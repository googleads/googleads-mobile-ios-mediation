#import "GADMAdapterMoPub.h"

#import "GADMAdapterMoPubSingleton.h"
#import "GADMoPubNetworkExtras.h"
#import "MPAdView.h"
#import "MPImageDownloadQueue.h"
#import "MPInterstitialAdController.h"
#import "MPLogging.h"
#import "MPNativeAd.h"
#import "MPNativeAdConstants.h"
#import "MPNativeAdDelegate.h"
#import "MPNativeAdRequest.h"
#import "MPNativeAdRequestTargeting.h"
#import "MPNativeAdUtils.h"
#import "MPNativeCache.h"
#import "MPStaticNativeAdRenderer.h"
#import "MPStaticNativeAdRendererSettings.h"
#import "MoPub.h"
#import "MoPubAdapterConstants.h"
#import "MoPubAdapterMediatedNativeAd.h"

@interface GADMAdapterMoPub () <MPNativeAdDelegate,
                                MPAdViewDelegate,
                                MPInterstitialAdControllerDelegate>

/// Connector from Google Mobile Ads SDK to receive ad configurations.
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@property(nonatomic, strong) MPAdView *bannerAd;
@property(nonatomic, strong) MPInterstitialAdController *interstitialAd;
@property(nonatomic, strong) MPNativeAd *nativeAd;
@property(nonatomic, strong) NSArray *nativeAdOptions;
@property(nonatomic, strong) MoPubAdapterMediatedNativeAd *mediatedAd;
@property(nonatomic, strong) MPImageDownloadQueue *imageDownloadQueue;
@property(nonatomic, strong) NSMutableDictionary *imagesDictionary;
@property(nonatomic, strong) GADNativeAdViewAdOptions *nativeAdViewAdOptions;
@property(nonatomic, assign) BOOL shouldDownloadImages;

@end

@implementation GADMAdapterMoPub

static NSMapTable *interstitialAdapterDelegates;

+ (void)load {
  interstitialAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                       valueOptions:NSPointerFunctionsWeakMemory];
}

+ (NSString *)adapterVersion {
  return kGADMAdapterMoPubVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMoPubNetworkExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
    _imageDownloadQueue = [[MPImageDownloadQueue alloc] init];
  }
  return self;
}

- (void)stopBeingDelegate {
  _bannerAd.delegate = nil;
  _interstitialAd.delegate = nil;
}
/*
 Keywords passed from AdMob are separated into 1) personally identifiable,
 and 2) non-personally identifiable categories before they are forwarded to MoPub due to GDPR.
 */
- (NSString *)getKeywords:(BOOL)intendedForPII {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSDate *birthday = [strongConnector userBirthday];
  NSString *ageString = @"";

  if (birthday) {
    NSInteger ageInteger = [self ageFromBirthday:birthday];
    ageString = [@"m_age:" stringByAppendingString:[@(ageInteger) stringValue]];
  }

  GADGender gender = [strongConnector userGender];
  NSString *genderString = @"";

  if (gender == kGADGenderMale) {
    genderString = @"m_gender:m";
  } else if (gender == kGADGenderFemale) {
    genderString = @"m_gender:f";
  }
  NSString *keywordsBuilder =
      [NSString stringWithFormat:@"%@,%@,%@", kGADMAdapterMoPubTpValue, ageString, genderString];

  if (intendedForPII) {
    if ([[MoPub sharedInstance] canCollectPersonalInfo]) {
      return [self keywordsContainUserData:strongConnector] ? keywordsBuilder : @"";
    } else {
      return @"";
    }
  } else {
    return [self keywordsContainUserData:strongConnector] ? @"" : keywordsBuilder;
  }
}

- (NSInteger)ageFromBirthday:(NSDate *)birthdate {
  NSDate *today = [NSDate date];
  NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear
                                                                    fromDate:birthdate
                                                                      toDate:today
                                                                     options:0];
  return ageComponents.year;
}

- (BOOL)keywordsContainUserData:(id<GADMAdNetworkConnector>)connector {
  return [connector userGender] || [connector userBirthday] || [connector userHasLocation];
}

#pragma mark - Interstitial Ads

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *publisherID = strongConnector.credentials[kGADMAdapterMoPubPubIdKey];

  @synchronized(interstitialAdapterDelegates) {
    if ([interstitialAdapterDelegates objectForKey:publisherID]) {
      NSError *adapterError = [NSError
          errorWithDomain:kGADMAdapterMoPubErrorDomain
                     code:kGADErrorInvalidRequest
                 userInfo:@{
                   NSLocalizedDescriptionKey : @"Unable to request a second ad using the sample "
                                               @"publisher ID while the first ad is still active."
                 }];
      [strongConnector adapter:self didFailAd:adapterError];
      return;
    } else {
      [interstitialAdapterDelegates setObject:self forKey:publisherID];
    }
  }

  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:strongConnector.userLatitude
                                                           longitude:strongConnector.userLongitude];

  _interstitialAd = [MPInterstitialAdController interstitialAdControllerForAdUnitId:publisherID];
  _interstitialAd.delegate = self;
  _interstitialAd.keywords = [self getKeywords:false];
  _interstitialAd.userDataKeywords = [self getKeywords:true];
  _interstitialAd.location = currentlocation;

  MPLogDebug(@"Requesting Interstitial Ad from MoPub Ad Network.");
  [[GADMAdapterMoPubSingleton sharedInstance] initializeMoPubSDKWithAdUnitID:publisherID
                                                           completionHandler:^{
                                                             [self.interstitialAd loadAd];
                                                           }];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  if (_interstitialAd.ready) {
    [_interstitialAd showFromViewController:rootViewController];
  }
}

#pragma mark MoPub Interstitial Ads delegate methods

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial {
  [_connector adapterDidReceiveInterstitial:self];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial {
  NSError *adapterError = [NSError errorWithDomain:kGADMAdapterMoPubErrorDomain
                                              code:kGADErrorMediationNoFill
                                          userInfo:nil];
  @synchronized(interstitialAdapterDelegates) {
    [interstitialAdapterDelegates removeObjectForKey:interstitial.adUnitId];
  }
  [_connector adapter:self didFailAd:adapterError];
}

- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial {
  [_connector adapterWillPresentInterstitial:self];
}

- (void)interstitialWillDisappear:(MPInterstitialAdController *)interstitial {
  [_connector adapterWillDismissInterstitial:self];
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial {
  @synchronized(interstitialAdapterDelegates) {
    [interstitialAdapterDelegates removeObjectForKey:interstitial.adUnitId];
  }
  [_connector adapterDidDismissInterstitial:self];
}

- (void)interstitialDidReceiveTapEvent:(MPInterstitialAdController *)interstitial {
  [_connector adapterDidGetAdClick:self];
}

#pragma mark - Banner Ads

/// Find closest supported ad size from a given ad size.
/// Returns nil if no supported size matches.
- (CGSize)GADSupportedAdSizeFromRequestedSize:(GADAdSize)gadAdSize {
  GADAdSize banner = GADAdSizeFromCGSize(CGSizeMake(320, 50));
  GADAdSize mRect = GADAdSizeFromCGSize(CGSizeMake(300, 250));
  GADAdSize leaderboard = GADAdSizeFromCGSize(CGSizeMake(728, 90));
  NSArray *potentials = @[
    NSValueFromGADAdSize(banner), NSValueFromGADAdSize(mRect), NSValueFromGADAdSize(leaderboard)
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  if (IsGADAdSizeValid(closestSize)) {
    return CGSizeFromGADAdSize(closestSize);
  }

  MPLogDebug(@"Unable to retrieve supported size from GADAdSize: %@",
             NSStringFromGADAdSize(gadAdSize));

  return CGSizeZero;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  CGSize supportedSize = [self GADSupportedAdSizeFromRequestedSize:adSize];
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *publisherID = strongConnector.credentials[kGADMAdapterMoPubPubIdKey];

  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:strongConnector.userLatitude
                                                           longitude:strongConnector.userLongitude];

  _bannerAd = [[MPAdView alloc] initWithAdUnitId:publisherID size:supportedSize];
  _bannerAd.delegate = self;
  _bannerAd.keywords = [self getKeywords:false];
  _bannerAd.userDataKeywords = [self getKeywords:true];
  _bannerAd.location = currentlocation;

  MPLogDebug(@"Requesting Banner Ad from MoPub Ad Network.");
  [[GADMAdapterMoPubSingleton sharedInstance] initializeMoPubSDKWithAdUnitID:publisherID
                                                           completionHandler:^{
                                                             [self.bannerAd loadAd];
                                                           }];
}

#pragma mark MoPub Ads View delegate methods

- (void)adViewDidLoadAd:(MPAdView *)view {
  [_connector adapter:self didReceiveAdView:view];
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view {
  NSString *errorDescription = [NSString stringWithFormat:@"Mopub failed to fill the ad."];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDescription, NSLocalizedDescriptionKey, nil];

  [_connector adapter:self
            didFailAd:[NSError errorWithDomain:kGADErrorDomain
                                          code:kGADErrorInvalidRequest
                                      userInfo:errorInfo]];
}

- (void)willLeaveApplicationFromAd:(MPAdView *)view {
  [_connector adapterWillLeaveApplication:self];
}

- (void)willPresentModalViewForAd:(MPAdView *)view {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillPresentFullScreenModal:self];
}

- (void)didDismissModalViewForAd:(MPAdView *)view {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterWillDismissFullScreenModal:self];
  [strongConnector adapterDidDismissFullScreenModal:self];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

#pragma mark - Native Ads

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MPStaticNativeAdRendererSettings *settings = [[MPStaticNativeAdRendererSettings alloc] init];
  MPNativeAdRendererConfiguration *config =
      [MPStaticNativeAdRenderer rendererConfigurationWithRendererSettings:settings];

  NSString *publisherID = strongConnector.credentials[kGADMAdapterMoPubPubIdKey];
  MPNativeAdRequest *adRequest = [MPNativeAdRequest requestWithAdUnitIdentifier:publisherID
                                                         rendererConfigurations:@[ config ]];

  MPNativeAdRequestTargeting *targeting = [MPNativeAdRequestTargeting targeting];
  targeting.keywords = [self getKeywords:false];
  targeting.userDataKeywords = [self getKeywords:true];
  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:strongConnector.userLatitude
                                                           longitude:strongConnector.userLongitude];
  targeting.location = currentlocation;
  NSSet *desiredAssets = [NSSet
      setWithObjects:kAdTitleKey, kAdTextKey, kAdIconImageKey, kAdMainImageKey, kAdCTATextKey, nil];
  targeting.desiredAssets = desiredAssets;

  adRequest.targeting = targeting;
  _nativeAdOptions = options;

  [[GADMAdapterMoPubSingleton sharedInstance] initializeMoPubSDKWithAdUnitID:publisherID
                                                           completionHandler:^{
                                                             [self requestNative:adRequest];
                                                           }];
}

- (void)requestNative:(MPNativeAdRequest *)adRequest {
  MPLogDebug(@"Requesting Native Ad from MoPub Ad Network.");
  [adRequest startWithCompletionHandler:^(MPNativeAdRequest *request, MPNativeAd *response,
                                          NSError *error) {
    [self handleNativeAdOptions:request
                   withResponse:response
                      withError:error
                    withOptions:self->_nativeAdOptions];
  }];
}

- (void)handleNativeAdOptions:(MPNativeAdRequest *)request
                 withResponse:(MPNativeAd *)response
                    withError:(NSError *)error
                  withOptions:(NSArray *)options {
  if (error) {
    [_connector adapter:self didFailAd:error];
  } else {
    _nativeAd = response;
    _nativeAd.delegate = self;
    _shouldDownloadImages = YES;

    if (options != nil) {
      for (GADAdLoaderOptions *loaderOptions in options) {
        if ([loaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
          GADNativeAdImageAdLoaderOptions *imageOptions =
              (GADNativeAdImageAdLoaderOptions *)loaderOptions;
          _shouldDownloadImages = !imageOptions.disableImageLoading;
        } else if ([loaderOptions isKindOfClass:[GADNativeAdViewAdOptions class]]) {
          _nativeAdViewAdOptions = (GADNativeAdViewAdOptions *)loaderOptions;
        }
      }
    }
    [self loadNativeAdImages];
  }
}

#pragma mark - Helper methods for downloading images

- (void)loadNativeAdImages {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSMutableArray *imageURLs = [NSMutableArray array];
  NSError *adapterError = [NSError errorWithDomain:kGADMAdapterMoPubErrorDomain
                                              code:kGADErrorReceivedInvalidResponse
                                          userInfo:nil];

  for (NSString *key in [_nativeAd.properties allKeys]) {
    if ([[key lowercaseString] hasSuffix:@"image"] &&
        [[_nativeAd.properties objectForKey:key] isKindOfClass:[NSString class]]) {
      if ([_nativeAd.properties objectForKey:key]) {
        NSURL *URL = [NSURL URLWithString:_nativeAd.properties[key]];
        if (URL != nil) {
          [imageURLs addObject:URL];
        } else {
          [strongConnector adapter:self didFailAd:adapterError];
          return;
        }
      } else {
        [strongConnector adapter:self didFailAd:adapterError];
        return;
      }
    }
  }
  [self precacheImagesWithURL:imageURLs];
}

- (NSString *)returnImageKey:(NSString *)imageURL {
  for (NSString *key in [_nativeAd.properties allKeys]) {
    if ([[key lowercaseString] hasSuffix:@"image"] &&
        [[_nativeAd.properties objectForKey:key] isKindOfClass:[NSString class]]) {
      if ([[_nativeAd.properties objectForKey:key] isEqualToString:imageURL]) {
        return key;
      }
    }
  }
  return nil;
}

- (void)precacheImagesWithURL:(NSArray *)imageURLs {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  _imagesDictionary = [[NSMutableDictionary alloc] init];

  for (NSURL *imageURL in imageURLs) {
    NSData *cachedImageData =
        [[MPNativeCache sharedCache] retrieveDataForKey:imageURL.absoluteString];

    UIImage *image = [UIImage imageWithData:cachedImageData];
    if (image) {
      // By default, the image data isn't decompressed until set on a UIImageView, on the main
      // thread. This can result in poor scrolling performance. To fix this, we force decompression
      // in the background before assignment to a UIImageView.
      UIGraphicsBeginImageContext(CGSizeMake(1, 1));
      [image drawAtPoint:CGPointZero];
      UIGraphicsEndImageContext();

      GADNativeAdImage *nativeAdImage = [[GADNativeAdImage alloc] initWithImage:image];
      [_imagesDictionary setObject:nativeAdImage
                            forKey:[self returnImageKey:imageURL.absoluteString]];
    }
  }

  if (_imagesDictionary.count < imageURLs.count) {
    MPLogDebug(@"Cache miss on %@. Re-downloading...", imageURLs);

    __weak typeof(self) weakSelf = self;
    [_imageDownloadQueue
        addDownloadImageURLs:imageURLs
             completionBlock:^(NSArray *errors) {
               __strong typeof(self) strongSelf = weakSelf;
               if (strongSelf) {
                 if (errors.count == 0) {
                   id<GADMAdNetworkConnector> strongConnector = strongSelf.connector;
                   for (NSURL *imageURL in imageURLs) {
                     UIImage *image =
                         [UIImage imageWithData:[[MPNativeCache sharedCache]
                                                    retrieveDataForKey:imageURL.absoluteString]];

                     GADNativeAdImage *nativeAdImage =
                         [[GADNativeAdImage alloc] initWithImage:image];
                     [strongSelf.imagesDictionary
                         setObject:nativeAdImage
                            forKey:[strongSelf returnImageKey:imageURL.absoluteString]];
                   }
                   if ([strongSelf.imagesDictionary objectForKey:kAdIconImageKey] &&
                       [strongSelf.imagesDictionary objectForKey:kAdMainImageKey]) {
                     strongSelf.mediatedAd = [[MoPubAdapterMediatedNativeAd alloc]
                         initWithMoPubNativeAd:strongSelf.nativeAd
                                  mappedImages:strongSelf.imagesDictionary
                           nativeAdViewOptions:strongSelf.nativeAdViewAdOptions
                                 networkExtras:[strongConnector networkExtras]];
                     [strongConnector adapter:strongSelf
                         didReceiveMediatedNativeAd:strongSelf.mediatedAd];
                   }
                 } else {
                   MPLogDebug(@"Failed to download images. Giving up for now.");
                   NSError *adapterError = [NSError errorWithDomain:kGADMAdapterMoPubErrorDomain
                                                               code:kGADErrorNetworkError
                                                           userInfo:nil];
                   [strongConnector adapter:strongSelf didFailAd:adapterError];
                   return;
                 }
               } else {
                 MPLogDebug(
                     @"MPNativeAd deallocated before loadImageForURL:intoImageView: download "
                     @"completion block was called");
                 NSError *adapterError = [NSError errorWithDomain:kGADMAdapterMoPubErrorDomain
                                                             code:kGADErrorInternalError
                                                         userInfo:nil];
                 [strongConnector adapter:strongSelf didFailAd:adapterError];
                 return;
               }
             }];
  } else {
    if (_shouldDownloadImages) {
      _mediatedAd = [[MoPubAdapterMediatedNativeAd alloc]
          initWithMoPubNativeAd:self.nativeAd
                   mappedImages:_imagesDictionary
            nativeAdViewOptions:_nativeAdViewAdOptions
                  networkExtras:[strongConnector networkExtras]];
      [strongConnector adapter:self didReceiveMediatedNativeAd:_mediatedAd];
    } else {
      NSMutableDictionary *_mainImageDictionary = [[NSMutableDictionary alloc] init];
      GADNativeAdImage *_tempMainImage = _imagesDictionary[kAdMainImageKey];
      _mainImageDictionary[kAdMainImageKey] = _tempMainImage;

      _mediatedAd = [[MoPubAdapterMediatedNativeAd alloc]
          initWithMoPubNativeAd:_nativeAd
                   mappedImages:_mainImageDictionary
            nativeAdViewOptions:_nativeAdViewAdOptions
                  networkExtras:[strongConnector networkExtras]];
      [strongConnector adapter:self didReceiveMediatedNativeAd:_mediatedAd];
    }
  }
}

#pragma mark MPNativeAdDelegate Methods

- (UIViewController *)viewControllerForPresentingModalView {
  return [_connector viewControllerForPresentingModalView];
}

- (void)willPresentModalForNativeAd:(MPNativeAd *)nativeAd {
  [GADMediatedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:_mediatedAd];
}

- (void)didDismissModalForNativeAd:(MPNativeAd *)nativeAd {
  [GADMediatedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:_mediatedAd];
  [GADMediatedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:_mediatedAd];
}

- (void)willLeaveApplicationFromNativeAd:(MPNativeAd *)nativeAd {
  [GADMediatedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:_mediatedAd];
}

@end

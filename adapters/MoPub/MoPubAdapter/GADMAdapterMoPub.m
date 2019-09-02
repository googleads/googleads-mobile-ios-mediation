#import "GADMAdapterMoPub.h"
#import "GADMAdapterMoPubSingleton.h"
#import "GADMAdapterMoPubUtils.h"
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

static NSMapTable<NSString *, GADMAdapterMoPub *> *GADMInterstitialAdapterDelegates;

@interface GADMAdapterMoPub () <MPNativeAdDelegate,
                                MPAdViewDelegate,
                                MPInterstitialAdControllerDelegate>
@end

@implementation GADMAdapterMoPub {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  NSArray<GADAdLoaderOptions *> *_nativeAdOptions;

  MPAdView *_bannerAd;

  MPInterstitialAdController *_interstitialAd;

  MPNativeAd *_nativeAd;

  MoPubAdapterMediatedNativeAd *_mediatedAd;

  MPImageDownloadQueue *_imageDownloadQueue;

  NSMutableDictionary<NSString *, GADNativeAdImage *> *_imagesDictionary;

  GADNativeAdViewAdOptions *_nativeAdViewAdOptions;

  BOOL _shouldDownloadImages;
}

+ (void)load {
  GADMInterstitialAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
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

/// Keywords passed from AdMob are separated into 1) personally identifiable,
/// and 2) non-personally identifiable categories before they are forwarded to MoPub due to GDPR.

- (nonnull NSString *)getKeywords:(BOOL)intendedForPII {
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

- (NSInteger)ageFromBirthday:(nonnull NSDate *)birthdate {
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

  @synchronized(GADMInterstitialAdapterDelegates) {
    if ([GADMInterstitialAdapterDelegates objectForKey:publisherID]) {
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
      GADMAdapterMoPubMapTableSetObjectForKey(GADMInterstitialAdapterDelegates, publisherID, self);
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
                                                             [self->_interstitialAd loadAd];
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
  @synchronized(GADMInterstitialAdapterDelegates) {
    GADMAdapterMoPubMapTableRemoveObjectForKey(GADMInterstitialAdapterDelegates, interstitial.adUnitId);
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
  @synchronized(GADMInterstitialAdapterDelegates) {
    GADMAdapterMoPubMapTableRemoveObjectForKey(GADMInterstitialAdapterDelegates, interstitial.adUnitId);
  }
  [_connector adapterDidDismissInterstitial:self];
}

- (void)interstitialDidReceiveTapEvent:(MPInterstitialAdController *)interstitial {
  [_connector adapterDidGetAdClick:self];
}

#pragma mark - Banner Ads

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *publisherID = strongConnector.credentials[kGADMAdapterMoPubPubIdKey];

  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:strongConnector.userLatitude
                                                           longitude:strongConnector.userLongitude];

  _bannerAd = [[MPAdView alloc] initWithAdUnitId:publisherID];
  _bannerAd.delegate = self;
  _bannerAd.keywords = [self getKeywords:false];
  _bannerAd.userDataKeywords = [self getKeywords:true];
  _bannerAd.location = currentlocation;

  MPLogDebug(@"Requesting Banner Ad from MoPub Ad Network.");
  [[GADMAdapterMoPubSingleton sharedInstance]
      initializeMoPubSDKWithAdUnitID:publisherID
                   completionHandler:^{
                     [self->_bannerAd loadAdWithMaxAdSize:adSize.size];
                   }];
}

#pragma mark MoPub Ads View delegate methods

- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize {
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

- (void)getNativeAdWithAdTypes:(NSArray<GADAdLoaderAdType> *)adTypes
                       options:(NSArray<GADAdLoaderOptions *> *)options {
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

- (void)requestNative:(nonnull MPNativeAdRequest *)adRequest {
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
                  withOptions:(NSArray<GADAdLoaderOptions *> *)options {
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
  NSMutableArray<NSURL *> *imageURLs = [NSMutableArray array];
  NSError *adapterError = [NSError errorWithDomain:kGADMAdapterMoPubErrorDomain
                                              code:kGADErrorReceivedInvalidResponse
                                          userInfo:nil];

  for (NSString *key in [_nativeAd.properties allKeys]) {
    if ([[key lowercaseString] hasSuffix:@"image"] &&
        [[_nativeAd.properties objectForKey:key] isKindOfClass:[NSString class]]) {
      if ([_nativeAd.properties objectForKey:key]) {
        NSURL *URL = [NSURL URLWithString:_nativeAd.properties[key]];
        if (URL != nil) {
          GADMAdapterMoPubMutableArrayAddObject(imageURLs, URL);
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

- (void)precacheImagesWithURL:(NSArray<NSURL *> *)imageURLs {
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
      NSString *imagekey = [self returnImageKey:imageURL.absoluteString];
      GADMAdapterMoPubMutableDictionarySetObjectForKey(_imagesDictionary, imagekey, nativeAdImage);
    }
  }

  if (_imagesDictionary.count < imageURLs.count) {
    MPLogDebug(@"Cache miss on %@. Re-downloading...", imageURLs);

    GADMAdapterMoPub __weak* weakSelf = self;
    [_imageDownloadQueue
        addDownloadImageURLs:imageURLs
             completionBlock:^(NSArray *errors) {
               GADMAdapterMoPub *strongSelf = weakSelf;
               if (strongSelf) {
                 if (errors.count == 0) {
                   id<GADMAdNetworkConnector> strongConnector = strongSelf->_connector;
                   for (NSURL *imageURL in imageURLs) {
                     UIImage *image =
                         [UIImage imageWithData:[[MPNativeCache sharedCache]
                                                    retrieveDataForKey:imageURL.absoluteString]];

                     GADNativeAdImage *nativeAdImage =
                         [[GADNativeAdImage alloc] initWithImage:image];
                     NSString *imagekey = [strongSelf returnImageKey:imageURL.absoluteString];
                     GADMAdapterMoPubMutableDictionarySetObjectForKey(strongSelf->_imagesDictionary,
                                                                      imagekey, nativeAdImage);
                   }
                   if ([strongSelf->_imagesDictionary objectForKey:kAdIconImageKey] &&
                       [strongSelf->_imagesDictionary objectForKey:kAdMainImageKey]) {
                     strongSelf->_mediatedAd = [[MoPubAdapterMediatedNativeAd alloc]
                                              initWithMoPubNativeAd:strongSelf->_nativeAd
                                  mappedImages:strongSelf->_imagesDictionary
                           nativeAdViewOptions:strongSelf->_nativeAdViewAdOptions
                                 networkExtras:[strongConnector networkExtras]];
                     [strongConnector adapter:strongSelf
                         didReceiveMediatedUnifiedNativeAd:strongSelf->_mediatedAd];
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
          initWithMoPubNativeAd:_nativeAd
                   mappedImages:_imagesDictionary
            nativeAdViewOptions:_nativeAdViewAdOptions
                  networkExtras:[strongConnector networkExtras]];
      [strongConnector adapter:self didReceiveMediatedUnifiedNativeAd:_mediatedAd];
    } else {
      NSMutableDictionary *_mainImageDictionary = [[NSMutableDictionary alloc] init];
      GADNativeAdImage *_tempMainImage = _imagesDictionary[kAdMainImageKey];
      _mainImageDictionary[kAdMainImageKey] = _tempMainImage;

      _mediatedAd = [[MoPubAdapterMediatedNativeAd alloc]
          initWithMoPubNativeAd:_nativeAd
                   mappedImages:_mainImageDictionary
            nativeAdViewOptions:_nativeAdViewAdOptions
                  networkExtras:[strongConnector networkExtras]];
      [strongConnector adapter:self didReceiveMediatedUnifiedNativeAd:_mediatedAd];
    }
  }
}

#pragma mark MPNativeAdDelegate Methods

- (UIViewController *)viewControllerForPresentingModalView {
  return [_connector viewControllerForPresentingModalView];
}

- (void)willPresentModalForNativeAd:(MPNativeAd *)nativeAd {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:_mediatedAd];
}

- (void)didDismissModalForNativeAd:(MPNativeAd *)nativeAd {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:_mediatedAd];
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:_mediatedAd];
}

- (void)willLeaveApplicationFromNativeAd:(MPNativeAd *)nativeAd {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:_mediatedAd];
}

@end

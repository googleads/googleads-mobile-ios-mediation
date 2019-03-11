#import "GADMAdapterMoPub.h"

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

+ (NSString *)adapterVersion {
  return GADMAdapterMoPubVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMoPubNetworkExtras class];
}

- (void)initializeMoPub:(NSString *)adUnitId
           withBannerAd:(MPAdView *)bannerAd
     withInterstitialAd:(MPInterstitialAdController *)interstitialAd
           withNativeAd:(MPNativeAdRequest *)nativeAd {
  MPMoPubConfiguration *sdkConfig =
      [[MPMoPubConfiguration alloc] initWithAdUnitIdForAppInitialization:adUnitId];

  if (!MoPub.sharedInstance.isSdkInitialized) {
    [[MoPub sharedInstance]
        initializeSdkWithConfiguration:sdkConfig
                            completion:^{
                              NSLog(@"MoPub SDK initialized.");

                              dispatch_async(dispatch_get_main_queue(), ^{
                                // Start loading ads now that the MoPub SDK has initialized
                                if (bannerAd != nil) {
                                  [bannerAd loadAd];
                                } else if (interstitialAd != nil) {
                                  [interstitialAd loadAd];
                                } else if (nativeAd != nil) {
                                  [nativeAd startWithCompletionHandler:^(MPNativeAdRequest *request,
                                                                         MPNativeAd *response,
                                                                         NSError *error) {
                                    [self handleNativeAdOptions:request
                                                   withResponse:response
                                                      withError:error
                                                    withOptions:self->_nativeAdOptions];
                                  }];
                                }
                              });
                            }];
  }
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
      [NSString stringWithFormat:@"%@,%@,%@", kAdapterTpValue, ageString, genderString];

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
  NSString *publisherID = [strongConnector credentials][@"pubid"];

  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:strongConnector.userLatitude
                                                           longitude:strongConnector.userLongitude];

  _interstitialAd = [MPInterstitialAdController interstitialAdControllerForAdUnitId:publisherID];
  _interstitialAd.delegate = self;
  _interstitialAd.keywords = [self getKeywords:false];
  _interstitialAd.userDataKeywords = [self getKeywords:true];
  _interstitialAd.location = currentlocation;

  if ([[MoPub sharedInstance] isSdkInitialized]) {
    [_interstitialAd loadAd];
  } else {
    [self initializeMoPub:publisherID
              withBannerAd:nil
        withInterstitialAd:_interstitialAd
              withNativeAd:nil];
  }

  MPLogDebug(@"Requesting Interstitial Ad from MoPub Ad Network.");
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
  NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain
                                              code:kGADErrorMediationNoFill
                                          userInfo:nil];
  [_connector adapter:self didFailAd:adapterError];
}

- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial {
  [_connector adapterWillPresentInterstitial:self];
}

- (void)interstitialWillDisappear:(MPInterstitialAdController *)interstitial {
  [_connector adapterWillDismissInterstitial:self];
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial {
  [_connector adapterDidDismissInterstitial:self];
}

- (void)interstitialDidReceiveTapEvent:(MPInterstitialAdController *)interstitial {
  [_connector adapterDidGetAdClick:self];
}

#pragma mark - Banner Ads

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *publisherID = [strongConnector credentials][@"pubid"];

  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:strongConnector.userLatitude
                                                           longitude:strongConnector.userLongitude];

  _bannerAd = [[MPAdView alloc] initWithAdUnitId:publisherID size:CGSizeFromGADAdSize(adSize)];
  _bannerAd.delegate = self;
  _bannerAd.keywords = [self getKeywords:false];
  _bannerAd.userDataKeywords = [self getKeywords:true];
  _bannerAd.location = currentlocation;

  if ([[MoPub sharedInstance] isSdkInitialized]) {
    [_bannerAd loadAd];
  } else {
    [self initializeMoPub:publisherID
              withBannerAd:_bannerAd
        withInterstitialAd:nil
              withNativeAd:nil];
  }

  MPLogDebug(@"Requesting Banner Ad from MoPub Ad Network.");
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

  NSString *publisherID = [strongConnector credentials][@"pubid"];
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

  if ([[MoPub sharedInstance] isSdkInitialized]) {
    [adRequest startWithCompletionHandler:^(MPNativeAdRequest *request, MPNativeAd *response,
                                            NSError *error) {
      [self handleNativeAdOptions:request
                     withResponse:response
                        withError:error
                      withOptions:self->_nativeAdOptions];
    }];
  } else {
    [self initializeMoPub:publisherID
              withBannerAd:nil
        withInterstitialAd:nil
              withNativeAd:adRequest];
  }
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
    MPLogDebug(@"Requesting Native Ad from MoPub Ad Network.");
  }
}

#pragma mark - Helper methods for downloading images

- (void)loadNativeAdImages {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSMutableArray *imageURLs = [NSMutableArray array];
  NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain
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
                   NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain
                                                               code:kGADErrorNetworkError
                                                           userInfo:nil];
                   [strongConnector adapter:strongSelf didFailAd:adapterError];
                   return;
                 }
               } else {
                 MPLogDebug(
                     @"MPNativeAd deallocated before loadImageForURL:intoImageView: download "
                     @"completion block was called");
                 NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain
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

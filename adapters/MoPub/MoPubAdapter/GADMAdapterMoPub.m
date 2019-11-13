#import "GADMAdapterMoPub.h"

#import "GADMAdapterMoPubConstants.h"
#import "GADMAdapterMoPubSingleton.h"
#import "GADMAdapterMoPubUtils.h"
#import "GADMAdapterMopubUnifiedNativeAd.h"
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

static NSMapTable<NSString *, GADMAdapterMoPub *> *GADMAdapterMoPubInterstitialDelegates;

@interface GADMAdapterMoPub () <MPNativeAdDelegate,
                                MPAdViewDelegate,
                                MPInterstitialAdControllerDelegate>
@end

@implementation GADMAdapterMoPub {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Array of ad loader options.
  NSArray<GADAdLoaderOptions *> *_nativeAdOptions;

  /// MoPub banner ad.
  MPAdView *_bannerAd;

  /// MoPub interstitial ad.
  MPInterstitialAdController *_interstitialAd;

  /// MoPub native ad.
  MPNativeAd *_nativeAd;

  /// MoPub native ad wrapper.
  GADMAdapterMopubUnifiedNativeAd *_mediatedAd;

  /// MoPub's image download queue.
  MPImageDownloadQueue *_imageDownloadQueue;

  /// Ad loader options for configuring the view of native ads.
  GADNativeAdViewAdOptions *_nativeAdViewAdOptions;

  /// Serializes GADMAdapterMoPubInterstitialDelegates usage.
  dispatch_queue_t _lockQueue;
}

+ (void)load {
  GADMAdapterMoPubInterstitialDelegates =
      [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
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
    _lockQueue = dispatch_queue_create("mopub-interstitialAdapterDelegates", DISPATCH_QUEUE_SERIAL);
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

  dispatch_async(_lockQueue, ^{
    if ([GADMAdapterMoPubInterstitialDelegates objectForKey:publisherID]) {
      NSError *adapterError = GADMAdapterMoPubErrorWithCodeAndDescription(
          kGADErrorInvalidRequest, @"Unable to request a second ad using the same publisher ID "
                                   @"while the first ad is still active.");
      [strongConnector adapter:self didFailAd:adapterError];
      return;
    } else {
      GADMAdapterMoPubMapTableSetObjectForKey(GADMAdapterMoPubInterstitialDelegates, publisherID,
                                              self);
    }
  });

  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:strongConnector.userLatitude
                                                           longitude:strongConnector.userLongitude];

  _interstitialAd = [MPInterstitialAdController interstitialAdControllerForAdUnitId:publisherID];
  _interstitialAd.delegate = self;
  _interstitialAd.keywords = [self getKeywords:NO];
  _interstitialAd.userDataKeywords = [self getKeywords:YES];
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
  NSError *adapterError =
      GADMAdapterMoPubErrorWithCodeAndDescription(kGADErrorNoFill, @"Mopub failed to fill the ad.");
  dispatch_async(_lockQueue, ^{
    GADMAdapterMoPubMapTableRemoveObjectForKey(GADMAdapterMoPubInterstitialDelegates,
                                               interstitial.adUnitId);
  });
  [_connector adapter:self didFailAd:adapterError];
}

- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial {
  [_connector adapterWillPresentInterstitial:self];
}

- (void)interstitialWillDisappear:(MPInterstitialAdController *)interstitial {
  [_connector adapterWillDismissInterstitial:self];
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial {
  dispatch_async(_lockQueue, ^{
    GADMAdapterMoPubMapTableRemoveObjectForKey(GADMAdapterMoPubInterstitialDelegates,
                                               interstitial.adUnitId);
  });
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
  _bannerAd.keywords = [self getKeywords:NO];
  _bannerAd.userDataKeywords = [self getKeywords:YES];
  _bannerAd.location = currentlocation;
  // MoPub banner frame must be set. For reference:
  // https://developers.mopub.com/publishers/ios/banner/#loading-banner-ads-in-your-app
  _bannerAd.frame = CGRectMake(0, 0, adSize.size.width, adSize.size.height);

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

- (void)adView:(MPAdView *)view didFailToLoadAdWithError:(NSError *)error {
  [_connector adapter:self didFailAd:error];
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
  _nativeAdOptions = options;

  MPStaticNativeAdRendererSettings *settings = [[MPStaticNativeAdRendererSettings alloc] init];
  MPNativeAdRendererConfiguration *config =
      [MPStaticNativeAdRenderer rendererConfigurationWithRendererSettings:settings];

  NSString *publisherID = strongConnector.credentials[kGADMAdapterMoPubPubIdKey];
  MPNativeAdRequest *adRequest = [MPNativeAdRequest requestWithAdUnitIdentifier:publisherID
                                                         rendererConfigurations:@[ config ]];

  MPNativeAdRequestTargeting *targeting = [MPNativeAdRequestTargeting targeting];
  targeting.keywords = [self getKeywords:NO];
  targeting.userDataKeywords = [self getKeywords:YES];
  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:strongConnector.userLatitude
                                                           longitude:strongConnector.userLongitude];
  targeting.location = currentlocation;
  NSSet<NSString *> *desiredAssets = [NSSet
      setWithObjects:kAdTitleKey, kAdTextKey, kAdIconImageKey, kAdMainImageKey, kAdCTATextKey, nil];
  targeting.desiredAssets = desiredAssets;
  adRequest.targeting = targeting;

  [[GADMAdapterMoPubSingleton sharedInstance] initializeMoPubSDKWithAdUnitID:publisherID
                                                           completionHandler:^{
                                                             [self requestNative:adRequest];
                                                           }];
}

- (void)requestNative:(nonnull MPNativeAdRequest *)adRequest {
  MPLogDebug(@"Requesting Native Ad from MoPub Ad Network.");
  [adRequest startWithCompletionHandler:^(MPNativeAdRequest *request, MPNativeAd *response,
                                          NSError *error) {
    [self handleNativeAdWithResponse:response withError:error];
  }];
}

- (void)handleNativeAdWithResponse:(MPNativeAd *)response withError:(NSError *)error {
  if (error) {
    [_connector adapter:self didFailAd:error];
    return;
  }

  _nativeAd = response;
  _nativeAd.delegate = self;
  GADMAdapterMoPub *__weak weakSelf = self;
  [self preCacheNativeImagesWithCompletionHandler:^(
            NSDictionary<NSString *, GADNativeAdImage *> *_Nullable imagesDictionary) {
    GADMAdapterMoPub *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    id<GADMAdNetworkConnector> strongConnector = strongSelf->_connector;
    if (!imagesDictionary[kAdIconImageKey] || !imagesDictionary[kAdMainImageKey]) {
      NSError *adapterError = GADMAdapterMoPubErrorWithCodeAndDescription(
          kGADErrorNetworkError, @"Failed to download images.");
      [strongConnector adapter:strongSelf didFailAd:adapterError];
      return;
    }
    strongSelf->_mediatedAd = [[GADMAdapterMopubUnifiedNativeAd alloc]
        initWithMoPubNativeAd:strongSelf->_nativeAd
                    mainImage:imagesDictionary[kAdMainImageKey]
                    iconImage:imagesDictionary[kAdIconImageKey]
          nativeAdViewOptions:strongSelf->_nativeAdViewAdOptions
                networkExtras:strongConnector.networkExtras];
    [strongConnector adapter:strongSelf didReceiveMediatedUnifiedNativeAd:strongSelf->_mediatedAd];
  }];
}

#pragma mark - Helper methods for downloading images

- (nullable NSDictionary<NSString *, NSURL *> *)imageURLsForKeys:(NSArray<NSString *> *)keys {
  NSMutableDictionary<NSString *, NSURL *> *imageURLDictionary = [[NSMutableDictionary alloc] init];

  for (NSString *imageKey in keys) {
    if ([_nativeAd.properties[imageKey] isKindOfClass:[NSString class]]) {
      NSString *nativeAdImageURLString = _nativeAd.properties[imageKey];
      NSURL *imageURL = [NSURL URLWithString:nativeAdImageURLString];
      GADMAdapterMoPubMutableDictionarySetObjectForKey(imageURLDictionary, imageKey, imageURL);
    }
  }

  return imageURLDictionary;
}

- (void)preCacheNativeImagesWithCompletionHandler:
    (void (^)(NSDictionary<NSString *, GADNativeAdImage *> *_Nullable imagesDictionary))
        completionHandler {
  NSArray<NSString *> *keyArray = @[kAdIconImageKey, kAdMainImageKey];
  NSDictionary<NSString *, NSURL *> *imageURLDictionary = [self imageURLsForKeys:keyArray];
  if (!imageURLDictionary[kAdMainImageKey] || !imageURLDictionary[kAdIconImageKey]) {
    NSError *adapterError = GADMAdapterMoPubErrorWithCodeAndDescription(
        kGADErrorReceivedInvalidResponse, @"Can't find the required MoPub native ad image assets.");
    [_connector adapter:self didFailAd:adapterError];
    return;
  }

  // Indicates whether the image assets should be downloaded or not.
  BOOL shouldDownloadImages = YES;
  if (_nativeAdOptions) {
    for (GADAdLoaderOptions *loaderOptions in _nativeAdOptions) {
      if ([loaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
        GADNativeAdImageAdLoaderOptions *imageOptions =
            (GADNativeAdImageAdLoaderOptions *)loaderOptions;
        shouldDownloadImages = !imageOptions.disableImageLoading;
      } else if ([loaderOptions isKindOfClass:[GADNativeAdViewAdOptions class]]) {
        _nativeAdViewAdOptions = (GADNativeAdViewAdOptions *)loaderOptions;
      }
    }
  }
  /// A dictionary that contains the icon and image assets for the native ad.
  NSMutableDictionary<NSString *, GADNativeAdImage *> *imagesDictionary =
      [[NSMutableDictionary alloc] init];
  if (shouldDownloadImages) {
    for (NSString *imageKey in imageURLDictionary.allKeys) {
      NSData *imageData = [[MPNativeCache sharedCache]
          retrieveDataForKey:imageURLDictionary[imageKey].absoluteString];
      if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        GADNativeAdImage *nativeAdImage = [[GADNativeAdImage alloc] initWithImage:image];
        GADMAdapterMoPubMutableDictionarySetObjectForKey(imagesDictionary, imageKey, nativeAdImage);
      }
    }

    // Check if MoPub image assets are cached.
    if (!imagesDictionary[kAdIconImageKey] || !imagesDictionary[kAdMainImageKey]) {
      GADMAdapterMoPub __weak *weakSelf = self;
      [_imageDownloadQueue
          addDownloadImageURLs:imageURLDictionary.allValues
               completionBlock:^(NSDictionary<NSURL *, UIImage *> *result, NSArray *errors) {
                 GADMAdapterMoPub *strongSelf = weakSelf;
                 if (!strongSelf) {
                   NSLog(@"MPNativeAd deallocated before MoPub native ad images were downloaded.");
                   return;
                 }
                 for (NSString *imageKey in imageURLDictionary.allKeys) {
                   NSURL *imageURL = imageURLDictionary[imageKey];
                   UIImage *image = result[imageURL];
                   if (image) {
                     GADNativeAdImage *nativeAdImage =
                         [[GADNativeAdImage alloc] initWithImage:image];
                     GADMAdapterMoPubMutableDictionarySetObjectForKey(imagesDictionary, imageKey,
                                                                      nativeAdImage);
                   }
                 }
                 completionHandler(imagesDictionary);
               }];
      return;
    }
  } else {
    for (NSString *imageKey in imageURLDictionary.allKeys) {
      GADNativeAdImage *nativeAdImage =
          [[GADNativeAdImage alloc] initWithURL:imageURLDictionary[imageKey] scale:1.0];
      GADMAdapterMoPubMutableDictionarySetObjectForKey(imagesDictionary, imageKey, nativeAdImage);
    }
  }
  completionHandler(imagesDictionary);
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

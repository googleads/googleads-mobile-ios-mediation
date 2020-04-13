//
//  GADMAdapterInMobi.m
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import "GADMAdapterInMobi.h"
#import <InMobiSDK/IMSdk.h>
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"
#import "InMobiMediatedUnifiedNativeAd.h"
#import "NativeAdKeys.h"

@interface GADMAdapterInMobi ()
@property(nonatomic, assign) CGFloat width, height;
@property(nonatomic, strong) InMobiMediatedUnifiedNativeAd *nativeAd;
@property(nonatomic, strong) GADInMobiExtras *extraInfo;
@property(nonatomic, assign) BOOL shouldDownloadImages;
@property(nonatomic, assign) BOOL serveAnyAd;
@end

/// Find closest supported ad size from a given ad size.
static CGSize GADMAdapterInMobiSupportedAdSizeFromGADAdSize(GADAdSize gadAdSize) {
  // Supported sizes
  // 320 x 50
  // 300 x 250
  // 728 x 90

  NSArray<NSValue *> *potentialSizeValues =
      @[ @(kGADAdSizeBanner), @(kGADAdSizeMediumRectangle), @(kGADAdSizeLeaderboard) ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentialSizeValues);
  return CGSizeFromGADAdSize(closestSize);
}

@implementation GADMAdapterInMobi
@synthesize adView = adView_;
@synthesize interstitial = interstitial_;
@synthesize native = native_;

static NSCache *imageCache;

__attribute__((constructor)) static void initialize_imageCache() {
  imageCache = [[NSCache alloc] init];
}

@synthesize connector = connector_;

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterInMobi class];
}

+ (nonnull NSString *)adapterVersion {
  return kGADMAdapterInMobiVersion;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADInMobiExtras class];
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id)connector {
  self.connector = connector;
  self.shouldDownloadImages = YES;
  self.serveAnyAd = NO;
  if (self = [super init]) {
    self.connector = connector;
  }
  return self;
}

- (void)prepareRequestParameters {
  if ([self.connector userGender] == kGADGenderMale) {
    [IMSdk setGender:kIMSDKGenderMale];
  } else if ([self.connector userGender] == kGADGenderFemale) {
    [IMSdk setGender:kIMSDKGenderFemale];
  }

  if ([self.connector userBirthday] != nil) {
    NSDateComponents *components = [[NSCalendar currentCalendar]
        components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
          fromDate:[self.connector userBirthday]];
    [IMSdk setYearOfBirth:[components year]];
  }

  if (self.connector) {
    self.extraInfo = [self.connector networkExtras];
  }

  if (self.extraInfo != nil) {
    if (self.extraInfo.postalCode != nil) {
      [IMSdk setPostalCode:self.extraInfo.postalCode];
    }
    if (self.extraInfo.areaCode != nil) {
      [IMSdk setAreaCode:self.extraInfo.areaCode];
    }
    if (self.extraInfo.interests != nil) {
      [IMSdk setInterests:self.extraInfo.interests];
    }
    if (self.extraInfo.age) {
      [IMSdk setAge:self.extraInfo.age];
    }
    if (self.extraInfo.yearOfBirth) {
      [IMSdk setYearOfBirth:self.extraInfo.yearOfBirth];
    }
    if (self.extraInfo.city && self.extraInfo.state && self.extraInfo.country) {
      [IMSdk setLocationWithCity:self.extraInfo.city
                           state:self.extraInfo.state
                         country:self.extraInfo.country];
    }
    if (self.extraInfo.language != nil) {
      [IMSdk setLanguage:self.extraInfo.language];
    }
  }

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  if (self.extraInfo && self.extraInfo.additionalParameters) {
    dict = [NSMutableDictionary dictionaryWithDictionary:self.extraInfo.additionalParameters];
  }

  GADMAdapterInMobiMutableDictionarySetObjectForKey(dict, @"tp", @"c_admob");
  GADMAdapterInMobiMutableDictionarySetObjectForKey(dict, @"tp-ver", [GADRequest sdkVersion]);

  if ([[self.connector childDirectedTreatment] integerValue] == 1) {
    GADMAdapterInMobiMutableDictionarySetObjectForKey(dict, @"coppa", @"1");
  } else {
    GADMAdapterInMobiMutableDictionarySetObjectForKey(dict, @"coppa", @"0");
  }

  if (self.adView) {
    // Let Mediation do the refresh animation.
    self.adView.transitionAnimation = UIViewAnimationTransitionNone;
    if (self.extraInfo.keywords != nil) {
      [self.adView setKeywords:self.extraInfo.keywords];
    }
    [self.adView setExtras:[NSDictionary dictionaryWithDictionary:dict]];
  } else if (self.interstitial) {
    if (self.extraInfo.keywords != nil) {
      [self.interstitial setKeywords:self.extraInfo.keywords];
    }
    [self.interstitial setExtras:[NSDictionary dictionaryWithDictionary:dict]];
  } else if (self.native) {
    if (self.extraInfo.keywords != nil) {
      [self.native setKeywords:self.extraInfo.keywords];
    }
    [self.native setExtras:[NSDictionary dictionaryWithDictionary:dict]];
  }
}

- (Boolean)isPerformanceAd:(nonnull IMNative *)imNative {
  NSData *data = [imNative.customAdContent dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error = nil;
  NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:&error];
  if ([[jsonDictionary objectForKey:PACKAGE_NAME] length]) {
    return YES;
  }
  return NO;
}

- (void)getNativeAdWithAdTypes:(nonnull NSArray *)adTypes options:(nullable NSArray *)options {
  NSString *accountID = self.connector.credentials[kGADMAdapterInMobiAccountID];
  NSError *error = [GADMediationAdapterInMobi initializeWithAccountID:accountID];
  if (error) {
    NSLog(@"[InMobi] Initialization failed: %@", error.localizedDescription);
    [self.connector adapter:self didFailAd:error];
    return;
  }

  long long placementId = self.placementId;
  if (placementId == -1) {
    NSString *errorDesc =
        [NSString stringWithFormat:@"[InMobi] Error - Placement ID not specified."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                         code:kGADErrorInvalidRequest
                                                     userInfo:errorInfo];
    [self.connector adapter:self didFailAd:error];
    return;
  }

  if ([self.connector testMode]) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to recieve test ads from "
          @"Inmobi");
  }

  for (GADNativeAdImageAdLoaderOptions *imageOptions in options) {
    if (![imageOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      continue;
    }
    self.shouldDownloadImages = !imageOptions.disableImageLoading;
  }

  NSLog(@"Requesting native ad from InMobi");
  self.native = [[IMNative alloc] initWithPlacementId:placementId delegate:self];
  [self prepareRequestParameters];
  [self.native load];
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (BOOL)handlesUserClicks {
  return NO;
}

- (void)getInterstitial {
  NSString *accountID = self.connector.credentials[kGADMAdapterInMobiAccountID];
  NSError *error = [GADMediationAdapterInMobi initializeWithAccountID:accountID];
  if (error) {
    NSLog(@"[InMobi] Initialization failed: %@", error.localizedDescription);
    [self.connector adapter:self didFailAd:error];
    return;
  }

  long long placementId = self.placementId;
  if (placementId == -1) {
    NSString *errorDesc =
        [NSString stringWithFormat:@"[InMobi] Error - Placement ID not specified."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                         code:kGADErrorInvalidRequest
                                                     userInfo:errorInfo];
    [self.connector adapter:self didFailAd:error];
    return;
  }

  if ([self.connector testMode]) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to recieve test ads from "
          @"Inmobi");
  }

  self.interstitial = [[IMInterstitial alloc] initWithPlacementId:placementId];
  [self prepareRequestParameters];
  self.interstitial.delegate = self;
  [self.interstitial load];
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSString *accountID = self.connector.credentials[kGADMAdapterInMobiAccountID];
  NSError *error = [GADMediationAdapterInMobi initializeWithAccountID:accountID];
  if (error) {
    NSLog(@"[InMobi] Initialization failed: %@", error.localizedDescription);
    [self.connector adapter:self didFailAd:error];
    return;
  }

  long long placementId = self.placementId;
  if (placementId == -1) {
    NSString *errorDesc =
        [NSString stringWithFormat:@"[InMobi] Error - Placement ID not specified."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                         code:kGADErrorInvalidRequest
                                                     userInfo:errorInfo];
    [self.connector adapter:self didFailAd:error];
    return;
  }

  if ([self.connector testMode]) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to recieve test ads from "
          @"Inmobi");
  }

  CGSize size = GADMAdapterInMobiSupportedAdSizeFromGADAdSize(adSize);

  if (CGSizeEqualToSize(size, CGSizeZero)) {
    NSString *errorDescription =
        [NSString stringWithFormat:@"Invalid size for InMobi mediation adapter. Size: %@",
                                   NSStringFromGADAdSize(adSize)];
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : errorDescription};
    GADRequestError *error = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                         code:kGADErrorMediationInvalidAdSize
                                                     userInfo:errorInfo];
    [self.connector adapter:self didFailAd:error];
    return;
  }
  self.adView = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                    placementId:placementId];
  self.adView.delegate = self;
  // Let Mediation do the refresh.
  [self.adView shouldAutoRefresh:NO];
  [self prepareRequestParameters];
  [self.adView load];
}

- (void)stopBeingDelegate {
  self.adView.delegate = nil;
  self.interstitial.delegate = nil;
}

- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController {
  if ([self.interstitial isReady]) {
    [self.interstitial showFromViewController:rootViewController
                                withAnimation:kIMInterstitialAnimationTypeCoverVertical];
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return [self.interstitial isReady];
}

#pragma mark -
#pragma mark Properties

- (long long)placementId {
  if (self.connector != nil && self.connector.credentials[kGADMAdapterInMobiPlacementID]) {
    return [self.connector.credentials[kGADMAdapterInMobiPlacementID] longLongValue];
  }
  return -1;
}

#pragma mark IMBannerDelegate methods

- (void)bannerDidFinishLoading:(nonnull IMBanner *)banner {
  NSLog(@"<<<<<ad request completed>>>>>");
  [self.connector adapter:self didReceiveAdView:banner];
}

- (void)banner:(nonnull IMBanner *)banner didFailToLoadWithError:(nonnull IMRequestStatus *)error {
  NSInteger errorCode = GADMAdapterInMobiAdMobErrorCodeForInMobiCode([error code]);
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                          code:errorCode
                                                      userInfo:errorInfo];
  [self.connector adapter:self didFailAd:reqError];
  NSLog(@"<<<< ad request failed.>>>, error=%@", error);
  NSLog(@"error code=%ld", (long)[error code]);
}

- (void)banner:(nonnull IMBanner *)banner didInteractWithParams:(nonnull NSDictionary *)params {
  NSLog(@"<<<< bannerDidInteract >>>>");
  [self.connector adapterDidGetAdClick:self];
}

- (void)userWillLeaveApplicationFromBanner:(nonnull IMBanner *)banner {
  NSLog(@"<<<< bannerWillLeaveApplication >>>>");
  [self.connector adapterWillLeaveApplication:self];
}

- (void)bannerWillPresentScreen:(nonnull IMBanner *)banner {
  NSLog(@"<<<< bannerWillPresentScreen >>>>");
  [self.connector adapterWillPresentFullScreenModal:self];
}

- (void)bannerDidPresentScreen:(nonnull IMBanner *)banner {
  NSLog(@"InMobi banner did present screen");
}

- (void)bannerWillDismissScreen:(nonnull IMBanner *)banner {
  NSLog(@"<<<< bannerWillDismissScreen >>>>");
  [self.connector adapterWillDismissFullScreenModal:self];
}

- (void)bannerDidDismissScreen:(nonnull IMBanner *)banner {
  NSLog(@"<<<< bannerDidDismissScreen >>>>");
  [self.connector adapterDidDismissFullScreenModal:self];
}

- (void)banner:(nonnull IMBanner *)banner
    rewardActionCompletedWithRewards:(nonnull NSDictionary *)rewards {
  NSLog(@"InMobi banner reward action completed with rewards: %@", [rewards description]);
}

#pragma mark IMAdInterstitialDelegate methods

- (void)interstitialDidFinishLoading:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialDidFinishRequest >>>>");
  [self.connector adapterDidReceiveInterstitial:self];
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToLoadWithError:(IMRequestStatus *)error {
  NSLog(@"interstitial did fail with error=%@", [error localizedDescription]);
  NSLog(@"error code=%ld", (long)[error code]);
  NSInteger errorCode = GADMAdapterInMobiAdMobErrorCodeForInMobiCode([error code]);
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                          code:errorCode
                                                      userInfo:errorInfo];
  [self.connector adapter:self didFailAd:reqError];
}

- (void)interstitialWillPresent:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialWillPresentScreen >>>>");
  if (self.connector != nil) {
    [self.connector adapterWillPresentInterstitial:self];
  }
}

- (void)interstitialDidPresent:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialDidPresent >>>>");
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToPresentWithError:(IMRequestStatus *)error {
  NSLog(@"interstitial did fail with error=%@", [error localizedDescription]);
  NSLog(@"error code=%ld", (long)[error code]);
  NSInteger errorCode = GADMAdapterInMobiAdMobErrorCodeForInMobiCode([error code]);
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                          code:errorCode
                                                      userInfo:errorInfo];
  [self.connector adapter:self didFailAd:reqError];
}

- (void)interstitialWillDismiss:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialWillDismiss >>>>");
  if (self.connector != nil) {
    [self.connector adapterWillDismissInterstitial:self];
  }
}

- (void)interstitialDidDismiss:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialDidDismiss >>>>");
  [self.connector adapterDidDismissInterstitial:self];
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didInteractWithParams:(nonnull NSDictionary *)params {
  NSLog(@"<<<< interstitialDidInteract >>>>");
  [self.connector adapterDidGetAdClick:self];
}

- (void)userWillLeaveApplicationFromInterstitial:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< userWillLeaveApplicationFromInterstitial >>>>");
  [self.connector adapterWillLeaveApplication:self];
}

- (void)interstitialDidReceiveAd:(nonnull IMInterstitial *)interstitial {
  NSLog(@"InMobi AdServer returned a response");
}

/**
 * Notifies the delegate that the native ad has finished loading
 */
- (void)nativeDidFinishLoading:(nonnull IMNative *)native {
  if (self.native != native) {
    GADRequestError *reqError = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                            code:kGADErrorNoFill
                                                        userInfo:nil];
    [self.connector adapter:self didFailAd:reqError];
    return;
  }

  self.nativeAd =
      [[InMobiMediatedUnifiedNativeAd alloc] initWithInMobiUnifiedNativeAd:native
                                                                   adapter:self
                                                       shouldDownloadImage:self.shouldDownloadImages
                                                                     cache:imageCache];
}

/**
 * Notifies the delegate that the native ad has failed to load with error.
 */
- (void)native:(nonnull IMNative *)native didFailToLoadWithError:(nonnull IMRequestStatus *)error {
  NSLog(@"Native Ad failed to load");
  NSInteger errorCode = GADMAdapterInMobiAdMobErrorCodeForInMobiCode([error code]);
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                          code:errorCode
                                                      userInfo:errorInfo];

  [self.connector adapter:self didFailAd:reqError];
}

/**
 * Notifies the delegate that the native ad would be presenting a full screen content.
 */
- (void)nativeWillPresentScreen:(nonnull IMNative *)native {
  NSLog(@"Native Will Present screen");
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:self.nativeAd];
}

/**
 * Notifies the delegate that the native ad has presented a full screen content.
 */
- (void)nativeDidPresentScreen:(nonnull IMNative *)native {
  NSLog(@"Native Did Present screen");
}

/**
 * Notifies the delegate that the native ad would be dismissing the presented full screen content.
 */
- (void)nativeWillDismissScreen:(nonnull IMNative *)native {
  NSLog(@"Native Will dismiss screen");
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:self.nativeAd];
}

/**
 * Notifies the delegate that the native ad has dismissed the presented full screen content.
 */
- (void)nativeDidDismissScreen:(nonnull IMNative *)native {
  NSLog(@"Native Did dismiss screen");
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:self.nativeAd];
}

/**
 * Notifies the delegate that the user will be taken outside the application context.
 */
- (void)userWillLeaveApplicationFromNative:(nonnull IMNative *)native {
  NSLog(@"User will leave application from native");
  [self.connector adapterWillLeaveApplication:self];
}

- (void)nativeAdImpressed:(nonnull IMNative *)native {
  NSLog(@"InMobi recorded impression successfully");
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self.nativeAd];
}

- (void)native:(nonnull IMNative *)native didInteractWithParams:(nonnull NSDictionary *)params {
  NSLog(@"User did interact with native");
}

- (void)nativeDidFinishPlayingMedia:(nonnull IMNative *)native {
  NSLog(@"Native ad finished playing media");
}

- (void)userDidSkipPlayingMediaFromNative:(nonnull IMNative *)native {
  NSLog(@"User did skip playing media from native");
}

@end

//
//  GADMAdapterInMobi.m
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import "GADMAdapterInMobi.h"
#import "GADInMobiExtras.h"
#import "InMobiMediatedNativeAppInstallAd.h"
#import "NativeAdKeys.h"
#import <InMobiSDK/IMSdk.h>
#import "GADMInMobiConsent.h"

@interface GADInMobiExtras ()
@property(nonatomic, retain) NSString *city, *state, *country;
@property(nonatomic, retain) CLLocation *location;
@end

@interface GADMAdapterInMobi ()
@property(nonatomic, assign) CGFloat width, height;
@property(nonatomic, strong) InMobiMediatedNativeAppInstallAd *installAd;
@property(nonatomic, strong) GADInMobiExtras *extraInfo;
@property(nonatomic, assign) BOOL isAppInstallRequest;
@property(nonatomic, assign) BOOL isNativeContentRequest;
@property(nonatomic, assign) BOOL shouldDownloadImages;
@property(nonatomic, assign) BOOL serveAnyAd;
@end

@implementation GADMAdapterInMobi
@synthesize adView = adView_;
@synthesize interstitial = interstitial_;
@synthesize adRewarded = adRewarded_;
@synthesize native = native_;

static NSCache *imageCache;

static BOOL isAccountInitialised = false;

__attribute__((constructor)) static void initialize_imageCache() {
  imageCache = [[NSCache alloc] init];
}

@synthesize connector = connector_;

+ (NSString *)adapterVersion {
  return @"7.2.4.0";
}

+ (BOOL) isAppInitialised {
  return isAccountInitialised;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADInMobiExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id)connector {
  self.connector = connector;
  self.isAppInstallRequest = NO;
  self.isNativeContentRequest = NO;
  self.shouldDownloadImages = YES;
  self.serveAnyAd = NO;
  if ((self = [super init])) {
    self.connector = connector;
  }
    [IMSdk initWithAccountID:[[self.connector credentials] objectForKey:@"accountid"] consentDictionary:[GADMInMobiConsent getConsent]];
    isAccountInitialised = true;
  NSLog(@"Initialized successfully");
  if (self.rewardedConnector) {
    self.rewardedConnector = nil;
  }

  return self;
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
        (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  self.rewardedConnector = connector;
    [IMSdk initWithAccountID:[[self.rewardedConnector credentials] objectForKey:@"accountid"] consentDictionary:[GADMInMobiConsent getConsent]];
    isAccountInitialised = true;
  if (self.connector) {
    self.connector = nil;
  }
  return self;
}

- (void)prepareRequestParameters {
  if ([self.connector userGender] == kGADGenderMale ||
      [self.rewardedConnector userGender] == kGADGenderMale) {
    [IMSdk setGender:kIMSDKGenderMale];
  } else if ([self.connector userGender] == kGADGenderFemale ||
             [self.rewardedConnector userGender] == kGADGenderFemale) {
    [IMSdk setGender:kIMSDKGenderFemale];
  }

  if ([self.connector userBirthday] != nil) {
    NSDateComponents *components = [[NSCalendar currentCalendar]
        components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
          fromDate:[self.connector userBirthday]];
    [IMSdk setYearOfBirth:[components year]];
  }

  if (self.rewardedConnector) {
    self.extraInfo = [self.rewardedConnector networkExtras];
  } else if (self.connector) {
    self.extraInfo = [self.connector networkExtras];
  }

  if (self.extraInfo != nil) {
    if (self.extraInfo.postalCode != nil) [IMSdk setPostalCode:self.extraInfo.postalCode];
    if (self.extraInfo.areaCode != nil) [IMSdk setAreaCode:self.extraInfo.areaCode];
    if (self.extraInfo.interests != nil) [IMSdk setInterests:self.extraInfo.interests];
    if (self.extraInfo.age != nil) [IMSdk setAge:self.extraInfo.age];
    if (self.extraInfo.yearOfBirth != nil) [IMSdk setYearOfBirth:self.extraInfo.yearOfBirth];
    if (self.extraInfo.city && self.extraInfo.state && self.extraInfo.country) {
      [IMSdk setLocationWithCity:self.extraInfo.city
                           state:self.extraInfo.state
                         country:self.extraInfo.country];
    }
    if (self.extraInfo.language != nil) [IMSdk setLanguage:self.extraInfo.language];
  }

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  if (self.extraInfo && self.extraInfo.additionalParameters) {
    dict = [NSMutableDictionary dictionaryWithDictionary:self.extraInfo.additionalParameters];
  }

  [dict setObject:@"c_admob" forKey:@"tp"];
  [dict setObject:[GADRequest sdkVersion] forKey:@"tp-ver"];

  if ([[self.connector childDirectedTreatment] integerValue] == 1 ||
      [[self.rewardedConnector childDirectedTreatment] integerValue] == 1) {
    [dict setObject:@"1" forKey:@"coppa"];
  } else {
    [dict setObject:@"0" forKey:@"coppa"];
  }

  if (self.adView) {
    // Let Mediation do the refresh animation.
    self.adView.transitionAnimation = UIViewAnimationTransitionNone;
    if (self.extraInfo.keywords != nil) [self.adView setKeywords:self.extraInfo.keywords];
    [self.adView setExtras:[NSDictionary dictionaryWithDictionary:dict]];
  } else if (self.interstitial) {
    if (self.extraInfo.keywords != nil) [self.interstitial setKeywords:self.extraInfo.keywords];
    [self.interstitial setExtras:[NSDictionary dictionaryWithDictionary:dict]];
  } else if (self.adRewarded) {
    if (self.extraInfo.keywords != nil) [self.adRewarded setKeywords:self.extraInfo.keywords];
    [self.adRewarded setExtras:[NSDictionary dictionaryWithDictionary:dict]];
  } else if (self.native) {
    if (self.extraInfo.keywords != nil) [self.native setKeywords:self.extraInfo.keywords];
    [self.native setExtras:[NSDictionary dictionaryWithDictionary:dict]];
  }
}

- (Boolean)isPerformanceAd:(IMNative *)imNative {
  NSData *data = [imNative.customAdContent dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error = nil;
  NSDictionary *jsonDictionary =
      [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
  if ([[jsonDictionary objectForKey:PACKAGE_NAME] length]) {
    return YES;
  }
  return NO;
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  long long placementId = self.placementId;
  if (placementId == -1) {
    NSString *errorDesc =
        [NSString stringWithFormat:@"[InMobi] Exception - Placement ID not specified."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADErrorDomain
                                                         code:kGADErrorInvalidRequest
                                                     userInfo:errorInfo];
    [self.connector adapter:self didFailAd:error];
    return;
  }

  if ([self.connector testMode]) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to recieve test ads from "
          @"Inmobi");
  }

  for (NSString *adType in adTypes) {
    if ([adType isEqual:kGADAdLoaderAdTypeNativeContent]) {
      self.isNativeContentRequest = YES;
    } else if ([adType isEqual:kGADAdLoaderAdTypeNativeAppInstall]) {
      self.isAppInstallRequest = YES;
    }
  }
  self.serveAnyAd = (self.isAppInstallRequest && self.isNativeContentRequest);

  if (!self.serveAnyAd) {
    GADRequestError *reqError =
        [GADRequestError errorWithDomain:kGADErrorDomain code:kGADErrorInvalidRequest userInfo:nil];
    [self.connector adapter:self didFailAd:reqError];
    return;
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
  long long placementId = self.placementId;
  if (placementId == -1) {
    NSString *errorDesc =
        [NSString stringWithFormat:@"[InMobi] Exception - Placement ID not specified."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADErrorDomain
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
  long long placementId = self.placementId;

  if (placementId == -1) {
    NSString *errorDesc =
        [NSString stringWithFormat:@"[InMobi] Exception - Placement ID not specified."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADErrorDomain
                                                         code:kGADErrorInvalidRequest
                                                     userInfo:errorInfo];
    [self.connector adapter:self didFailAd:error];
    return;
  }

  if ([self.connector testMode]) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to recieve test ads from "
          @"Inmobi");
  }

  if (GADAdSizeEqualToSize(adSize, kGADAdSizeBanner)) {
    self.adView = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 320, 50)
                                      placementId:placementId];  // self.placementId is hardcoded
  } else if (GADAdSizeEqualToSize(adSize, kGADAdSizeMediumRectangle)) {
    self.adView = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 300, 250)
                                      placementId:placementId];  // self.placementId is hardcoded
  } else if (GADAdSizeEqualToSize(adSize, kGADAdSizeFullBanner)) {
    self.adView = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 468, 60)
                                      placementId:placementId];  // self.placementId is hardcoded
  } else if (GADAdSizeEqualToSize(adSize, kGADAdSizeLeaderboard)) {
    self.adView = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 728, 90)
                                      placementId:placementId];  // self.placementId is hardcoded
  } else if (GADAdSizeEqualToSize(adSize, kGADAdSizeSkyscraper)) {
    self.adView = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 120, 600)
                                      placementId:placementId];  // self.placementId is hardcoded
  } else if ((GADAdSizeEqualToSize(adSize, kGADAdSizeSmartBannerPortrait)) ||
             (GADAdSizeEqualToSize(adSize, kGADAdSizeSmartBannerLandscape))) {
    [self getOptimalSlotSize];
    self.adView = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)
                                      placementId:placementId];  // self.placementId is hardcoded
  } else {
    NSString *errorDesc = [NSString
        stringWithFormat:@"[InMobi] Exception - Invalid ad type %@", NSStringFromGADAdSize(adSize)];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADErrorDomain
                                                         code:kGADErrorMediationInvalidAdSize
                                                     userInfo:errorInfo];
    [self.connector adapter:self didFailAd:error];
    return;
  }
  // Let Mediation do the refresh.
  [self.adView shouldAutoRefresh:NO];
  self.adView.delegate = self;
  [self prepareRequestParameters];
  [self.adView load];
}

- (void)setUp {
  if (self)
    [self.rewardedConnector adapterDidSetUpRewardBasedVideoAd:self];
  else {
    NSString *errorDesc =
        [NSString stringWithFormat:@"[InMobi] Exception - Error at the time of setting up adapter"];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADErrorDomain
                                                         code:kGADErrorMediationAdapterError
                                                     userInfo:errorInfo];
    [self.rewardedConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
  }
}

- (void)requestRewardBasedVideoAd {
  long long placementId = self.placementId;
  if (placementId == -1) {
    NSString *errorDesc =
        [NSString stringWithFormat:@"[InMobi] Exception - Placement ID not specified."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADErrorDomain
                                                         code:kGADErrorInvalidRequest
                                                     userInfo:errorInfo];
    [self.connector adapter:self didFailAd:error];
    return;
  }

  if ([self.connector testMode]) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to recieve test ads from "
          @"Inmobi");
  }

  self.adRewarded = [[IMInterstitial alloc] initWithPlacementId:placementId];
  [self prepareRequestParameters];
  self.adRewarded.delegate = self;
  [self.adRewarded load];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  if ([self.adRewarded isReady]) {
    [self.adRewarded showFromViewController:viewController];
  }
}

- (void)getOptimalSlotSize {
  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat screenWidth = CGRectGetWidth(screenBounds);
  CGFloat screenHeight = CGRectGetHeight(screenBounds);

  NSMutableArray *dataArray = [[NSMutableArray alloc] initWithCapacity:3];
  [dataArray insertObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithInt:728],
                                                           [NSNumber numberWithInt:90], nil]
                  atIndex:0];
  [dataArray insertObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithInt:468],
                                                           [NSNumber numberWithInt:60], nil]
                  atIndex:1];
  [dataArray insertObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithInt:320],
                                                           [NSNumber numberWithInt:50], nil]
                  atIndex:2];

  for (int i = 0; i < [dataArray count]; i++) {
    if (([[[dataArray objectAtIndex:i] objectAtIndex:0] intValue] <= screenWidth) &&
        ([[[dataArray objectAtIndex:i] objectAtIndex:1] intValue]) <= screenHeight) {
      self.width = [[[dataArray objectAtIndex:i] objectAtIndex:0] intValue];
      self.height = [[[dataArray objectAtIndex:i] objectAtIndex:1] intValue];
    }
  }
  self.width = [[[dataArray objectAtIndex:2] objectAtIndex:0] intValue];
  self.height = [[[dataArray objectAtIndex:2] objectAtIndex:1] intValue];
}

- (void)stopBeingDelegate {
  self.adView.delegate = nil;
  self.interstitial.delegate = nil;
  self.adRewarded.delegate = nil;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
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
  if (self.connector != nil && [[self.connector credentials] objectForKey:@"placementid"]) {
    return [[[self.connector credentials] objectForKey:@"placementid"] longLongValue];
  } else if (self.rewardedConnector != nil &&
             [[self.rewardedConnector credentials] objectForKey:@"placementid"]) {
    return [[[self.rewardedConnector credentials] objectForKey:@"placementid"] longLongValue];
  }
  return -1;
}

#pragma mark Convert InMobi Error codes to Google's

- (NSInteger)getAdMobErrorCode:(NSInteger)inmobiErrorCode {
  NSInteger errorCode;
  switch (inmobiErrorCode) {
    case kIMStatusCodeNoFill:
      errorCode = kGADErrorMediationNoFill;
      break;
    case kIMStatusCodeRequestTimedOut:
      errorCode = kGADErrorTimeout;
      break;
    case kIMStatusCodeServerError:
      errorCode = kGADErrorServerError;
      break;
    case kIMStatusCodeInternalError:
      errorCode = kGADErrorInternalError;
      break;
    default:
      errorCode = kGADErrorInternalError;
      break;
  }
  return errorCode;
}

#pragma mark IMBannerDelegate methods

- (void)bannerDidFinishLoading:(IMBanner *)banner {
  NSLog(@"<<<<<ad request completed>>>>>");
  [self.connector adapter:self didReceiveAdView:banner];
}

- (void)banner:(IMBanner *)banner didFailToLoadWithError:(IMRequestStatus *)error {
  NSInteger errorCode = [self getAdMobErrorCode:[error code]];
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError =
      [GADRequestError errorWithDomain:kGADErrorDomain code:errorCode userInfo:errorInfo];
  [self.connector adapter:self didFailAd:reqError];
  NSLog(@"<<<< ad request failed.>>>, error=%@", error);
  NSLog(@"error code=%ld", (long)[error code]);
}

- (void)banner:(IMBanner *)banner didInteractWithParams:(NSDictionary *)params {
  NSLog(@"<<<< bannerDidInteract >>>>");
  [self.connector adapterDidGetAdClick:self];
}

- (void)userWillLeaveApplicationFromBanner:(IMBanner *)banner {
  NSLog(@"<<<< bannerWillLeaveApplication >>>>");
  [self.connector adapterWillLeaveApplication:self];
}

- (void)bannerWillPresentScreen:(IMBanner *)banner {
  NSLog(@"<<<< bannerWillPresentScreen >>>>");
  [self.connector adapterWillPresentFullScreenModal:self];
}

- (void)bannerDidPresentScreen:(IMBanner *)banner {
  NSLog(@"InMobi banner did present screen");
}

- (void)bannerWillDismissScreen:(IMBanner *)banner {
  NSLog(@"<<<< bannerWillDismissScreen >>>>");
  [self.connector adapterWillDismissFullScreenModal:self];
}

- (void)bannerDidDismissScreen:(IMBanner *)banner {
  NSLog(@"<<<< bannerDidDismissScreen >>>>");
  [self.connector adapterDidDismissFullScreenModal:self];
}

- (void)banner:(IMBanner *)banner rewardActionCompletedWithRewards:(NSDictionary *)rewards {
  NSLog(@"InMobi banner reward action completed with rewards: %@", [rewards description]);
}

#pragma mark IMAdInterstitialDelegate methods

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialDidFinishRequest >>>>");
  if (self.rewardedConnector != nil)
    [self.rewardedConnector adapterDidReceiveRewardBasedVideoAd:self];
  else
    [self.connector adapterDidReceiveInterstitial:self];
}

- (void)interstitial:(IMInterstitial *)interstitial
    didFailToLoadWithError:(IMRequestStatus *)error {
  NSLog(@"interstitial did fail with error=%@", [error localizedDescription]);
  NSLog(@"error code=%ld", (long)[error code]);
  NSInteger errorCode = [self getAdMobErrorCode:[error code]];
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError =
      [GADRequestError errorWithDomain:kGADErrorDomain code:errorCode userInfo:errorInfo];
  if (self.rewardedConnector != nil)
    [self.rewardedConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:reqError];
  else
    [self.connector adapter:self didFailAd:reqError];
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialWillPresentScreen >>>>");
  if (self.connector != nil) [self.connector adapterWillPresentInterstitial:self];
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialDidPresent >>>>");
  if (self.rewardedConnector != nil) {
    [self.rewardedConnector adapterDidOpenRewardBasedVideoAd:self];
    [self.rewardedConnector adapterDidStartPlayingRewardBasedVideoAd:self];
  }
}

- (void)interstitial:(IMInterstitial *)interstitial
    didFailToPresentWithError:(IMRequestStatus *)error {
  NSLog(@"interstitial did fail with error=%@", [error localizedDescription]);
  NSLog(@"error code=%ld", (long)[error code]);
  NSInteger errorCode = [self getAdMobErrorCode:[error code]];
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError =
      [GADRequestError errorWithDomain:kGADErrorDomain code:errorCode userInfo:errorInfo];
  [self.connector adapter:self didFailAd:reqError];
}

- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialWillDismiss >>>>");
  if (self.connector != nil) [self.connector adapterWillDismissInterstitial:self];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialDidDismiss >>>>");
  if (self.rewardedConnector != nil)
    [self.rewardedConnector adapterDidCloseRewardBasedVideoAd:self];
  else
    [self.connector adapterDidDismissInterstitial:self];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params {
  NSLog(@"<<<< interstitialDidInteract >>>>");
  if (self.rewardedConnector != nil)
    [self.rewardedConnector adapterDidGetAdClick:self];
  else
    [self.connector adapterDidGetAdClick:self];
}

- (void)interstitial:(IMInterstitial *)interstitial
    rewardActionCompletedWithRewards:(NSDictionary *)rewards {
  NSLog(@"InMobi interstitial reward action completed with rewards: %@", [rewards description]);
  NSString *key = [rewards allKeys][0];

  if (self.rewardedConnector != nil) {
    [self.rewardedConnector adapterDidCompletePlayingRewardBasedVideoAd:self];
    GADAdReward *reward =
        [[GADAdReward alloc] initWithRewardType:key rewardAmount:[rewards objectForKey:key]];
    [self.rewardedConnector adapter:self didRewardUserWithReward:reward];
  }
}

- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial *)interstitial {
  NSLog(@"<<<< userWillLeaveApplicationFromInterstitial >>>>");
  if (self.rewardedConnector != nil)
    [self.rewardedConnector adapterWillLeaveApplication:self];
  else
    [self.connector adapterWillLeaveApplication:self];
}

- (void)interstitialDidReceiveAd:(IMInterstitial *)interstitial {
  NSLog(@"InMobi AdServer returned a response");
}

/**
 * Notifies the delegate that the native ad has finished loading
 */
- (void)nativeDidFinishLoading:(IMNative *)native {
  if (self.native != native) {
    GADRequestError *reqError = [GADRequestError errorWithDomain:kGADErrorDomain
                                                            code:kGADErrorMediationNoFill
                                                        userInfo:nil];
    [self.connector adapter:self didFailAd:reqError];
    self.isNativeContentRequest = NO;
    self.isAppInstallRequest = NO;
    return;
  }

  self.installAd = [[InMobiMediatedNativeAppInstallAd alloc]
      initWithInMobiNativeAppInstallAd:native
                           withAdapter:self
                   shouldDownloadImage:self.shouldDownloadImages
                             withCache:imageCache];

  self.isNativeContentRequest = NO;
  self.isAppInstallRequest = NO;
}

/**
 * Notifies the delegate that the native ad has failed to load with error.
 */
- (void)native:(IMNative *)native didFailToLoadWithError:(IMRequestStatus *)error {
  NSLog(@"Native Ad failed to load");
  NSInteger errorCode = [self getAdMobErrorCode:[error code]];
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError =
      [GADRequestError errorWithDomain:kGADErrorDomain code:errorCode userInfo:errorInfo];

  [self.connector adapter:self didFailAd:reqError];
  self.isNativeContentRequest = NO;
  self.isAppInstallRequest = NO;
}

/**
 * Notifies the delegate that the native ad would be presenting a full screen content.
 */
- (void)nativeWillPresentScreen:(IMNative *)native {
  NSLog(@"Native Will Present screen");
  [GADMediatedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:self.installAd];
}

/**
 * Notifies the delegate that the native ad has presented a full screen content.
 */
- (void)nativeDidPresentScreen:(IMNative *)native {
  NSLog(@"Native Did Present screen");
}

/**
 * Notifies the delegate that the native ad would be dismissing the presented full screen content.
 */
- (void)nativeWillDismissScreen:(IMNative *)native {
  NSLog(@"Native Will dismiss screen");
  [GADMediatedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:self.installAd];
}

/**
 * Notifies the delegate that the native ad has dismissed the presented full screen content.
 */
- (void)nativeDidDismissScreen:(IMNative *)native {
  NSLog(@"Native Did dismiss screen");
  [GADMediatedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:self.installAd];
}

/**
 * Notifies the delegate that the user will be taken outside the application context.
 */
- (void)userWillLeaveApplicationFromNative:(IMNative *)native {
  NSLog(@"User will leave application from native");
  [self.connector adapterWillLeaveApplication:self];
}

- (void)nativeAdImpressed:(IMNative *)native {
  NSLog(@"InMobi recorded impression successfully");
  [GADMediatedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self.installAd];
}

- (void)native:(IMNative *)native didInteractWithParams:(NSDictionary *)params {
  NSLog(@"User did interact with native");
}

- (void)nativeDidFinishPlayingMedia:(IMNative *)native {
  NSLog(@"Native ad finished playing media");
}

- (void)userDidSkipPlayingMediaFromNative:(IMNative *)native {
  NSLog(@"User did skip playing media from native");
}


@end

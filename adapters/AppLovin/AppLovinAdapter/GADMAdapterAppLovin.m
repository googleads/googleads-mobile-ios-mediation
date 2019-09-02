//
//  GADMAdapterAppLovin.m
//
//
//  Created by Thomas So on 1/10/18.
//
//

#import "GADMAdapterAppLovin.h"
#import <AppLovinSDK/AppLovinSDK.h>
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinUtils.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Banner Delegate.
@interface GADMAdapterAppLovinBannerDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>
- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter;
@property(nonatomic, weak) GADMAdapterAppLovin *parentAdapter;
@end

/// AppLovin Interstitial Delegate.
@interface GADMAdapterAppLovinInterstitialDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate>
- (instancetype)initWithParentRenderer:(GADMAdapterAppLovin *)parentRenderer;
@property(nonatomic, weak) GADMAdapterAppLovin *parentRenderer;
@end

@interface GADMAdapterAppLovin ()

/// Controlled Properties.
@property(nonatomic, strong) ALSdk *sdk;
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;

/// Interstitial Properties.
@property(nonatomic, strong, nullable) ALInterstitialAd *interstitial;
@property(nonatomic, strong, nullable) ALAd *alInterstitialAd;
@property(nonatomic, strong) GADMAdapterAppLovinInterstitialDelegate *interstitialDelegate;
/// Banner Properties.
@property(nonatomic, strong, nullable) ALAdView *adView;
@property(nonatomic, strong) GADMAdapterAppLovinBannerDelegate *bannerDelegate;

/// Controller properties - The connector/credentials referencing these properties may get
/// deallocated.
@property(nonatomic, copy) NSString *placement;
// Placements are left in this adapter for backwards-compatibility purposes.
@property(nonatomic, copy) NSString *zoneIdentifier;

@property(nonatomic) GADAdSize adSize;
@property(nonatomic, strong) ALAd *ad;
@end

@implementation GADMAdapterAppLovin
static NSMutableArray *gRequestedInterstitialZoneIdentifiers;

+ (void)load {
  gRequestedInterstitialZoneIdentifiers = [[NSMutableArray alloc] init];
}

#pragma mark - GAD Ad Network Protocol Methods

+ (NSString *)adapterVersion {
  return GADMAdapterAppLovinConstant.adapterVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAppLovinExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    self.connector = connector;
    self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:connector.credentials];

    if (!self.sdk) {
      [GADMAdapterAppLovinUtils log:@"Failed to initialize SDK"];
    }
  }
  return self;
}

- (void)stopBeingDelegate {
  @synchronized(gRequestedInterstitialZoneIdentifiers) {
    if (_interstitial) {
      [gRequestedInterstitialZoneIdentifiers removeObject:self.zoneIdentifier];
    }
  }
  _interstitial = nil;
  self.connector = nil;
  self.interstitialDelegate = nil;
  self.bannerDelegate = nil;

  self.interstitial.adDisplayDelegate = nil;
  self.interstitial.adVideoPlaybackDelegate = nil;

  self.adView.adLoadDelegate = nil;
  self.adView.adDisplayDelegate = nil;
  self.adView.adEventDelegate = nil;
}

#pragma mark - GAD Ad Network Protocol Interstitial Methods

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  self.placement = [GADMAdapterAppLovinUtils retrievePlacementFromConnector:strongConnector];
  self.zoneIdentifier =
      [GADMAdapterAppLovinUtils retrieveZoneIdentifierFromConnector:strongConnector];

  [GADMAdapterAppLovinUtils log:@"Requesting interstitial for zone: %@ and placement: %@",
                                self.zoneIdentifier, self.placement];

  NSArray *requestedZones;
  @synchronized(gRequestedInterstitialZoneIdentifiers) {
    requestedZones = [NSArray arrayWithArray:gRequestedInterstitialZoneIdentifiers];
  }

  if ([requestedZones containsObject:self.zoneIdentifier]) {
    [GADMAdapterAppLovinUtils log:@"Can't request a second ad for the same zone Identifier "
                                  @"without showing the first ad."];
    NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                         code:0
                                     userInfo:nil];
    [strongConnector adapter:self didFailAd:error];
  } else {
    self.interstitialDelegate =
        [[GADMAdapterAppLovinInterstitialDelegate alloc] initWithParentRenderer:self];
    _interstitial = [[ALInterstitialAd alloc] initWithSdk:self.sdk];
    _interstitial.adDisplayDelegate = self.interstitialDelegate;
    _interstitial.adVideoPlaybackDelegate = self.interstitialDelegate;

    @synchronized(gRequestedInterstitialZoneIdentifiers) {
      [gRequestedInterstitialZoneIdentifiers addObject:self.zoneIdentifier];
    }

    if (self.zoneIdentifier.length > 0) {
      [self.sdk.adService loadNextAdForZoneIdentifier:self.zoneIdentifier
                                            andNotify:self.interstitialDelegate];
    } else {
      [self.sdk.adService loadNextAd:[ALAdSize sizeInterstitial]
                           andNotify:self.interstitialDelegate];
    }
  }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  GADMAdapterAppLovinExtras *networkExtras = strongConnector.networkExtras;
  self.sdk.settings.muted = networkExtras.muteAudio;

  [GADMAdapterAppLovinUtils log:@"Showing interstitial ad: %@ for zone: %@ placement: %@",
                                _alInterstitialAd.adIdNumber, self.zoneIdentifier, self.placement];
  [self.interstitial showAd:_alInterstitialAd];
}

#pragma mark - GAD Ad Network Protocol Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  self.adSize = adSize;
  self.placement = [GADMAdapterAppLovinUtils retrievePlacementFromConnector:strongConnector];
  self.zoneIdentifier =
      [GADMAdapterAppLovinUtils retrieveZoneIdentifierFromConnector:strongConnector];

  [GADMAdapterAppLovinUtils log:@"Requesting banner of size %@ for zone: %@ and placement: %@",
                                NSStringFromGADAdSize(adSize), self.zoneIdentifier, self.placement];

  // Convert requested size to AppLovin Ad Size.
  ALAdSize *appLovinAdSize = [GADMAdapterAppLovinUtils adSizeFromRequestedSize:adSize];

  if (appLovinAdSize) {
    self.adView = [[ALAdView alloc] initWithSdk:self.sdk size:appLovinAdSize];

    CGSize size = CGSizeFromGADAdSize(adSize);
    self.adView.frame = CGRectMake(0, 0, size.width, size.height);

    self.bannerDelegate = [[GADMAdapterAppLovinBannerDelegate alloc] initWithParentAdapter:self];
    self.adView.adLoadDelegate = self.bannerDelegate;
    self.adView.adDisplayDelegate = self.bannerDelegate;
    self.adView.adEventDelegate = self.bannerDelegate;

    if (self.zoneIdentifier.length > 0) {
      [self.sdk.adService loadNextAdForZoneIdentifier:self.zoneIdentifier
                                            andNotify:self.bannerDelegate];
    } else {
      [self.sdk.adService loadNextAd:appLovinAdSize andNotify:self.bannerDelegate];
    }
  } else {
    [GADMAdapterAppLovinUtils log:@"Failed to request banner with unsupported size"];

    NSError *error =
        [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                            code:kGADErrorMediationInvalidAdSize
                        userInfo:@{
                          NSLocalizedFailureReasonErrorKey :
                              @"Adapter requested to display a banner ad of unsupported size"
                        }];
    [strongConnector adapter:self didFailAd:error];
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (nullable ALAdSize *)appLovinAdSizeFromRequestedSize:(GADAdSize)size {
  GADAdSize banner = GADAdSizeFromCGSize(CGSizeMake(320, 50));
  GADAdSize leaderboard = GADAdSizeFromCGSize(CGSizeMake(728, 90));
  GADAdSize mRect = GADAdSizeFromCGSize(CGSizeMake(300, 250));
  NSArray *potentials = @[
    NSValueFromGADAdSize(banner), NSValueFromGADAdSize(mRect), NSValueFromGADAdSize(leaderboard)
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(size, potentials);
  CGSize closestCGSize = CGSizeFromGADAdSize(closestSize);
  if (CGSizeEqualToSize(CGSizeFromGADAdSize(banner), closestCGSize)) {
    return [ALAdSize sizeBanner];
  } else if (CGSizeEqualToSize(CGSizeFromGADAdSize(leaderboard), closestCGSize)) {
    return [ALAdSize sizeLeader];
  } else if (CGSizeEqualToSize(CGSizeFromGADAdSize(mRect), closestCGSize)) {
    return [ALAdSize sizeMRec];
  }

  [GADMAdapterAppLovinUtils
      log:@"Unable to retrieve AppLovin size from GADAdSize: %@", NSStringFromGADAdSize(size)];
  return nil;
}

@end

@implementation GADMAdapterAppLovinInterstitialDelegate

#pragma mark - Initialization

- (instancetype)initWithParentRenderer:(GADMAdapterAppLovin *)parentRenderer {
  self = [super init];
  if (self) {
    self.parentRenderer = parentRenderer;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
  GADMAdapterAppLovin *parentRenderer = self.parentRenderer;
  [GADMAdapterAppLovinUtils log:@"Interstitial did load ad: %@ for zone: %@", ad.adIdNumber,
                                parentRenderer.zoneIdentifier];
  parentRenderer.alInterstitialAd = ad;
  [parentRenderer.connector adapterDidReceiveInterstitial:parentRenderer];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
  GADMAdapterAppLovin *parentRenderer = self.parentRenderer;
  [GADMAdapterAppLovinUtils log:@"Interstitial failed to load with error: %d", code];

  @synchronized(gRequestedInterstitialZoneIdentifiers) {
    [gRequestedInterstitialZoneIdentifiers removeObject:parentRenderer.zoneIdentifier];
  }

  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                       code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                                   userInfo:nil];

  [parentRenderer.connector adapter:parentRenderer didFailAd:error];
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial displayed"];
  GADMAdapterAppLovin *parentRenderer = self.parentRenderer;
  [parentRenderer.connector adapterWillPresentInterstitial:parentRenderer];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial hidden"];
  GADMAdapterAppLovin *parentRenderer = self.parentRenderer;
  @synchronized(gRequestedInterstitialZoneIdentifiers) {
    [gRequestedInterstitialZoneIdentifiers removeObject:parentRenderer.zoneIdentifier];
  }
  id<GADMAdNetworkConnector> strongConnector = parentRenderer.connector;
  [strongConnector adapterWillDismissInterstitial:parentRenderer];
  [strongConnector adapterDidDismissInterstitial:parentRenderer];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];
  GADMAdapterAppLovin *parentRenderer = self.parentRenderer;
  id<GADMAdNetworkConnector> strongConnector = parentRenderer.connector;
  [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];
  [strongConnector adapterDidGetAdClick:parentRenderer];
  [strongConnector adapterWillLeaveApplication:parentRenderer];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Interstitial video playback began"];
}

- (void)videoPlaybackEndedInAd:(ALAd *)ad
             atPlaybackPercent:(NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
  [GADMAdapterAppLovinUtils log:@"Interstitial video playback ended at playback percent: %lu%%",
                                percentPlayed.unsignedIntegerValue];
}

@end

@implementation GADMAdapterAppLovinBannerDelegate

#pragma mark - Initialization

- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter {
  self = [super init];
  if (self) {
    self.parentAdapter = parentAdapter;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
  GADMAdapterAppLovin *parentAdapter = self.parentAdapter;
  [GADMAdapterAppLovinUtils log:@"Banner did load ad: %@ for zone: %@ and placement: %@",
                                ad.adIdNumber, parentAdapter.zoneIdentifier,
                                parentAdapter.placement];
  [parentAdapter.adView render:ad];
  [parentAdapter.connector adapter:parentAdapter didReceiveAdView:parentAdapter.adView];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [GADMAdapterAppLovinUtils log:@"Banner failed to load with error: %d", code];
  GADMAdapterAppLovin *parentAdapter = self.parentAdapter;
  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                       code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                                   userInfo:nil];
  [parentAdapter.connector adapter:parentAdapter didFailAd:error];
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Banner displayed"];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Banner dismissed"];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Banner clicked"];
  GADMAdapterAppLovin *parentAdapter = self.parentAdapter;
  [parentAdapter.connector adapterDidGetAdClick:parentAdapter];
}

#pragma mark - Ad View Event Delegate

- (void)ad:(ALAd *)ad didPresentFullscreenForAdView:(ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner presented fullscreen"];
  GADMAdapterAppLovin *parentAdapter = self.parentAdapter;
  [parentAdapter.connector adapterWillPresentFullScreenModal:parentAdapter];
}

- (void)ad:(ALAd *)ad willDismissFullscreenForAdView:(ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner will dismiss fullscreen"];
  GADMAdapterAppLovin *parentAdapter = self.parentAdapter;
  [parentAdapter.connector adapterWillDismissFullScreenModal:parentAdapter];
}

- (void)ad:(ALAd *)ad didDismissFullscreenForAdView:(ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner did dismiss fullscreen"];
  GADMAdapterAppLovin *parentAdapter = self.parentAdapter;
  [parentAdapter.connector adapterDidDismissFullScreenModal:parentAdapter];
}

- (void)ad:(ALAd *)ad willLeaveApplicationForAdView:(ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner left application"];
  GADMAdapterAppLovin *parentAdapter = self.parentAdapter;
  [parentAdapter.connector adapterWillLeaveApplication:parentAdapter];
}

- (void)ad:(ALAd *)ad
    didFailToDisplayInAdView:(ALAdView *)adView
                   withError:(ALAdViewDisplayErrorCode)code {
  [GADMAdapterAppLovinUtils log:@"Banner failed to display: %ld", code];
}

@end

#pragma clang diagnostic pop

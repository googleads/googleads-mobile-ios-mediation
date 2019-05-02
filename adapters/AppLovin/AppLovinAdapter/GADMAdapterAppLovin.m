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
#import "GADMAdapterAppLovinQueue.h"
#import "GADMAdapterAppLovinUtils.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface GADMAdapterAppLovin () <ALAdLoadDelegate,
                                   ALAdDisplayDelegate,
                                   ALAdVideoPlaybackDelegate,
                                   ALAdViewEventDelegate>

/// Controlled Properties.
@property(nonatomic, strong) ALSdk *sdk;
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;

/// Interstitial Properties.
@property(nonatomic, strong, nullable) ALInterstitialAd *interstitial;
@property(nonatomic, strong, nullable) ALAd *alInterstitialAd;
/// Banner Properties.
@property(nonatomic, strong, nullable) ALAdView *adView;

/// Controller properties - The connector/credentials referencing these properties may get
/// deallocated.
@property(nonatomic, copy) NSString *placement;
// Placements are left in this adapter for backwards-compatibility purposes.
@property(nonatomic, copy) NSString *zoneIdentifier;

@property(nonatomic) GADAdSize adSize;
@end

/// Banner Delegate.
@interface GADMAdapterAppLovinBannerDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>
@property(nonatomic, weak) GADMAdapterAppLovin *parentAdapter;
- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter;
@end

@implementation GADMAdapterAppLovin

__weak static GADMAdapterAppLovin *adapterWithDefaultZone = nil;

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
  self.connector = nil;

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

  if (adapterWithDefaultZone && self.zoneIdentifier.length < 1) {
    [GADMAdapterAppLovinUtils log:@"Can't request a second ad using the default zone identifier "
                                  @"without showing the first ad."];
    NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                         code:0
                                     userInfo:nil];
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _interstitial = [[ALInterstitialAd alloc] initWithSdk:self.sdk];
  _interstitial.adDisplayDelegate = self;
  _interstitial.adVideoPlaybackDelegate = self;

  if (self.zoneIdentifier.length > 0) {
    [self.sdk.adService loadNextAdForZoneIdentifier:self.zoneIdentifier andNotify:self];
  } else {
    adapterWithDefaultZone = self;
    [self.sdk.adService loadNextAd:[ALAdSize sizeInterstitial] andNotify:self];
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

    GADMAdapterAppLovinBannerDelegate *delegate =
        [[GADMAdapterAppLovinBannerDelegate alloc] initWithParentAdapter:self];
    self.adView.adLoadDelegate = delegate;
    self.adView.adDisplayDelegate = delegate;
    self.adView.adEventDelegate = delegate;

    if (self.zoneIdentifier.length > 0) {
      [self.sdk.adService loadNextAdForZoneIdentifier:self.zoneIdentifier andNotify:delegate];
    } else {
      [self.sdk.adService loadNextAd:appLovinAdSize andNotify:delegate];
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

#pragma mark - Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
  [GADMAdapterAppLovinUtils
      log:@"Interstitial did load ad: %@ for zone: %@", ad.adIdNumber, self.zoneIdentifier];
  self.alInterstitialAd = ad;
  [self.connector adapterDidReceiveInterstitial:self];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [GADMAdapterAppLovinUtils log:@"Interstitial failed to load with error: %d", code];

  NSError *error =
      [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                          code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                      userInfo:@{
                        NSLocalizedFailureReasonErrorKey :
                            @"Adapter requested to display an interstitial before one was loaded"
                      }];

  [self.connector adapter:self didFailAd:error];
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial displayed"];
  [self.connector adapterWillPresentInterstitial:self];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  [GADMAdapterAppLovinUtils log:@"Interstitial dismissed"];
  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];
  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillLeaveApplication:self];
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
  [GADMAdapterAppLovinUtils log:@"Banner did load ad: %@ for zone: %@ and placement: %@",
                                ad.adIdNumber, self.parentAdapter.zoneIdentifier,
                                self.parentAdapter.placement];

  [self.parentAdapter.adView render:ad];
  [self.parentAdapter.connector adapter:self.parentAdapter
                       didReceiveAdView:self.parentAdapter.adView];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [GADMAdapterAppLovinUtils log:@"Banner failed to load with error: %d", code];

  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                       code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                                   userInfo:nil];
  [self.parentAdapter.connector adapter:self.parentAdapter didFailAd:error];
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
  [self.parentAdapter.connector adapterDidGetAdClick:self.parentAdapter];
}

#pragma mark - Ad View Event Delegate

- (void)ad:(ALAd *)ad didPresentFullscreenForAdView:(ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner presented fullscreen"];
  [self.parentAdapter.connector adapterWillPresentFullScreenModal:self.parentAdapter];
}

- (void)ad:(ALAd *)ad willDismissFullscreenForAdView:(ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner will dismiss fullscreen"];
  [self.parentAdapter.connector adapterWillDismissFullScreenModal:self.parentAdapter];
}

- (void)ad:(ALAd *)ad didDismissFullscreenForAdView:(ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner did dismiss fullscreen"];
  [self.parentAdapter.connector adapterDidDismissFullScreenModal:self.parentAdapter];
}

- (void)ad:(ALAd *)ad willLeaveApplicationForAdView:(ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner left application"];
  [self.parentAdapter.connector adapterWillLeaveApplication:self.parentAdapter];
}

- (void)ad:(ALAd *)ad
    didFailToDisplayInAdView:(ALAdView *)adView
                   withError:(ALAdViewDisplayErrorCode)code {
  [GADMAdapterAppLovinUtils log:@"Banner failed to display: %ld", code];
}

@end

#pragma clang diagnostic pop

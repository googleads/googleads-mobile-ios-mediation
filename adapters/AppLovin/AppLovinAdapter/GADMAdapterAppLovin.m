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

@interface GADMAdapterAppLovin ()

/// Controlled Properties.
@property(nonatomic, strong) ALSdk *sdk;
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;

/// Interstitial Properties.
@property(nonatomic, strong, nullable) ALInterstitialAd *interstitial;

/// Banner Properties.
@property(nonatomic, strong, nullable) ALAdView *adView;

/// Controller properties - The connector/credentials referencing these properties may get
/// deallocated.
@property(nonatomic, copy) NSString
    *placement;  // Placements are left in this adapter for backwards-compatibility purposes.
@property(nonatomic, copy) NSString *zoneIdentifier;

@end

/// Interstitial Load Delegate.
@interface GADMAdapterAppLovinInterstitialLoadDelegate : NSObject <ALAdLoadDelegate>
@property(nonatomic, copy) NSString *zoneIdentifier;
- (instancetype)initWithZoneIdentifier:(NSString *)zoneIdentifier;
@end

/// Interstitial Delegate.
@interface GADMAdapterAppLovinInterstitialDelegate
    : NSObject <ALAdDisplayDelegate, ALAdVideoPlaybackDelegate, ALAdViewEventDelegate>
@property(nonatomic, weak) GADMAdapterAppLovin *parentAdapter;
- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter;
@end

/// Banner Delegate.
@interface GADMAdapterAppLovinBannerDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>
@property(nonatomic, weak) GADMAdapterAppLovin *parentAdapter;
- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter;
@end

@implementation GADMAdapterAppLovin

// Use weak references to allow AdMob to release our adapter when needed.
static NSMutableDictionary<NSString *, GADMAdapterAppLovinQueue<GADMAdapterAppLovin *> *>
    *ALInterstitialPendingLoadDelegates;
static NSMutableDictionary<NSString *, GADMAdapterAppLovinInterstitialLoadDelegate *>
    *ALInterstitialLoadDelegates;
static NSMutableDictionary<NSString *, GADMAdapterAppLovinQueue<ALAd *> *> *ALInterstitialAdQueues;
static NSObject *ALInterstitialAdQueueLock;

#pragma mark - Class Initialization

+ (void)initialize {
  ALInterstitialPendingLoadDelegates = [NSMutableDictionary dictionary];
  ALInterstitialLoadDelegates = [NSMutableDictionary dictionary];
  ALInterstitialAdQueues = [NSMutableDictionary dictionary];
  ALInterstitialAdQueueLock = [[NSObject alloc] init];
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
  @synchronized(ALInterstitialAdQueueLock) {
    self.placement = [GADMAdapterAppLovinUtils retrievePlacementFromConnector:strongConnector];
    self.zoneIdentifier =
        [GADMAdapterAppLovinUtils retrieveZoneIdentifierFromConnector:strongConnector];

    [GADMAdapterAppLovinUtils log:@"Requesting interstitial for zone: %@ and placement: %@",
                                  self.zoneIdentifier, self.placement];

    GADMAdapterAppLovinQueue *__nullable queue = ALInterstitialAdQueues[self.zoneIdentifier];

    // If we don't already have enqueued ads, fetch from SDK.
    if (queue.count == 0) {
      // Retrieve static delegate (to prevent attaching duplicate delegates for the _same_ ad load
      // event).
      GADMAdapterAppLovinInterstitialLoadDelegate *delegate =
          ALInterstitialLoadDelegates[self.zoneIdentifier];
      if (!delegate) {
        delegate = [[GADMAdapterAppLovinInterstitialLoadDelegate alloc]
            initWithZoneIdentifier:self.zoneIdentifier];
        ALInterstitialLoadDelegates[self.zoneIdentifier] = delegate;
      }

      // Add adapter to pending load delegate for zone as well.
      GADMAdapterAppLovinQueue *pendingLoadDelegates =
          ALInterstitialPendingLoadDelegates[self.zoneIdentifier];
      if (!pendingLoadDelegates) {
        pendingLoadDelegates = [GADMAdapterAppLovinQueue queue];
        ALInterstitialPendingLoadDelegates[self.zoneIdentifier] = pendingLoadDelegates;
      }
      [pendingLoadDelegates enqueue:self];

      if (self.zoneIdentifier.length > 0) {
        [self.sdk.adService loadNextAdForZoneIdentifier:self.zoneIdentifier andNotify:delegate];
      } else {
        [self.sdk.adService loadNextAd:[ALAdSize sizeInterstitial] andNotify:delegate];
      }
    } else {
      [GADMAdapterAppLovinUtils log:@"Enqueued interstitial found. Finishing load..."];

      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.connector adapterDidReceiveInterstitial:self];
      }];
    }
  }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  @synchronized(ALInterstitialAdQueueLock) {
    // Update mute state.
    GADMAdapterAppLovinExtras *networkExtras = strongConnector.networkExtras;
    self.sdk.settings.muted = networkExtras.muteAudio;

    ALAd *dequeuedAd = [ALInterstitialAdQueues[self.zoneIdentifier] dequeue];
    if (dequeuedAd) {
      [GADMAdapterAppLovinUtils log:@"Showing interstitial ad: %@ for zone: %@ placement: %@",
                                    dequeuedAd.adIdNumber, self.zoneIdentifier, self.placement];
      [self.interstitial showOver:[UIApplication sharedApplication].keyWindow
                        placement:self.placement
                        andRender:dequeuedAd];
    } else {
      [GADMAdapterAppLovinUtils log:@"Attempting to show interstitial before one was loaded"];

      // Check if we have a default zone interstitial available.
      if (self.zoneIdentifier.length == 0 && [self.interstitial isReadyForDisplay]) {
        [GADMAdapterAppLovinUtils log:@"Showing interstitial preloaded by SDK"];
        [self.interstitial showOverPlacement:self.placement];
      }
      // TODO: Show ad for zone identifier if exists.
      else {
        [strongConnector adapterWillPresentInterstitial:self];
        [strongConnector adapterDidDismissInterstitial:self];
      }
    }
  }
}

- (ALInterstitialAd *)interstitial {
  if (!_interstitial) {
    _interstitial = [[ALInterstitialAd alloc] initWithSdk:self.sdk];

    GADMAdapterAppLovinInterstitialDelegate *delegate =
        [[GADMAdapterAppLovinInterstitialDelegate alloc] initWithParentAdapter:self];
    _interstitial.adDisplayDelegate = delegate;
    _interstitial.adVideoPlaybackDelegate = delegate;
  }

  return _interstitial;
}

#pragma mark - GAD Ad Network Protocol Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
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

@end

@implementation GADMAdapterAppLovinInterstitialLoadDelegate

#pragma mark - Initialization

- (instancetype)initWithZoneIdentifier:(NSString *)zoneIdentifier {
  self = [super init];
  if (self) {
    self.zoneIdentifier = zoneIdentifier;
  }
  return self;
}

#pragma mark - Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
  [GADMAdapterAppLovinUtils
      log:@"Interstitial did load ad: %@ for zone: %@", ad.adIdNumber, self.zoneIdentifier];

  @synchronized(ALInterstitialAdQueueLock) {
    GADMAdapterAppLovinQueue<ALAd *> *preloadedAds = ALInterstitialAdQueues[self.zoneIdentifier];
    if (!preloadedAds) {
      preloadedAds = [GADMAdapterAppLovinQueue queueWithCapacity:1];
      ALInterstitialAdQueues[self.zoneIdentifier] = preloadedAds;
    }

    [preloadedAds enqueue:ad];
  }

  // Notify pending adapters/connectors of success.
  GADMAdapterAppLovinQueue<GADMAdapterAppLovin *> *pendingLoadDelegates =
      ALInterstitialPendingLoadDelegates[self.zoneIdentifier];
  while (![pendingLoadDelegates isEmpty]) {
    GADMAdapterAppLovin *delegate = [pendingLoadDelegates dequeue];
    [delegate.connector adapterDidReceiveInterstitial:delegate];
  }
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

  // Notify pending adapters/connectors of failure.
  GADMAdapterAppLovinQueue<GADMAdapterAppLovin *> *pendingLoadDelegates =
      ALInterstitialPendingLoadDelegates[self.zoneIdentifier];
  while (![pendingLoadDelegates isEmpty]) {
    GADMAdapterAppLovin *delegate = [pendingLoadDelegates dequeue];
    [delegate.connector adapter:delegate didFailAd:error];
  }
}

@end

@implementation GADMAdapterAppLovinInterstitialDelegate

#pragma mark - Initialization

- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter {
  self = [super init];
  if (self) {
    self.parentAdapter = parentAdapter;
  }
  return self;
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial displayed"];
  [self.parentAdapter.connector adapterWillPresentInterstitial:self.parentAdapter];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial dismissed"];
  [self.parentAdapter.connector adapterWillDismissInterstitial:self.parentAdapter];
  [self.parentAdapter.connector adapterDidDismissInterstitial:self.parentAdapter];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];
  [self.parentAdapter.connector adapterDidGetAdClick:self.parentAdapter];
  [self.parentAdapter.connector adapterWillLeaveApplication:self.parentAdapter];
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

  [self.parentAdapter.adView render:ad overPlacement:self.parentAdapter.placement];
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

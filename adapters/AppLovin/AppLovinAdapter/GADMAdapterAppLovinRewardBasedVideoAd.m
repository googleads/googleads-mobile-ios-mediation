//
//  GADMAdapterAppLovinRewardBasedVideoAd.m
//
//
//  Created by Thomas So on 5/20/17.
//
//

#import "GADMAdapterAppLovinRewardBasedVideoAd.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinExtras.h"
#import <AppLovinSDK/AppLovinSDK.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#define DEFAULT_ZONE @""

@interface GADMAdapterAppLovinRewardBasedVideoAd () <ALAdLoadDelegate, ALAdDisplayDelegate,
                                                     ALAdVideoPlaybackDelegate, ALAdRewardDelegate>

@property(nonatomic, strong) ALSdk *sdk;
@property(nonatomic, strong) ALIncentivizedInterstitialAd *incent;

@property(nonatomic, assign) BOOL fullyWatched;
@property(nonatomic, strong, nullable) GADAdReward *reward;

@property(nonatomic, weak) id<GADMRewardBasedVideoAdNetworkConnector> connector;

/// Controller properties - The connector/credentials referencing these properties may get
/// deallocated.
@property(nonatomic, copy) NSString *
    placement;  // Placements are left in this adapter for backwards-compatibility purposes.
@property(nonatomic, copy) NSString *zoneIdentifier;

@end

@implementation GADMAdapterAppLovinRewardBasedVideoAd

/// A dictionary of Zone -> `ALIncentivizedInterstitialAd` to be shared by instances of the custom
/// event.
/// This prevents skipping of ads as this adapter will be re-created and preloaded (along with
/// underlying `ALIncentivizedInterstitialAd`)
/// on every ad load regardless if ad was actually displayed or not.
static NSMutableDictionary<NSString *, ALIncentivizedInterstitialAd *> *
    ALGlobalIncentivizedInterstitialAds;
static NSObject *ALGlobalIncentivizedInterstitialAdsLock;

#pragma mark - Class Initialization

+ (void)initialize {
  [super initialize];

  ALGlobalIncentivizedInterstitialAds = [NSMutableDictionary dictionary];
  ALGlobalIncentivizedInterstitialAdsLock = [[NSObject alloc] init];
}

#pragma mark - GADMRewardBasedVideoAdNetworkAdapter Methods

+ (NSString *)adapterVersion {
  return GADMAdapterAppLovinConstant.adapterVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAppLovinExtras class];
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
        (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    self.connector = connector;
  }
  return self;
}

- (void)setUp {
  [self log:@"Attempting to initialize SDK"];

  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.connector;

  self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:strongConnector.credentials];

  if (self.sdk) {
    [self log:@"Successfully initialized SDK"];
    [strongConnector adapterDidSetUpRewardBasedVideoAd:self];
  } else {
    [self log:@"Failed to initialize SDK"];
    NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                         code:kGADErrorMediationAdapterError
                                     userInfo:@{
                                       NSLocalizedFailureReasonErrorKey :
                                           @"Failed to initialize AppLovin rewarded video adapter"
                                     }];
    [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
  }
}

- (void)requestRewardBasedVideoAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.connector;
  @synchronized(ALGlobalIncentivizedInterstitialAdsLock) {
    self.placement = [GADMAdapterAppLovinUtils retrievePlacementFromConnector:strongConnector];
    self.zoneIdentifier =
        [GADMAdapterAppLovinUtils retrieveZoneIdentifierFromConnector:strongConnector];

    [self log:@"Requesting interstitial for zone: %@ and placement: %@", self.zoneIdentifier,
              self.placement];

    // Check if incentivized ad for zone already exists.
    if (ALGlobalIncentivizedInterstitialAds[self.zoneIdentifier]) {
      self.incent = ALGlobalIncentivizedInterstitialAds[self.zoneIdentifier];
    } else {
      // If this is a default Zone, create the incentivized ad normally.
      if ([DEFAULT_ZONE isEqualToString:self.zoneIdentifier]) {
        self.incent = [[ALIncentivizedInterstitialAd alloc] initWithSdk:self.sdk];
      }
      // Otherwise, use the Zones API.
      else {
        self.incent = [GADMAdapterAppLovinUtils
            incentivizedInterstitialAdWithZoneIdentifier:self.zoneIdentifier
                                                     sdk:self.sdk];
      }

      ALGlobalIncentivizedInterstitialAds[self.zoneIdentifier] = self.incent;
    }
  }

  self.incent.adVideoPlaybackDelegate = self;
  self.incent.adDisplayDelegate = self;

  if ([self.incent isReadyForDisplay]) {
    [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
  } else {
    [self.incent preloadAndNotify:self];
  }
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.connector;
  if ([self.incent isReadyForDisplay]) {
    // Reset reward states.
    self.reward = nil;
    self.fullyWatched = NO;

    // Update mute state.
    GADMAdapterAppLovinExtras *networkExtras = strongConnector.networkExtras;
    self.sdk.settings.muted = networkExtras.muteAudio;

    [self log:@"Showing rewarded video for zone: %@ placement: %@", self.zoneIdentifier,
              self.placement];
    [self.incent showOver:[UIApplication sharedApplication].keyWindow
                placement:self.placement
                andNotify:self];
  } else {
    [self log:@"Attempting to show rewarded video before one was loaded"];

    // TODO: Add support for checking default SDK-preloaded ad.
    [strongConnector adapterDidOpenRewardBasedVideoAd:self];
    [strongConnector adapterDidCloseRewardBasedVideoAd:self];
  }
}

- (void)stopBeingDelegate {
  self.connector = nil;

  self.incent.adVideoPlaybackDelegate = nil;
  self.incent.adDisplayDelegate = nil;
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
  [self log:@"Rewarded video did load ad: %@ for zoneIdentifier: %@ and placement: %@",
            ad.adIdNumber, self.zoneIdentifier, self.placement];
  [self.connector adapterDidReceiveRewardBasedVideoAd:self];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [self log:@"Rewarded video failed to load with error: %d", code];

  NSError *error =
      [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                          code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                      userInfo:@{
                        NSLocalizedFailureReasonErrorKey : @"Unable to load rewarded video"
                      }];
  [self.connector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
  [self log:@"Rewarded video displayed"];
  [self.connector adapterDidOpenRewardBasedVideoAd:self];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.connector;
  [self log:@"Rewarded video dismissed"];

  if (self.fullyWatched && self.reward) {
    [strongConnector adapter:self didRewardUserWithReward:self.reward];
  }

  [strongConnector adapterDidCloseRewardBasedVideoAd:self];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
  [self log:@"Rewarded video clicked"];
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.connector;

  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillLeaveApplication:self];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad {
  [self log:@"Rewarded video playback began"];
  [self.connector adapterDidStartPlayingRewardBasedVideoAd:self];
}

- (void)videoPlaybackEndedInAd:(ALAd *)ad
             atPlaybackPercent:(NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
  [self log:@"Rewarded video playback ended at playback percent: %lu%%",
            percentPlayed.unsignedIntegerValue];

  self.fullyWatched = wasFullyWatched;

  if(self.fullyWatched) {
    [self.connector adapterDidCompletePlayingRewardBasedVideoAd:self];
  }
}

#pragma mark - Reward Delegate

- (void)rewardValidationRequestForAd:(ALAd *)ad
          didExceedQuotaWithResponse:(NSDictionary *)response {
  [self
      log:@"Rewarded video validation request for ad did exceed quota with response: %@", response];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad didFailWithError:(NSInteger)responseCode {
  [self log:@"Rewarded video validation request for ad failed with error code: %ld", responseCode];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad wasRejectedWithResponse:(NSDictionary *)response {
  [self log:@"Rewarded video validation request was rejected with response: %@", response];
}

- (void)userDeclinedToViewAd:(ALAd *)ad {
  [self log:@"User declined to view rewarded video"];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad didSucceedWithResponse:(NSDictionary *)response {
  NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:response[@"amount"]];
  NSString *currency = response[@"currency"];

  [self log:@"Rewarded %@ %@", amount, currency];

  self.reward = [[GADAdReward alloc] initWithRewardType:currency rewardAmount:amount];
}

#pragma mark - Logging

- (void)log:(NSString *)format, ... {
  if (GADMAdapterAppLovinConstant.loggingEnabled) {
    va_list valist;
    va_start(valist, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:valist];
    va_end(valist);

    NSLog(@"AppLovinRewardedAdapter: %@", message);
  }
}

@end

#pragma clang diagnostic pop

//
//  GADMRTBAdapterAppLovinRewardedRenderer.m
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMAdapterAppLovinRewardedRenderer.h"
#import <AppLovinSDK/AppLovinSDK.h>
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinUtils.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#define DEFAULT_ZONE @""

@interface GADMAdapterAppLovinRewardedRenderer () <ALAdLoadDelegate,
                                                   ALAdDisplayDelegate,
                                                   ALAdVideoPlaybackDelegate,
                                                   ALAdRewardDelegate>

/// Data used to render an RTB rewarded ad.
@property(nonatomic, strong) GADMediationRewardedAdConfiguration *adConfiguration;

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, copy) GADRewardedLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of rewarded presentation events.
@property(nonatomic, weak, nullable) id<GADMediationRewardedAdEventDelegate> delegate;

@property(nonatomic, strong) ALSdk *sdk;
@property(nonatomic, strong) ALIncentivizedInterstitialAd *incent;
@property(nonatomic, strong) ALAd *ad;
@property(nonatomic) BOOL isRTBAdRequested;

@property(nonatomic, assign) BOOL fullyWatched;
@property(nonatomic, strong, nullable) GADAdReward *reward;

/// Controller properties - The connector/credentials referencing these properties may get
/// deallocated.
@property(nonatomic, copy) NSString *placement;
// Placements are left in this adapter for backwards-compatibility purposes.
@property(nonatomic, copy) NSString *zoneIdentifier;

@end

@implementation GADMAdapterAppLovinRewardedRenderer

/// A dictionary of Zone -> `ALIncentivizedInterstitialAd` to be shared by instances of the adapter.
/// This prevents skipping of ads as this adapter will be re-created and preloaded (along with
/// underlying `ALIncentivizedInterstitialAd`)
/// on every ad load regardless if ad was actually displayed or not.
static NSMutableDictionary<NSString *, ALIncentivizedInterstitialAd *>
    *ALGlobalIncentivizedInterstitialAds;
static NSObject *ALGlobalIncentivizedInterstitialAdsLock;

#pragma mark - Class Initialization

+ (void)initialize {
  [super initialize];

  ALGlobalIncentivizedInterstitialAds = [NSMutableDictionary dictionary];
  ALGlobalIncentivizedInterstitialAdsLock = [[NSObject alloc] init];
}

- (instancetype)initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                      completionHandler:(GADRewardedLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    self.adConfiguration = adConfiguration;
    self.adLoadCompletionHandler = handler;
    self.sdk = [GADMAdapterAppLovinUtils
        retrieveSDKFromCredentials:self.adConfiguration.credentials.settings];
    if (!self.sdk) {
      [self log:@"Failed to retrieve SDK instance"];
      NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                           code:kGADErrorMediationAdapterError
                                       userInfo:@{
                                         NSLocalizedFailureReasonErrorKey :
                                             @"Failed to retrieve AppLovin rewarded video adapter"
                                       }];
      self.adLoadCompletionHandler(nil, error);
    }
  }
  return self;
}

- (void)requestRTBRewardedAd {
  // Create rewarded video object
  self.incent = [[ALIncentivizedInterstitialAd alloc] initWithSdk:self.sdk];
  self.isRTBAdRequested = YES;

  self.incent.adDisplayDelegate = self;
  self.incent.adVideoPlaybackDelegate = self;

  // Load ad
  [self.sdk.adService loadNextAdForAdToken:self.adConfiguration.bidResponse andNotify:self];
}

- (void)requestRewardedAd {
  self.isRTBAdRequested = NO;
  @synchronized(ALGlobalIncentivizedInterstitialAdsLock) {
    self.placement =
        [GADMAdapterAppLovinUtils retrievePlacementFromAdConfiguration:self.adConfiguration];
    self.zoneIdentifier =
        [GADMAdapterAppLovinUtils retrieveZoneIdentifierFromAdConfiguration:self.adConfiguration];

    [self log:@"Requesting interstitial for zone: %@ and placement: %@", self.zoneIdentifier,
              self.placement];

    // Check if incentivized ad for zone already exists.
    if (ALGlobalIncentivizedInterstitialAds[self.zoneIdentifier]) {
      NSString *failureReason = @"Can't load an ad with same Zone ID without showing the first";
      NSError *error =
          [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                              code:0
                          userInfo:@{NSLocalizedFailureReasonErrorKey : failureReason}];
      self.adLoadCompletionHandler(nil, error);
    } else {
      // If this is a default Zone, create the incentivized ad normally.
      if ([DEFAULT_ZONE isEqualToString:self.zoneIdentifier]) {
        self.incent = [[ALIncentivizedInterstitialAd alloc] initWithSdk:self.sdk];
      }
      // Otherwise, use the Zones API.
      else {
        self.incent =
            [[ALIncentivizedInterstitialAd alloc] initWithZoneIdentifier:self.zoneIdentifier
                                                                     sdk:self.sdk];
      }
      self.incent.adVideoPlaybackDelegate = self;
      self.incent.adDisplayDelegate = self;
      [self.incent preloadAndNotify:self];
      ALGlobalIncentivizedInterstitialAds[self.zoneIdentifier] = self.incent;
    }
  }
}

- (void)presentFromViewController:(UIViewController *)viewController {
  // Update mute state.
  GADMAdapterAppLovinExtras *networkExtras = self.adConfiguration.extras;
  self.sdk.settings.muted = networkExtras.muteAudio;

  // Reset reward states.
  self.reward = nil;
  self.fullyWatched = NO;

  if (self.isRTBAdRequested) {
    [self.incent showOver:[UIApplication sharedApplication].keyWindow
                 renderAd:self.ad
                andNotify:self];
  } else {
    if ([self.incent isReadyForDisplay]) {
      [self log:@"Showing rewarded video for zone: %@ placement: %@", self.zoneIdentifier,
                self.placement];
      [self.incent showOver:[UIApplication sharedApplication].keyWindow
                  placement:self.placement
                  andNotify:self];
    } else {
      [self log:@"Attempting to show rewarded video before one was loaded"];

      // TODO: Add support for checking default SDK-preloaded ad.

      NSError *error =
          [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                              code:0
                          userInfo:@{
                            NSLocalizedFailureReasonErrorKey : @"Unable to Present rewarded video"
                          }];
      [self.delegate didFailToPresentWithError:error];
    }
  }
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
  [self log:@"Rewarded video did load ad: %@", ad.adIdNumber];

  if (self.isRTBAdRequested) {
    self.ad = ad;
  }
  self.delegate = self.adLoadCompletionHandler(self, nil);
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [self log:@"Rewarded video failed to load with error: %d", code];
  if (!self.isRTBAdRequested) {
    [ALGlobalIncentivizedInterstitialAds removeObjectForKey:self.zoneIdentifier];
  }

  NSError *error = [NSError
      errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                 code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
             userInfo:@{NSLocalizedFailureReasonErrorKey : @"Unable to load rewarded video"}];
  self.adLoadCompletionHandler(nil, error);
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
  [self log:@"Rewarded video displayed"];
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.delegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate reportImpression];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
  [self log:@"Rewarded video dismissed"];
  if (!self.isRTBAdRequested) {
    [ALGlobalIncentivizedInterstitialAds removeObjectForKey:self.zoneIdentifier];
  }
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.delegate;
  if (self.fullyWatched && self.reward) {
    [strongDelegate didRewardUserWithReward:self.reward];
  }

  [strongDelegate didDismissFullScreenView];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
  [self log:@"Rewarded video clicked"];
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.delegate;
  [strongDelegate reportClick];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad {
  [self log:@"Rewarded video playback began"];
  [self.delegate didStartVideo];
}

- (void)videoPlaybackEndedInAd:(ALAd *)ad
             atPlaybackPercent:(NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
  [self log:@"Rewarded video playback ended at playback percent: %lu%%",
            percentPlayed.unsignedIntegerValue];

  self.fullyWatched = wasFullyWatched;

  if (self.fullyWatched) {
    [self.delegate didEndVideo];
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

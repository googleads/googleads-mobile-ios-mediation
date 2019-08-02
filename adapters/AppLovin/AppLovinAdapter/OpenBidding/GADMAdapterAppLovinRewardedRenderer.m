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

/// AppLovin Rewarded Delegate. AppLovin rewarded protocols are implemented in a separate class to
/// avoid a retain cycle, as the AppLovin SDK keep a strong reference to its delegate.
@interface GADMAppLovinRewardedDelegate : NSObject <ALAdLoadDelegate,
                                                    ALAdDisplayDelegate,
                                                    ALAdVideoPlaybackDelegate,
                                                    ALAdRewardDelegate>
@property(nonatomic, weak) GADMAdapterAppLovinRewardedRenderer *parentRenderer;
- (instancetype)initWithParentRenderer:(GADMAdapterAppLovinRewardedRenderer *)parentRenderer;
@end

@interface GADMAdapterAppLovinRewardedRenderer ()

/// Data used to render an RTB rewarded ad.
@property(nonatomic, strong) GADMediationRewardedAdConfiguration *adConfiguration;

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of rewarded presentation events.
@property(nonatomic, weak, nullable) id<GADMediationRewardedAdEventDelegate> delegate;

/// Delegate to get notified by the AppLovin SDK of rewarded presentation events.
@property(nonatomic, strong) GADMAppLovinRewardedDelegate *appLovinDelegate;

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

static NSMutableArray *gRequestedRewardedZoneIdentifiers;

+ (void)load {
  gRequestedRewardedZoneIdentifiers = [[NSMutableArray alloc] init];
}

- (instancetype)initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                      completionHandler:(GADMediationRewardedLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    self.adConfiguration = adConfiguration;
    self.adLoadCompletionHandler = handler;
    self.sdk = [GADMAdapterAppLovinUtils
        retrieveSDKFromCredentials:self.adConfiguration.credentials.settings];
    if (!self.sdk) {
      [GADMAdapterAppLovinUtils log:@"Failed to retrieve SDK instance"];
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

  self.appLovinDelegate = [[GADMAppLovinRewardedDelegate alloc] initWithParentRenderer:self];
  self.incent.adDisplayDelegate = self.appLovinDelegate;
  self.incent.adVideoPlaybackDelegate = self.appLovinDelegate;

  // Load ad
  [self.sdk.adService loadNextAdForAdToken:self.adConfiguration.bidResponse
                                 andNotify:self.appLovinDelegate];
}

- (void)requestRewardedAd {
  self.isRTBAdRequested = NO;
  self.placement =
      [GADMAdapterAppLovinUtils retrievePlacementFromAdConfiguration:self.adConfiguration];
  self.zoneIdentifier =
      [GADMAdapterAppLovinUtils retrieveZoneIdentifierFromAdConfiguration:self.adConfiguration];

  [GADMAdapterAppLovinUtils log:@"Requesting interstitial for zone: %@ and placement: %@",
                                self.zoneIdentifier, self.placement];

  // Check if incentivized ad for zone already exists.
  NSArray *requestedZones;
  @synchronized(gRequestedRewardedZoneIdentifiers) {
    requestedZones = [NSArray arrayWithArray:gRequestedRewardedZoneIdentifiers];
  }

  if ([requestedZones containsObject:self.zoneIdentifier]) {
    NSString *failureReason = @"Can't load an ad with same Zone ID without showing the first";
    NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
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
      self.incent = [[ALIncentivizedInterstitialAd alloc] initWithZoneIdentifier:self.zoneIdentifier
                                                                             sdk:self.sdk];
    }
    self.appLovinDelegate = [[GADMAppLovinRewardedDelegate alloc] initWithParentRenderer:self];
    self.incent.adVideoPlaybackDelegate = self.appLovinDelegate;
    self.incent.adDisplayDelegate = self.appLovinDelegate;
    [self.incent preloadAndNotify:self.appLovinDelegate];
    @synchronized(gRequestedRewardedZoneIdentifiers) {
      [gRequestedRewardedZoneIdentifiers addObject:self.zoneIdentifier];
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

  if ([self.incent isReadyForDisplay]) {
    [GADMAdapterAppLovinUtils log:@"Showing rewarded video for zone: %@ placement: %@",
                                  self.zoneIdentifier, self.placement];
    [self.incent showAd:self.ad andNotify:self.appLovinDelegate];
  } else {
    [GADMAdapterAppLovinUtils log:@"Attempting to show rewarded video before one was loaded"];
    NSError *error = [NSError
        errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                   code:0
               userInfo:@{NSLocalizedFailureReasonErrorKey : @"Unable to Present rewarded video"}];
    [self.delegate didFailToPresentWithError:error];
  }
}

- (void)dealloc {
  self.appLovinDelegate = nil;
  self.incent.adVideoPlaybackDelegate = nil;
  self.incent.adDisplayDelegate = nil;
}

@end

@implementation GADMAppLovinRewardedDelegate

#pragma mark - Initialization

- (instancetype)initWithParentRenderer:(GADMAdapterAppLovinRewardedRenderer *)parentRenderer {
  self = [super init];
  if (self) {
    self.parentRenderer = parentRenderer;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad did load ad: %@", ad.adIdNumber];

  GADMAdapterAppLovinRewardedRenderer *parentRenderer = self.parentRenderer;
  parentRenderer.ad = ad;
  dispatch_async(dispatch_get_main_queue(), ^{
    if (parentRenderer.adLoadCompletionHandler) {
      parentRenderer.delegate = parentRenderer.adLoadCompletionHandler(parentRenderer, nil);
    }
  });
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad failed to load with error: %d", code];
  GADMAdapterAppLovinRewardedRenderer *parentRenderer = self.parentRenderer;
  NSString *errorDomain;
  if (parentRenderer.isRTBAdRequested) {
    errorDomain = GADMAdapterAppLovinConstant.rtbErrorDomain;
  } else {
    errorDomain = GADMAdapterAppLovinConstant.errorDomain;
    @synchronized(gRequestedRewardedZoneIdentifiers) {
      [gRequestedRewardedZoneIdentifiers removeObject:parentRenderer.zoneIdentifier];
    }
  }

  NSError *error = [NSError errorWithDomain:errorDomain
                                       code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                                   userInfo:nil];

  if (parentRenderer.adLoadCompletionHandler) {
    parentRenderer.adLoadCompletionHandler(nil, error);
  }
}

#pragma mark - Ad Display Delegate

- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad clicked"];
  [self.parentRenderer.delegate reportClick];
}

- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad displayed"];

  id<GADMediationRewardedAdEventDelegate> delegate = self.parentRenderer.delegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad dismissed"];
  GADMAdapterAppLovinRewardedRenderer *parentRenderer = self.parentRenderer;
  if (!parentRenderer.isRTBAdRequested) {
    @synchronized(gRequestedRewardedZoneIdentifiers) {
      [gRequestedRewardedZoneIdentifiers removeObject:_parentRenderer.zoneIdentifier];
    }
  }
  id<GADMediationRewardedAdEventDelegate> delegate = parentRenderer.delegate;
  if (parentRenderer.fullyWatched && parentRenderer.reward) {
    [delegate didRewardUserWithReward:parentRenderer.reward];
  }

  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(nonnull ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad playback began"];
  [self.parentRenderer.delegate didStartVideo];
}

- (void)videoPlaybackEndedInAd:(nonnull ALAd *)ad
             atPlaybackPercent:(nonnull NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad playback ended at playback percent: %lu%%",
                                percentPlayed.unsignedIntegerValue];

  GADMAdapterAppLovinRewardedRenderer *parentRenderer = self.parentRenderer;
  parentRenderer.fullyWatched = wasFullyWatched;

  if (parentRenderer.fullyWatched) {
    [parentRenderer.delegate didEndVideo];
  }
}

#pragma mark - Reward Delegate

- (void)rewardValidationRequestForAd:(ALAd *)ad
          didExceedQuotaWithResponse:(NSDictionary *)response {
  [GADMAdapterAppLovinUtils
      log:@"Rewarded ad validation request for ad did exceed quota with response: %@", response];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad didFailWithError:(NSInteger)responseCode {
  [GADMAdapterAppLovinUtils
      log:@"Rewarded ad validation request for ad failed with error code: %ld", responseCode];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad wasRejectedWithResponse:(NSDictionary *)response {
  [GADMAdapterAppLovinUtils
      log:@"Rewarded ad validation request was rejected with response: %@", response];
}

- (void)userDeclinedToViewAd:(ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"User declined to view rewarded video"];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad didSucceedWithResponse:(NSDictionary *)response {
  NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:response[@"amount"]];
  NSString *currency = response[@"currency"];

  [GADMAdapterAppLovinUtils log:@"Rewarded %@ %@", amount, currency];

  self.parentRenderer.reward = [[GADAdReward alloc] initWithRewardType:currency
                                                          rewardAmount:amount];
}

@end

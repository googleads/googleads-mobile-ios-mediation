//
//  GADMAdapterMyTargetRewarded.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 29.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

@import MyTargetSDK;

#import "GADMAdapterMyTargetRewarded.h"
#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetUtils.h"
#import "GADMAdapterMyTargetExtras.h"

#define guard(CONDITION) \
  if (CONDITION) {       \
  }

@interface GADMAdapterMyTargetRewarded () <MTRGInterstitialAdDelegate>

@end

@implementation GADMAdapterMyTargetRewarded {
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _connector;
  MTRGInterstitialAd *_interstitialAd;
  BOOL _isInterstitialAllowed;
  BOOL _isInterstitialStarted;
}

+ (NSString *)adapterVersion {
  return kGADMAdapterMyTargetVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterMyTargetExtras class];
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
        (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    id<GADAdNetworkExtras> networkExtras = connector.networkExtras;
    if (networkExtras && [networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]]) {
      GADMAdapterMyTargetExtras *extras = (GADMAdapterMyTargetExtras *)networkExtras;
      [GADMAdapterMyTargetUtils setLogEnabled:extras.isDebugMode];
    }

    MTRGLogInfo();
    MTRGLogDebug(@"Credentials: %@", connector.credentials);
    _connector = connector;
    _isInterstitialAllowed = NO;
    _isInterstitialStarted = NO;
  }
  return self;
}

- (void)setUp {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;

  NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:strongConnector.credentials];
  guard(slotId > 0) else {
    MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
    [strongConnector adapter:self
        didFailToSetUpRewardBasedVideoAdWithError:
            [GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId]];
    return;
  }

  _isInterstitialAllowed = NO;
  _interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:slotId];
  _interstitialAd.delegate = self;
  [GADMAdapterMyTargetUtils fillCustomParams:_interstitialAd.customParams
                               withConnector:strongConnector];
  [_interstitialAd.customParams setCustomParam:kMTRGCustomParamsMediationAdmob
                                        forKey:kMTRGCustomParamsMediationKey];
  [strongConnector adapterDidSetUpRewardBasedVideoAd:self];
}

- (void)requestRewardBasedVideoAd {
  MTRGLogInfo();
  [_interstitialAd load];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  MTRGLogInfo();
  guard(_isInterstitialAllowed && _interstitialAd) else return;
  [_interstitialAd showWithController:viewController];
  _isInterstitialStarted = YES;
}

- (void)stopBeingDelegate {
  MTRGLogInfo();
  _connector = nil;
  if (_interstitialAd) {
    _interstitialAd.delegate = nil;
    _interstitialAd = nil;
  }
}

#pragma mark - MTRGInterstitialAdDelegate

- (void)onLoadWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
  _isInterstitialAllowed = YES;
  [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
}

- (void)onNoAdWithReason:(NSString *)reason interstitialAd:(MTRGInterstitialAd *)interstitialAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  NSString *description = [GADMAdapterMyTargetUtils noAdWithReason:reason];
  MTRGLogError(description);
  guard(strongConnector) else return;
  NSError *error = [GADMAdapterMyTargetUtils errorWithDescription:description];
  [strongConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
}

- (void)onClickWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
  [strongConnector adapterDidGetAdClick:self];
}

- (void)onCloseWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
  [strongConnector adapterDidCloseRewardBasedVideoAd:self];
}

- (void)onVideoCompleteWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterDidCompletePlayingRewardBasedVideoAd:self];
  MTRGLogInfo();
  guard(strongConnector) else return;
  NSString *rewardType = @"";                            // must not be nil
  NSDecimalNumber *rewardAmount = [NSDecimalNumber one];  // must not be nil
  GADAdReward *adReward =
      [[GADAdReward alloc] initWithRewardType:rewardType rewardAmount:rewardAmount];
  [strongConnector adapter:self didRewardUserWithReward:adReward];
}

- (void)onDisplayWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
  [strongConnector adapterDidOpenRewardBasedVideoAd:self];
  [strongConnector adapterDidStartPlayingRewardBasedVideoAd:self];
}

- (void)onLeaveApplicationWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
  [strongConnector adapterWillLeaveApplication:self];
}

@end

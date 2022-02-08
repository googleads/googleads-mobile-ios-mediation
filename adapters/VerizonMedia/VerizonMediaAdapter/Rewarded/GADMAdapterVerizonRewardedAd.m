//
//  GADMAdapterVerizonRewardedAd.m
//
// @copyright Copyright (c) 2019 Verizon. All rights reserved.
//

#import "GADMAdapterVerizonRewardedAd.h"

#import <VerizonAdsInterstitialPlacement/VerizonAdsInterstitialPlacement.h>

#include <stdatomic.h>
#import "GADMAdapterVerizonConstants.h"
#import "GADMAdapterVerizonUtils.h"
#import "GADMVerizonPrivacy_Internal.h"

NSString *const GADMAdapterVerizonVideoCompleteEventId = @"onVideoComplete";

@interface GADMAdapterVerizonRewardedAd () <VASInterstitialAdDelegate,
                                            VASInterstitialAdFactoryDelegate>
@end

@implementation GADMAdapterVerizonRewardedAd {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _rewardedCompletionHandler;

  /// Verizon media rewarded ad.
  VASInterstitialAd *_rewardedAd;

  /// Placement ID string used to request ads from Verizon Ads SDK.
  NSString *_placementID;

  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// Ad Configuration for the ad to be rendered.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// Handles loading and caching of Verizon media rewarded ads.
  VASInterstitialAdFactory *_rewardedAdFactory;

  BOOL _isVideoCompletionEventCalled;
}

- (void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)handler {
  // Store the ad config and completion handler for later use.
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler = [handler copy];
  _rewardedCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
      _Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationRewardedAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(ad, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };
  _adConfiguration = adConfig;

  NSDictionary<NSString *, id> *credentials = adConfig.credentials.settings;
  NSString *siteID = credentials[GADMAdapterVerizonMediaDCN];
  BOOL isInitialized = GADMAdapterVerizonInitializeVASAdsWithSiteID(siteID);
  if (!isInitialized) {
    NSError *error = GADMAdapterVerizonErrorWithCodeAndDescription(
        GADMAdapterVerizonErrorInitialization, @"Verizon SDK failed to initialize.");
    handler(nil, error);
    return;
  }

  _placementID = credentials[GADMAdapterVerizonMediaPosition];

  if (!_placementID) {
    NSError *error = GADMAdapterVerizonErrorWithCodeAndDescription(
        GADMAdapterVerizonErrorInvalidServerParameters, @"Placement ID cannot be nil");
    handler(nil, error);
    return;
  }

  [self setRequestInfoFromAdConfiguration];
  _rewardedCompletionHandler = handler;
  _rewardedAd = nil;
  _rewardedAdFactory = [[VASInterstitialAdFactory alloc] initWithPlacementId:_placementID
                                                                      vasAds:VASAds.sharedInstance
                                                                    delegate:self];
  [_rewardedAdFactory load:self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedAd showFromViewController:viewController];
}

- (void)setRequestInfoFromAdConfiguration {
  // User Settings.
  [self setUserSettingsFromAdConfiguration];

  // COPPA.
  [self setCoppaFromAdConfiguration];

  // Location.
  if (_adConfiguration.hasUserLocation) {
    VASAds.sharedInstance.locationEnabled = YES;
  }
}

- (void)setUserSettingsFromAdConfiguration {
  VASRequestMetadataBuilder *builder = [[VASRequestMetadataBuilder alloc] init];

  // Mediator.
  builder.mediator = [NSString stringWithFormat:@"AdMobVAS-%@", GADMAdapterVerizonMediaVersion];

  VASAds.sharedInstance.requestMetadata = [builder build];
}

- (void)setCoppaFromAdConfiguration {
  VASDataPrivacyBuilder *builder = [[VASDataPrivacyBuilder alloc] initWithDataPrivacy:VASAds.sharedInstance.dataPrivacy];
  builder.coppa.applies = [_adConfiguration.childDirectedTreatment boolValue];
  VASAds.sharedInstance.dataPrivacy = [builder build];
}

- (void)dealloc {
  if ([_rewardedAd respondsToSelector:@selector(destroy)]) {
    [_rewardedAd performSelector:@selector(destroy)];
  }

  _rewardedAdFactory.delegate = nil;
  _rewardedAd.delegate = nil;
  _rewardedAd = nil;
}

#pragma mark - VASInterstitialAdFactoryDelegate

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
        didLoadInterstitialAd:(nonnull VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_rewardedAd = interstitialAd;
    self->_adEventDelegate = self->_rewardedCompletionHandler(self, nil);
  });
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
             didFailWithError:(nonnull VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_rewardedCompletionHandler(nil, errorInfo);
  });
}

#pragma mark - VASInterstitialAdDelegate

- (void)interstitialAdDidShow:(nonnull VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_adEventDelegate willPresentFullScreenView];
  });
}

- (void)interstitialAdDidFail:(nonnull VASInterstitialAd *)interstitialAd
                    withError:(nonnull VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_adEventDelegate didFailToPresentWithError:errorInfo];
  });
}

- (void)interstitialAdDidClose:(nonnull VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    id<GADMediationRewardedAdEventDelegate> strongDelegate = self->_adEventDelegate;
    [strongDelegate willDismissFullScreenView];
    [strongDelegate didDismissFullScreenView];
  });
}

- (void)interstitialAdDidLeaveApplication:(nonnull VASInterstitialAd *)interstitialAd {
  // Do nothing.
}

- (void)interstitialAdClicked:(nonnull VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_adEventDelegate reportClick];
  });
}

- (void)interstitialAdEvent:(nonnull VASInterstitialAd *)interstitialAd
                     source:(nonnull NSString *)source
                    eventId:(nonnull NSString *)eventId
                  arguments:(nullable NSDictionary<NSString *, id> *)arguments {
  if ([eventId isEqualToString:GADMAdapterVerizonVideoCompleteEventId] &&
      !_isVideoCompletionEventCalled) {
    dispatch_async(dispatch_get_main_queue(), ^{
      GADAdReward *reward =
          [[GADAdReward alloc] initWithRewardType:@""
                                     rewardAmount:[[NSDecimalNumber alloc] initWithInteger:1]];
      [self->_adEventDelegate didRewardUserWithReward:reward];
      self->_isVideoCompletionEventCalled = YES;
    });
  }
}

@end

//
//  GADMAdapterVerizonRewardedAd.m
//
// @copyright Copyright (c) 2019 Verizon. All rights reserved.
//

#import "GADMAdapterVerizonRewardedAd.h"

#import <VerizonAdsStandardEdition/VerizonAdsStandardEdition.h>
#import <VerizonAdsInterstitialPlacement/VerizonAdsInterstitialPlacement.h>

#import "GADMAdapterVerizonConstants.h"
#import "GADMVerizonConsent_Internal.h"

NSString * const GADMAdapterVerizonVideoCompleteEventId = @"onVideoComplete";

@interface GADMAdapterVerizonRewardedAd () <VASInterstitialAdDelegate,
                                            VASInterstitialAdFactoryDelegate>
@end

@implementation GADMAdapterVerizonRewardedAd {
  /// Verizon media rewarded ad.
  VASInterstitialAd *_rewardedAd;

  /// A shared instance of the Verizon media core SDK.
  VASAds *_vasAds;

  /// Placement ID string used to request ads from Verizon Ads SDK.
  NSString *_placementID;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _rewardedCompletionHandler;

  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// Ad Configuration for the ad to be rendered.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// Handles loading and caching of Verizon media rewarded ads.
  VASInterstitialAdFactory *_rewardedAdFactory;

  BOOL _isVideoCompletionEventCalled;
}

- (void)initializeVASSDK {
  NSDictionary *settings = _adConfiguration.credentials.settings;
  if(settings[kGADMAdapterVerizonMediaPosition]) {
    _placementID = settings[kGADMAdapterVerizonMediaPosition];
  }

  NSString *siteId = settings[kGADMAdapterVerizonMediaDCN];
  if (!siteId.length) {
    siteId = [[NSBundle mainBundle] objectForInfoDictionaryKey:kGADMAdapterVerizonMediaSiteID];
  }

  if(UIDevice.currentDevice.systemVersion.floatValue >= 8.0) {
    VASAds.logLevel = VASLogLevelError;
    if(![VASAds.sharedInstance isInitialized]) {
      [VASStandardEdition initializeWithSiteId:siteId];
    }
    _vasAds = [VASAds sharedInstance];
    [GADMVerizonConsent.sharedInstance updateConsentInfo];
  }
}

- (void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                       completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)handler {
  _adConfiguration = adConfig;
  if (!_vasAds) {
    [self initializeVASSDK];
  }

  if (!_placementID || ![_vasAds isInitialized]) {
    NSError *error = [NSError errorWithDomain:kGADErrorDomain
                                         code:kGADErrorMediationAdapterError
                                     userInfo:@{ NSLocalizedDescriptionKey : @"Verizon adapter was not intialized properly."}];
    handler(nil, error);
  }

  [self setRequestInfoFromAdConfiguration];
  _rewardedCompletionHandler = handler;
  _rewardedAd = nil;
  _rewardedAdFactory = [[VASInterstitialAdFactory alloc] initWithPlacementId:_placementID
                                                                      vasAds:_vasAds
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
    _vasAds.locationEnabled = YES;
  }
}

- (void)setUserSettingsFromAdConfiguration {
  VASRequestMetadataBuilder *builder = [[VASRequestMetadataBuilder alloc] init];

  // Mediator.
  builder.appMediator = [NSString stringWithFormat:@"AdMobVAS-%@", kGADMAdapterVerizonMediaVersion];

  _vasAds.requestMetadata = [builder build];
}

- (void)setCoppaFromAdConfiguration {
  _vasAds.COPPA = _adConfiguration.childDirectedTreatment;
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
    self->_rewardedCompletionHandler = nil;
  });
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
             didFailWithError:(nonnull VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_rewardedCompletionHandler(nil, errorInfo);
    self->_rewardedCompletionHandler = nil;
  });
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
      cacheLoadedNumRequested:(NSInteger)numRequested
                  numReceived:(NSInteger)numReceived {
  // Unused.
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
    cacheUpdatedWithCacheSize:(NSInteger)cacheSize {
  // Unused.
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
      cacheLoadedNumRequested:(NSInteger)numRequested {
  // Unused.
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

// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterMyTargetBannerAd.h"

#import <MyTargetSDK/MyTargetSDK.h>

#import <stdatomic.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMAdapterMyTargetBannerAd () <MTRGAdViewDelegate>
@end

@implementation GADMAdapterMyTargetBannerAd {
  /// Completion handler to forward ad load events to the Google Mobile Ads SDK.
  GADMediationBannerLoadCompletionHandler _completionHandler;

  /// Banner ad configuration of the ad request.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// Ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationBannerAdEventDelegate> _adEventDelegate;

  /// myTarget ad view object.
  MTRGAdView *_adView;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];

    _completionHandler = ^id<GADMediationBannerAdEventDelegate>(
        _Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }

      id<GADMediationBannerAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(ad, error);
      }

      originalCompletionHandler = nil;
      return delegate;
    };

    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadBannerAd {
  MTRGLogInfo();
  id<GADAdNetworkExtras> networkExtras = _adConfiguration.extras;
  if (networkExtras && [networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]]) {
    GADMAdapterMyTargetExtras *extras = (GADMAdapterMyTargetExtras *)networkExtras;
    GADMAdapterMyTargetUtils.logEnabled = extras.isDebugMode;
  }

  NSDictionary<NSString *, id> *credentials = _adConfiguration.credentials.settings;
  MTRGLogDebug(@"Credentials: %@", credentials);

  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  if (slotId <= 0) {
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorInvalidServerParameters, @"Slot ID cannot be nil.");
    _completionHandler(nil, error);
    return;
  }

  GADAdSize adSize = _adConfiguration.adSize;
  NSError *error = nil;
  MTRGAdSize *mytargetAdSize = GADMAdapterMyTargetSizeFromRequestedSize(adSize, &error);
  if (error) {
    _completionHandler(nil, error);
    return;
  }
  CGFloat width = mytargetAdSize.size.width;
  CGFloat height = mytargetAdSize.size.height;
  MTRGLogDebug(@"adSize: %.fx%.f", width, height);

  _adView = [MTRGAdView adViewWithSlotId:slotId shouldRefreshAd:NO];
  _adView.adSize = mytargetAdSize;
  _adView.frame = CGRectMake(0, 0, width, height);
  _adView.delegate = self;
  _adView.viewController = _adConfiguration.topViewController;
  GADMAdapterMyTargetFillCustomParams(_adView.customParams, networkExtras);
  [_adView.customParams setCustomParam:kMTRGCustomParamsMediationAdmob
                                forKey:kMTRGCustomParamsMediationKey];
  [_adView load];
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
  return _adView;
}

#pragma mark - MTRGAdViewDelegate

- (void)onLoadWithAdView:(MTRGAdView *)adView;
{
  MTRGLogInfo();
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)onLoadFailedWithError:(NSError *)error adView:(MTRGAdView *)adView {
  MTRGLogInfo();
  MTRGLogError(error.localizedDescription);
  NSError *noFillError = GADMAdapterMyTargetErrorWithCodeAndDescription(
      GADMAdapterMyTargetErrorNoFill, error.localizedDescription);
  _completionHandler(nil, noFillError);
}

- (void)onAdShowWithAdView:(MTRGAdView *)adView {
  MTRGLogInfo();
  [_adEventDelegate reportImpression];
}

- (void)onAdClickWithAdView:(MTRGAdView *)adView {
  MTRGLogInfo();
  [_adEventDelegate reportClick];
}

@end

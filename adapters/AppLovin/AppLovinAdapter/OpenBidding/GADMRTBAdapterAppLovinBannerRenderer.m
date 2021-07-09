//
//  GADMRTBAdapterAppLovinBannerRenderer.m
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMRTBAdapterAppLovinBannerRenderer.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinUtils.h"

#import <AppLovinSDK/AppLovinSDK.h>
#include <stdatomic.h>

#import "GADMAppLovinRTBBannerDelegate.h"

@implementation GADMRTBAdapterAppLovinBannerRenderer {
  /// Data used to render an banner ad.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// Instance of the AppLovin SDK.
  ALSdk *_SDK;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    // Store the completion handler for later use.
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler originalCompletionHandler = [handler copy];
    _adLoadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
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
  }
  return self;
}

- (void)loadAd {
  NSString *SDKKey = [GADMAdapterAppLovinUtils
      retrieveSDKKeyFromCredentials:_adConfiguration.credentials.settings];
  if (!SDKKey) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, @"Invalid server parameters.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _SDK = [GADMAdapterAppLovinUtils retrieveSDKFromSDKKey:SDKKey];
  if (!_SDK) {
    NSError *error = GADMAdapterAppLovinNilSDKError(SDKKey);
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // Convert requested size to AppLovin Ad Size.
  ALAdSize *appLovinAdSize =
      [GADMAdapterAppLovinUtils appLovinAdSizeFromRequestedSize:_adConfiguration.adSize];

  if (!appLovinAdSize) {
    NSString *errorString =
        [NSString stringWithFormat:@"Failed to request banner with unsupported size : %@",
                                   NSStringFromCGSize(_adConfiguration.adSize.size)];
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorBannerSizeMismatch, errorString);
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // Create adview object.
  _adView = [[ALAdView alloc] initWithSdk:_SDK size:appLovinAdSize];

  GADMAppLovinRTBBannerDelegate *delegate =
      [[GADMAppLovinRTBBannerDelegate alloc] initWithParentRenderer:self];
  _adView.adDisplayDelegate = delegate;
  _adView.adEventDelegate = delegate;

  // Load ad.
  [_SDK.adService loadNextAdForAdToken:_adConfiguration.bidResponse andNotify:delegate];
}

#pragma mark - GADMediationBannerAd

- (nonnull UIView *)view {
  return _adView;
}

- (void)dealloc {
  _adView.adDisplayDelegate = nil;
  _adView.adEventDelegate = nil;
}

@end

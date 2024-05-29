// Copyright 2024 Google LLC
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

#import "GADMAdapterNendBannerAd.h"

#import <NendAd/NendAd.h>

#include <stdatomic.h>

#import "GADMAdapterNendConstants.h"
#import "GADMAdapterNendUtils.h"

@interface GADMAdapterNendBannerAd () <NADViewDelegate>
@end

@implementation GADMAdapterNendBannerAd {
  /// The completion handler to call when ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _loadCompletionHandler;

  /// Indicates whether the load completion handler was called or not.
  BOOL _isLoadCompletionHandlerCalled;

  /// Banner ad configuration of the ad request.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationBannerAdEventDelegate> _adEventDelegate;

  /// nend ad view.
  NADView *_nadView;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
      loadCompletionHandler:(nonnull GADMediationBannerLoadCompletionHandler)loadCompletionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _isLoadCompletionHandlerCalled = NO;
    _loadCompletionHandler = [loadCompletionHandler copy];
  }
  return self;
}

- (void)loadBannerAd {
  GADAdSize adSize = GADSupportedAdSizeFromRequestedSize(_adConfiguration.adSize);
  if (GADAdSizeEqualToSize(adSize, GADAdSizeInvalid)) {
    NSString *errorMsg =
        [NSString stringWithFormat:@"Unable to retrieve supported ad size from GADAdSize: %@",
                                   NSStringFromGADAdSize(adSize)];
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        GADMAdapterNendErrorBannerSizeMismatch, errorMsg);
    [self callLoadCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }

  NSString *spotID = _adConfiguration.credentials.settings[GADMAdapterNendSpotID];
  NSString *APIKey = _adConfiguration.credentials.settings[GADMAdapterNendApiKey];

  NSError *serverParameterError = GADMAdapterNendValidateSpotID(spotID);
  if (serverParameterError) {
    [self callLoadCompletionHandlerIfNeededWithAd:nil error:serverParameterError];
    return;
  }

  serverParameterError = GADMAdapterNendValidateAPIKey(APIKey);
  if (serverParameterError) {
    [self callLoadCompletionHandlerIfNeededWithAd:nil error:serverParameterError];
    return;
  }

  _nadView = [[NADView alloc] initWithFrame:CGRectZero];
  [_nadView setNendID:spotID.integerValue apiKey:APIKey];
  _nadView.backgroundColor = UIColor.clearColor;
  _nadView.delegate = self;
  [_nadView load];
}

- (void)callLoadCompletionHandlerIfNeededWithAd:(nullable id<GADMediationBannerAd>)ad
                                          error:(nullable NSError *)error {
  @synchronized(self) {
    if (_isLoadCompletionHandlerCalled) {
      return;
    }
    _isLoadCompletionHandlerCalled = YES;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    if (self->_loadCompletionHandler) {
      self->_adEventDelegate = self->_loadCompletionHandler(ad, error);
    }
    self->_loadCompletionHandler = nil;
  });
}

#pragma mark - GADMediationBannerAd

- (nonnull UIView *)view {
  return _nadView;
}

#pragma mark - NADViewDelegate

- (void)nadViewDidReceiveAd:(nonnull NADView *)adView {
  [self callLoadCompletionHandlerIfNeededWithAd:self error:nil];
}

- (void)nadViewDidFailToReceiveAd:(nonnull NADView *)adView {
  NSLog(@"nend SDK banner did fail to receive ad.");
  NSError *error = GADMAdapterNendSDKLoadError();
  [self callLoadCompletionHandlerIfNeededWithAd:nil error:error];
}

- (void)nadViewDidClickAd:(nonnull NADView *)adView {
  [_adEventDelegate reportClick];
}

@end

// Copyright 2019 Google LLC.
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

#import "InMobiBannerAd.h"
#include <stdatomic.h>
#import "GADMAdapterInMobiUtils.h"

@interface InMobiBannerAd () <GADMediationBannerAd, IMBannerDelegate>

@property(nonatomic, strong) IMBanner *banner;
@property(nonatomic, copy) GADRTBSignalCompletionHandler signalCompletionHandler;
@property(nonatomic, copy) GADMediationBannerLoadCompletionHandler renderCompletionHandler;
@property(nonatomic, weak) id<GADMediationBannerAdEventDelegate> adEventDelegate;

@end

@implementation InMobiBannerAd

- (instancetype)initWithPlacementId:(long long)placementId adSize:(GADAdSize)adSize {
  _banner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, adSize.size.width, adSize.size.height)
                                placementId:placementId];
  [_banner setExtras:@{@"tp" : @"c_admob"}];
  _banner.delegate = self;
  return self;
}

- (void)collectIMSignalsWithGMACompletionHandler:
    (nonnull GADRTBSignalCompletionHandler)completionHandler {
  GADMAdapterInMobiMutableSetSafeGADRTBSignalCompletionHandler(_signalCompletionHandler,
                                                               completionHandler);
  [_banner getSignals];
}

- (void)loadIMBannerResponseWithGMAAdConfig:(GADMediationBannerAdConfiguration *)adConfig
                          completionHandler:(GADMediationBannerLoadCompletionHandler)handler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler = [handler copy];
  _renderCompletionHandler =
      ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> bannerAd, NSError *error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationBannerAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(bannerAd, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };
  [_banner load:[adConfig.bidResponse dataUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark IMBannerDelegate

- (void)banner:(IMBanner *)banner gotSignals:(NSData *)signals {
  NSString *signalsString = [[NSString alloc] initWithData:signals encoding:NSUTF8StringEncoding];
  _signalCompletionHandler(signalsString, nil);
}

- (void)banner:(IMBanner *)banner failedToGetSignalsWithError:(IMRequestStatus *)status {
  _signalCompletionHandler(nil, status);
}

- (void)banner:(IMBanner *)banner didFailToLoadWithError:(IMRequestStatus *)error {
  _renderCompletionHandler(nil, error);
}

- (void)bannerDidFinishLoading:(IMBanner *)banner {
  _adEventDelegate = _renderCompletionHandler(self, nil);
}

- (void)banner:(IMBanner *)banner didInteractWithParams:(NSDictionary *)params {
  [_adEventDelegate reportClick];
}

- (void)bannerWillPresentScreen:(IMBanner *)banner {
  id<GADMediationBannerAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate reportImpression];
}

- (void)bannerWillDismissScreen:(IMBanner *)banner {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)bannerDidDismissScreen:(IMBanner *)banner {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)userWillLeaveApplicationFromBanner:(IMBanner *)banner {
  [_adEventDelegate willBackgroundApplication];
}

#pragma mark InmobiBannerAdView

- (UIView *)view {
  return _banner;
}

@end

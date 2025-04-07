// Copyright 2024 Google Inc.
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

#import "GADMAdapterIronSourceRtbBannerAd.h"
#import <Foundation/Foundation.h>
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceUtils.h"

@interface GADMAdapterIronSourceRtbBannerAd ()

@end

@implementation GADMAdapterIronSourceRtbBannerAd

- (void)loadBannerAdForConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  _bannerAdLoadCompletionHandler = completionHandler;

  NSDictionary *credentials = [adConfiguration.credentials settings];

  if (credentials[GADMAdapterIronSourceInstanceId]) {
    self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
  } else {
    [GADMAdapterIronSourceUtils onLog:@"Missing or invalid IronSource interstitial ad Instance ID. "
                                      @"Using the default instance ID."];
    self.instanceID = GADMIronSourceDefaultRtbInstanceId;
  }

  NSString *bidResponse = adConfiguration.bidResponse;
  NSMutableDictionary<NSString *, NSString *> *extraParams =
      [GADMAdapterIronSourceUtils getExtraParamsWithWatermark:adConfiguration.watermark];
  ISAAdSize *iAdsBannerSize =
      [GADMAdapterIronSourceUtils iAdsSizeFromRequestedSize:adConfiguration.adSize];
  ISABannerAdRequestBuilder *requestBuilder = [[[ISABannerAdRequestBuilder alloc]
      initWithInstanceId:self.instanceID
                     adm:bidResponse
                    size:iAdsBannerSize] withExtraParams:extraParams];

  ISABannerAdRequest *adRequest =
      [[requestBuilder withViewController:adConfiguration.topViewController] build];

  [ISABannerAdLoader loadAdWithAdRequest:adRequest delegate:self];
}

- (void)bannerAdDidLoad:(nonnull ISABannerAdView *)bannerAdView {
  if (self.bannerAdLoadCompletionHandler == nil) {
    return;
  }
  bannerAdView.delegate = self;
  _biddingISABannerAd = bannerAdView;
  self.bannerAdEventDelegate = self.bannerAdLoadCompletionHandler(self, nil);
}

- (void)bannerAdDidFailToLoadWithError:(nonnull NSError *)error {
  if (!self.bannerAdLoadCompletionHandler) {
    return;
  }
  self.bannerAdLoadCompletionHandler(nil, error);
}

- (void)bannerAdViewDidShow:(nonnull ISABannerAdView *)bannerAdView {
  id<GADMediationBannerAdEventDelegate> bannerDelegate = self.bannerAdEventDelegate;
  if (!bannerDelegate) {
    return;
  }
  [bannerDelegate reportImpression];
}

- (void)bannerAdViewDidClick:(nonnull ISABannerAdView *)bannerAdView {
  id<GADMediationBannerAdEventDelegate> bannerDelegate = self.bannerAdEventDelegate;
  if (!bannerDelegate) {
    return;
  }
  [bannerDelegate reportClick];
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
  return _biddingISABannerAd;
}

@end

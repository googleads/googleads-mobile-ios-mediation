// Copyright 2020 Google LLC.
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

#import "GADRTBAdapterMaioEntryPoint.h"
#import "GADRTBMaioRewardedAd.h"
#import "GADRTBMaioInterstitialAd.h"

@implementation GADRTBAdapterMaioEntryPoint {
  GADRTBMaioRewardedAd *_rewarded;
  GADRTBMaioInterstitialAd *_interstitial;
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params completionHandler:(nonnull GADRTBSignalCompletionHandler)completionHandler {
  completionHandler(nil, nil);
}

-(void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewarded = [[GADRTBMaioRewardedAd alloc] initWithAdConfiguration:adConfiguration];
  [_rewarded loadRewardedAdWithCompletionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitial = [[GADRTBMaioInterstitialAd alloc] initWithAdConfiguration:adConfiguration];
  [_interstitial loadInterstitialWithCompletionHandler:completionHandler];
}

@end

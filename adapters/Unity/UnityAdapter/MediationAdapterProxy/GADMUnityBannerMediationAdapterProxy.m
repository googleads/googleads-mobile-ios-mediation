// Copyright 2021 Google LLC.
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

#import "GADMUnityBannerMediationAdapterProxy.h"

@interface GADMUnityBannerMediationAdapterProxy ()
@property(nonatomic, copy) GADMediationBannerLoadCompletionHandler loadCompletionHandler;
@property(nonatomic, weak) id<GADMediationBannerAd> ad;
@end

@implementation GADMUnityBannerMediationAdapterProxy

- (nonnull instancetype)initWithAd:(id<GADMediationBannerAd>)ad
         completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _ad = ad;
    _loadCompletionHandler = completionHandler;
  }
  return self;
}

#pragma mark UADSBannerViewDelegate

- (void)bannerViewDidLoad:(UADSBannerView *)bannerView {
  self.eventDelegate = self.loadCompletionHandler(self.ad, nil);
}

- (void)bannerViewDidError:(UADSBannerView *)bannerView error:(UADSBannerError *)error {
  self.loadCompletionHandler(self.ad, error);
}

@end

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

#import "GADMUnityBannerNetworkAdapterProxy.h"

@implementation GADMUnityBannerNetworkAdapterProxy

#pragma mark UADSBannerViewDelegate

- (void)bannerViewDidLoad:(UADSBannerView *)bannerView {
  if (!self.adapter) {
    return;
  }
  [self.connector adapter:self.adapter didReceiveAdView:bannerView];
}

- (void)bannerViewDidError:(UADSBannerView *)bannerView error:(UADSBannerError *)error {
  if (!self.adapter) {
    return;
  }
  [self.connector adapter:self.adapter didFailAd:error];
}

- (void)bannerViewDidClick:(UADSBannerView *)bannerView {
  if (!self.adapter) {
    return;
  }
  [self.connector adapterDidGetAdClick:self.adapter];
}

- (void)bannerViewDidLeaveApplication:(UADSBannerView *)bannerView {
  [self.connector adapterWillLeaveApplication:self.adapter];
}

@end

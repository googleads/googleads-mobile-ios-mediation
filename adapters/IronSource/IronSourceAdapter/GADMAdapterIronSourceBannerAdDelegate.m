// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterIronSourceBannerAdDelegate.h"
#import <Foundation/Foundation.h>
#import "GADMAdapterIronSourceBannerAd.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"

@implementation GADMAdapterIronSourceBannerAdDelegate

- (GADMAdapterIronSourceBannerAdDelegate *)init {
  return self;
}

#pragma mark - ISDemandOnlyBannerDelegate

- (void)didClickBanner:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource banner ad was clicked for Instance ID: %@",
                                       instanceId]];

  GADMAdapterIronSourceBannerAd *adInstance =
      [GADMAdapterIronSourceBannerAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  id<GADMediationBannerAdEventDelegate> eventDelegate = [adInstance getBannerAdEventDelegate];
  if (eventDelegate != nil) {
    [eventDelegate reportClick];
  }
}

- (void)bannerDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:
                          @"IronSource banner ad failed to load for Instance ID: %@ with error: %@",
                          instanceId, error.localizedDescription]];

  GADMAdapterIronSourceBannerAd *adInstance =
      [GADMAdapterIronSourceBannerAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  [adInstance setState:GADMAdapterIronSourceInstanceStateCanLoad];
  [adInstance getLoadCompletionHandler](nil, error);
}

- (void)bannerDidLoad:(ISDemandOnlyBannerView *)bannerView instanceId:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource banner ad was loaded for Instance ID: %@",
                                       instanceId]];

  GADMAdapterIronSourceBannerAd *adInstance =
      [GADMAdapterIronSourceBannerAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  [adInstance setState:GADMAdapterIronSourceInstanceStateCanLoad];
  [adInstance setBannerView:bannerView];
  [adInstance setBannerAdEventDelegate:([adInstance getLoadCompletionHandler](adInstance, nil))];
}

- (void)bannerDidShow:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource banner ad was shown for Instance ID: %@",
                                       instanceId]];

  GADMAdapterIronSourceBannerAd *adInstance =
      [GADMAdapterIronSourceBannerAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  id<GADMediationBannerAdEventDelegate> eventDelegate = [adInstance getBannerAdEventDelegate];
  if (eventDelegate != nil) {
    [eventDelegate reportImpression];
  }
}

- (void)bannerWillLeaveApplication:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:
                          @"IronSource banner ad will leave the application for Instance ID: %@",
                          instanceId]];

  GADMAdapterIronSourceBannerAd *adInstance =
      [GADMAdapterIronSourceBannerAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  id<GADMediationBannerAdEventDelegate> eventDelegate = [adInstance getBannerAdEventDelegate];
  if (eventDelegate != nil) {
    [eventDelegate willDismissFullScreenView];
  }
}

@end

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

#import "GADMUnityInterstitialNetworkAdapterProxy.h"
#import "GADMAdapterUnityConstants.h"
#import "NSErrorUnity.h"

@implementation GADMUnityInterstitialNetworkAdapterProxy

#pragma mark UnityAdsLoadDelegate

- (void)unityAdsAdFailedToLoad:(nonnull NSString *)placementId
                     withError:(UnityAdsLoadError)errorCode
                   withMessage:(nonnull NSString *)message {
  if (!self.adapter) {
    return;
  }

  [self.connector adapter:self.adapter didFailAd:[NSError adNotAvailablePerPlacement:placementId]];
}

- (void)unityAdsAdLoaded:(nonnull NSString *)placementId {
  if (!self.adapter) {
    return;
  }
  [self.connector adapterDidReceiveInterstitial:self.adapter];
}
#pragma mark UnityAdsShowDelegate

- (void)unityAdsShowClick:(nonnull NSString *)placementId {
  if (!self.adapter) {
    return;
  }
  [self.connector adapterDidGetAdClick:self.adapter];
  [self.connector adapterWillLeaveApplication:self.adapter];
}

- (void)unityAdsShowComplete:(nonnull NSString *)placementId
             withFinishState:(UnityAdsShowCompletionState)state {
  if (!self.adapter) {
    return;
  }
  [self notifyDismiss];
}

- (void)unityAdsShowFailed:(nonnull NSString *)placementId
                 withError:(UnityAdsShowError)error
               withMessage:(nonnull NSString *)message {
  if (!self.adapter) {
    return;
  }
  // Simulate show failure by calling adapterWillPresentInterstitial just before
  // adapterWillDismissInterstitial.
  [self.connector adapterWillPresentInterstitial:self.adapter];
  [self notifyDismiss];
}

- (void)unityAdsShowStart:(nonnull NSString *)placementId {
  if (!self.adapter) {
    return;
  }
  [self.connector adapterWillPresentInterstitial:self.adapter];
}

- (void)notifyDismiss {
  [self.connector adapterWillDismissInterstitial:self.adapter];
  [self.connector adapterDidDismissInterstitial:self.adapter];
}

@end

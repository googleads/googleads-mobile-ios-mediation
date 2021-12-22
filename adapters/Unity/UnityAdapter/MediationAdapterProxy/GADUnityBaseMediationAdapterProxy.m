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

#import "GADUnityBaseMediationAdapterProxy.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"

@implementation GADUnityBaseMediationAdapterProxy

#pragma mark UnityAdsLoadDelegate

- (void)unityAdsAdFailedToLoad:(nonnull NSString *)placementId
                     withError:(UnityAdsLoadError)loadError
                   withMessage:(nonnull NSString *)message {
}

- (void)unityAdsAdLoaded:(nonnull NSString *)placementId {
}

#pragma mark UnityAdsShowDelegate

- (void)unityAdsShowClick:(nonnull NSString *)placementId {
  [self.eventDelegate reportClick];
}

- (void)unityAdsShowComplete:(nonnull NSString *)placementId
             withFinishState:(UnityAdsShowCompletionState)state {
  [self.eventDelegate willDismissFullScreenView];
  [self.eventDelegate didDismissFullScreenView];
}

- (void)unityAdsShowFailed:(nonnull NSString *)placementId
                 withError:(UnityAdsShowError)error
               withMessage:(nonnull NSString *)message {
  NSError *errorWithDescription =
      GADMAdapterUnitySDKErrorWithUnityAdsShowErrorAndMessage(error, message);
  [self.eventDelegate didFailToPresentWithError:errorWithDescription];
}

- (void)unityAdsShowStart:(nonnull NSString *)placementId {
  [self.eventDelegate willPresentFullScreenView];
}

#pragma mark UADSBannerViewDelegate

- (void)bannerViewDidLoad:(UADSBannerView *)bannerView {
}

- (void)bannerViewDidError:(UADSBannerView *)bannerView error:(UADSBannerError *)error {
}

- (void)bannerViewDidClick:(UADSBannerView *)bannerView {
  [self.eventDelegate reportClick];
}

- (void)bannerViewDidLeaveApplication:(UADSBannerView *)bannerView {
}

@end

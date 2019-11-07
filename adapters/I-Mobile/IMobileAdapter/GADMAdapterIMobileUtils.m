// Copyright 2019 Google LLC
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

#import "GADMAdapterIMobileUtils.h"
#import "GADMAdapterIMobileConstants.h"

/// Create NSError from descritption.
NSError *_Nonnull GADMAdapterIMobileErrorWithCodeAndDescription(NSUInteger code,
                                                                NSString *_Nonnull description) {
  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description};
  return [NSError errorWithDomain:kGADMAdapterIMobileErrorDomain code:code userInfo:userInfo];
}

/// Convert i-mobile fail result to AdMob error code.
GADErrorCode GADMAdapterIMobileAdMobErrorFromIMobileResult(ImobileSdkAdsFailResult iMobileResult) {
  switch (iMobileResult) {
    case IMOBILESDKADS_ERROR_PARAM:
    case IMOBILESDKADS_ERROR_AUTHORITY:
      return kGADErrorInvalidArgument;
    case IMOBILESDKADS_ERROR_RESPONSE:
    case IMOBILESDKADS_ERROR_UNKNOWN:
      return kGADErrorInternalError;
    case IMOBILESDKADS_ERROR_NETWORK_NOT_READY:
    case IMOBILESDKADS_ERROR_NETWORK:
      return kGADErrorNetworkError;
    case IMOBILESDKADS_ERROR_AD_NOT_READY:
    case IMOBILESDKADS_ERROR_NOT_FOUND:
      return kGADErrorNoFill;
    case IMOBILESDKADS_ERROR_SHOW_TIMEOUT:
      return kGADErrorTimeout;
  }

  return kGADErrorMediationAdapterError;
}

GADAdSize GADMAdapterIMobileAdSizeFromGADAdSize(GADAdSize gadAdSize) {
  GADAdSize bannerSize = GADAdSizeFromCGSize(CGSizeMake(320, 50));
  GADAdSize bigBannerSize = GADAdSizeFromCGSize(CGSizeMake(320, 100));
  GADAdSize mediumRectSize = GADAdSizeFromCGSize(CGSizeMake(300, 250));
  NSArray<NSValue *> *potentialSizes = @[ @(bannerSize), @(bigBannerSize), @(mediumRectSize) ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentialSizes);
  return closestSize;
}

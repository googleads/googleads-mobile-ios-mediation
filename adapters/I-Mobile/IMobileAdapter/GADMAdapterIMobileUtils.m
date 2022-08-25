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

NSError *_Nonnull GADMAdapterIMobileErrorWithCodeAndDescription(GADMAdapterIMobileErrorCode code,
                                                                NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  return [NSError errorWithDomain:GADMAdapterIMobileErrorDomain code:code userInfo:userInfo];
}

NSError *_Nonnull GADMAdapterIMobileErrorWithFailResultAndDescription(
    ImobileSdkAdsFailResult failResult, NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  return [NSError errorWithDomain:GADMAdapterIMobileErrorDomain code:failResult userInfo:userInfo];
}

void GADMAdapterIMobileMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                               id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

void GADMAdapterIMobileMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable,
                                                  id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

GADAdSize GADMAdapterIMobileAdSizeFromGADAdSize(GADAdSize gadAdSize) {
  GADAdSize bannerSize = GADAdSizeFromCGSize(CGSizeMake(320, 50));
  GADAdSize bigBannerSize = GADAdSizeFromCGSize(CGSizeMake(320, 100));
  GADAdSize mediumRectSize = GADAdSizeFromCGSize(CGSizeMake(300, 250));
  NSArray<NSValue *> *potentialSizes = @[ @(bannerSize), @(bigBannerSize), @(mediumRectSize) ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentialSizes);
  return closestSize;
}

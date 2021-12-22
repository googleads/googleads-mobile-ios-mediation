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

#import "NSErrorUnity.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"

@implementation NSError (Unity)
+ (nonnull NSError *)noValidGameId {
  return GADMAdapterUnityErrorWithCodeAndDescription(
      GADMAdapterUnityErrorInvalidServerParameters,
      @"UnityAds mediation configurations did not contain a valid game ID.");
}

+ (nonnull NSError *)unsupportedBannerGADAdSize:(GADAdSize)adSize {
  NSString *errorMsg = [NSString
      stringWithFormat:
          @"UnityAds supported banner sizes are not a good fit for the requested size: %@",
          NSStringFromGADAdSize(adSize)];
  return GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorSizeMismatch, errorMsg);
}

+ (nonnull NSError *)adNotAvailablePerPlacement:(NSString *)placementId {
  NSString *errorMsg =
      [NSString stringWithFormat:@"No ad available for the placement ID: %@", placementId];
  return GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorPlacementStateNoFill,
                                                     errorMsg);
}
@end

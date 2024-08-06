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

#import "GADMAdapterVungleUtils.h"
#import "GADMAdapterVungleConstants.h"

NSError *_Nonnull GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorCode code,
                                                               NSString *_Nonnull description) {
  NSDictionary<NSString *, NSString *> *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterVungleErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

VungleAdSize *_Nonnull GADMAdapterVungleConvertGADAdSizeToVungleAdSize(
    GADAdSize adSize, NSString *_Nonnull placementId) {
  return [VungleAdSize VungleValidAdSizeFromCGSizeWithSize:adSize.size placementId:placementId];
}

@implementation GADMAdapterVungleUtils

+ (nonnull NSString *)findAppID:(nullable NSDictionary *)serverParameters {
  NSString *appId = serverParameters[GADMAdapterVungleApplicationID];
  if (!appId) {
    NSString *const message = @"Liftoff Monetize app ID should be specified!";
    NSLog(message);
    return @"";
  }
  return appId;
}

+ (nonnull NSString *)findPlacement:(nullable NSDictionary *)serverParameters {
  NSString *placementId = serverParameters[GADMAdapterVunglePlacementID];
  return placementId ? placementId : @"";
}

#pragma mark - Safe Collection utility methods.

void GADMAdapterVungleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

@end

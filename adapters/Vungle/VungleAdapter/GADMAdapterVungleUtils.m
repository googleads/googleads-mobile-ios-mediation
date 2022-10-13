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

NSError *_Nonnull GADMAdapterVungleErrorToGADError(GADMAdapterVungleErrorCode code,
                                                               NSInteger vungleCode,
                                                               NSString *_Nonnull description) {
  NSString *formattedDescription = [NSString stringWithFormat:@"Code: %ld, Description: %@", (long)vungleCode, description];
  return GADMAdapterVungleErrorWithCodeAndDescription(code, formattedDescription);
}

NSError *_Nonnull GADMAdapterVungleInvalidPlacementErrorWithCodeAndDescription() {
  GADMAdapterVungleErrorCode code = GADMAdapterVungleErrorInvalidServerParameters;
  NSString *description = @"Placement ID not specified.";
  return GADMAdapterVungleErrorWithCodeAndDescription(code, description);
}

NSError *_Nonnull GADMAdapterVungleInvalidAppIdErrorWithCodeAndDescription() {
  GADMAdapterVungleErrorCode code = GADMAdapterVungleErrorInvalidServerParameters;
  NSString *description = @"Vungle app ID not specified.";
  return GADMAdapterVungleErrorWithCodeAndDescription(code, description);
}

@implementation GADMAdapterVungleUtils

+ (nullable NSString *)findAppID:(nullable NSDictionary *)serverParameters {
  NSString *appId = serverParameters[GADMAdapterVungleApplicationID];
  if (!appId) {
    NSString *const message = @"Vungle app ID should be specified!";
    NSLog(message);
    return nil;
  }
  return appId;
}

+ (nullable NSString *)findPlacement:(nullable NSDictionary *)serverParameters
                       networkExtras:(nullable VungleAdNetworkExtras *)networkExtras {
  NSString *ret = serverParameters[GADMAdapterVunglePlacementID];
  if (networkExtras && networkExtras.playingPlacement) {
    if (ret) {
      NSLog(@"'placementID' had a value in both serverParameters and networkExtras. "
            @"Used one from serverParameters.");
    } else {
      ret = networkExtras.playingPlacement;
    }
  }

  return ret;
}

@end

// Copyright 2022 Google LLC
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

#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"

NSError *_Nonnull GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorCode code,
                                                               NSString *_Nonnull description) {
  return [NSError errorWithDomain:GADMAdapterPangleErrorDomain
                             code:code
                         userInfo:@{
                           NSLocalizedDescriptionKey : description,
                           NSLocalizedFailureReasonErrorKey : description
                         }];
}

NSError *_Nonnull GADMAdapterPangleChildUserError(void) {
    NSString *errorMsg = @"GADMobileAds.sharedInstance.requestConfiguration indicates the user is a child. Pangle SDK V71 or higher does not support child users.";
    return GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorChildUser,errorMsg);;
}

void GADMAdapterPangleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

@implementation GADMAdapterPangleUtils

+ (BOOL)isChildUser {
    GADRequestConfiguration *requestConfiguration = GADMobileAds.sharedInstance.requestConfiguration;
    return [requestConfiguration.tagForChildDirectedTreatment boolValue] ||
           [requestConfiguration.tagForUnderAgeOfConsent boolValue];
}


@end

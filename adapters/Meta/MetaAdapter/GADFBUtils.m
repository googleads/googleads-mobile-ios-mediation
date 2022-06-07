// Copyright 2019 Google LLC.
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

#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NSError *_Nonnull GADFBErrorWithCodeAndDescription(GADFBErrorCode code,
                                                   NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                       code:code
                                   userInfo:userInfo];
  return error;
}

void GADFBConfigureMediationService(void) {
  [FBAdSettings
      setMediationService:[NSString stringWithFormat:@"GOOGLE_%@:%@",
                                                     GADMobileAds.sharedInstance.sdkVersion,
                                                     GADMAdapterFacebookVersion]];
}

void GADMAdapterFacebookMutableSetAddObject(NSMutableSet *_Nullable set,
                                            NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

void GADMAdapterFacebookSetMixedAudience(NSNumber *_Nonnull childDirectedTreatment) {
  [FBAdSettings setMixedAudience:childDirectedTreatment.boolValue];
}

// Copyright 2016 Google Inc.
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

#import "GADMChartboostError.h"
#import "GADMAdapterChartboostConstants.h"

NSError *GADChartboostErrorWithDescription(NSString *description) {
  description = description ? [description copy] : @"";
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:kGADMAdapterChartboostErrorDomain
                                       code:0
                                   userInfo:userInfo];
  return error;
}

NSError *NSErrorForCHBCacheError(CHBCacheError *error) {
  return GADChartboostErrorWithDescription(error.description);
}

NSError *NSErrorForCHBShowError(CHBShowError *error) {
  return GADChartboostErrorWithDescription(error.description);
}

NSError *NSErrorForCHBClickError(CHBClickError *error) {
  return GADChartboostErrorWithDescription(error.description);
}

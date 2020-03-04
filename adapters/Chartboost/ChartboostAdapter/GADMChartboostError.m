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

GADErrorCode GADErrorCodeForCHBCacheErrorCode(CHBCacheErrorCode code);

NSError *GADChartboostError(GADErrorCode code, NSString *description) {
  description = description ? [description copy] : @"";
  return [NSError errorWithDomain:kGADMAdapterChartboostErrorDomain
                             code:0
                         userInfo:@{NSLocalizedDescriptionKey : description,
                                    NSLocalizedFailureReasonErrorKey : description}];
}

NSError *NSErrorForCHBCacheError(CHBCacheError *error) {
  return GADChartboostError(GADErrorCodeForCHBCacheErrorCode(error.code), [error description]);
}

NSError *NSErrorForCHBShowError(CHBShowError *error) {
  return GADChartboostError(0, [error description]);
}

NSError *NSErrorForCHBClickError(CHBClickError *error) {
  return GADChartboostError(0, [error description]);
}

GADErrorCode GADErrorCodeForCHBCacheErrorCode(CHBCacheErrorCode code) {
  switch (code) {
    case CHBCacheErrorCodeInternal: return kGADErrorInternalError;
    case CHBCacheErrorCodeInternetUnavailable: return kGADErrorNetworkError;
    case CHBCacheErrorCodeNetworkFailure: return kGADErrorNetworkError;
    case CHBCacheErrorCodeNoAdFound: return kGADErrorNoFill;
    case CHBCacheErrorCodeSessionNotStarted: return kGADErrorMediationAdapterError;
    case CHBCacheErrorCodeAssetDownloadFailure: return kGADErrorMediationDataError;
    case CHBCacheErrorCodePublisherDisabled: return kGADErrorInvalidRequest;
  }
  return kGADErrorInvalidRequest;
}

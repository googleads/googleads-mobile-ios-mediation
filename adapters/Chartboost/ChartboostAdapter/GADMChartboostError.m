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
#import "GADMAdapterChartboostUtils.h"

NSError *GADMChartboostErrorForCHBCacheError(CHBCacheError *error) {
  NSString *suffix = [NSString stringWithFormat:@"code %lu", (unsigned long)error.code];
  switch (error.code) {
    case CHBCacheErrorCodeInternal:
      suffix = @"CHBCacheErrorCodeInternal";
      break;
    case CHBCacheErrorCodeInternetUnavailable:
      suffix = @"CHBCacheErrorCodeInternetUnavailable";
      break;
    case CHBCacheErrorCodeNetworkFailure:
      suffix = @"CHBCacheErrorCodeNetworkFailure";
      break;
    case CHBCacheErrorCodeNoAdFound:
      suffix = @"CHBCacheErrorCodeNoAdFound";
      break;
    case CHBCacheErrorCodeSessionNotStarted:
      suffix = @"CHBCacheErrorCodeSessionNotStarted";
      break;
    case CHBCacheErrorCodeAssetDownloadFailure:
      suffix = @"CHBCacheErrorCodeAssetDownloadFailure";
      break;
    case CHBCacheErrorCodePublisherDisabled:
      suffix = @"CHBCacheErrorCodePublisherDisabled";
      break;
  }

  NSString *description =
      [NSString stringWithFormat:@"Chartboost SDK returned a cache error: %@", suffix];
  return GADMAdapterChartboostErrorWithCodeAndDescription(200 + error.code, description);
}

NSError *GADMChartboostErrorForCHBShowError(CHBShowError *error) {
  NSString *suffix = [NSString stringWithFormat:@"code %lu", (unsigned long)error.code];
  switch (error.code) {
    case CHBShowErrorCodeInternal:
      suffix = @"CHBShowErrorCodeInternal";
      break;
    case CHBShowErrorCodeSessionNotStarted:
      suffix = @"CHBShowErrorCodeSessionNotStarted";
      break;
    case CHBShowErrorCodeAdAlreadyVisible:
      suffix = @"CHBShowErrorCodeAdAlreadyVisible";
      break;
    case CHBShowErrorCodeInternetUnavailable:
      suffix = @"CHBShowErrorCodeInternetUnavailable";
      break;
    case CHBShowErrorCodePresentationFailure:
      suffix = @"CHBShowErrorCodePresentationFailure";
      break;
    case CHBShowErrorCodeNoCachedAd:
      suffix = @"CHBShowErrorCodeNoCachedAd";
      break;
  }
  NSString *description =
      [NSString stringWithFormat:@"Chartboost SDK returned a show error: %@", suffix];
  return GADMAdapterChartboostErrorWithCodeAndDescription(300 + error.code, description);
}

NSError *GADMChartboostErrorForCHBClickError(CHBClickError *error) {
  NSString *suffix = [NSString stringWithFormat:@"code %lu", (unsigned long)error.code];
  switch (error.code) {
    case CHBClickErrorCodeUriInvalid:
      suffix = @"CHBClickErrorCodeUriInvalid";

      break;
    case CHBClickErrorCodeUriUnrecognized:
      suffix = @"CHBClickErrorCodeUriUnrecognized";
      break;
    case CHBClickErrorCodeConfirmationGateFailure:
      suffix = @"CHBClickErrorCodeConfirmationGateFailure";
      break;
    case CHBClickErrorCodeInternal:
      suffix = @"CHBClickErrorCodeInternal";
      break;
  }
  NSString *description =
      [NSString stringWithFormat:@"Chartboost SDK returned a click error: %@", suffix];
  return GADMAdapterChartboostErrorWithCodeAndDescription(400 + error.code, description);
}

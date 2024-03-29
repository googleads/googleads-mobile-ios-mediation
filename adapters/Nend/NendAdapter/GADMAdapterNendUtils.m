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

#import "GADMAdapterNendUtils.h"
#import "GADMAdapterNendConstants.h"

NSError *_Nonnull GADMAdapterNendErrorWithCodeAndDescription(GADMAdapterNendErrorCode code,
                                                             NSString *_Nonnull description) {
  NSDictionary<NSString *, id> *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterNendErrorDomain code:code userInfo:userInfo];
  return error;
}

NSError *_Nonnull GADMAdapterNendSDKLoadError() {
  NSString *_Nonnull message = @"nend SDK returned a load failure callback.";
  NSDictionary<NSString *, id> *userInfo =
      @{NSLocalizedDescriptionKey : message, NSLocalizedFailureReasonErrorKey : message};
  NSError *error = [NSError errorWithDomain:GADMAdapterNendErrorDomain
                                       code:GADMAdapterNendErrorLoadFailureCallback
                                   userInfo:userInfo];
  return error;
}

NSError *_Nonnull GADMAdapterNendSDKPresentError() {
  NSString *_Nonnull message = @"nend SDK returned a show failure callback.";
  NSDictionary<NSString *, id> *userInfo =
      @{NSLocalizedDescriptionKey : message, NSLocalizedFailureReasonErrorKey : message};
  NSError *error = [NSError errorWithDomain:GADMAdapterNendErrorDomain
                                       code:GADMAdapterNendErrorShowFailureCallback
                                   userInfo:userInfo];
  return error;
}

NSError *_Nonnull GADMAdapterNendErrorForShowResult(NADInterstitialShowResult result) {
  NSString *suffix = [NSString stringWithFormat:@"result %lu", (unsigned long)result];
  NSInteger code = 299;
  switch (result) {
    case AD_SHOW_SUCCESS:
      suffix = @"AD_SHOW_SUCCESS";
      code = 200;
      break;
    case AD_LOAD_INCOMPLETE:
      suffix = @"AD_LOAD_INCOMPLETE";
      code = 201;
      break;
    case AD_REQUEST_INCOMPLETE:
      suffix = @"AD_REQUEST_INCOMPLETE";
      code = 202;
      break;
    case AD_DOWNLOAD_INCOMPLETE:
      suffix = @"AD_DOWNLOAD_INCOMPLETE";
      code = 203;
      break;
    case AD_FREQUENCY_NOT_REACHABLE:
      suffix = @"AD_FREQUENCY_NOT_REACHABLE";
      code = 204;
      break;
    case AD_SHOW_ALREADY:
      suffix = @"AD_SHOW_ALREADY";
      code = 205;
      break;
    case AD_CANNOT_DISPLAY:
      suffix = @"AD_CANNOT_DISPLAY";
      code = 206;
      break;
  }
  NSString *description =
      [NSString stringWithFormat:@"nend SDK returned failed to show ad with reason: %@", suffix];
  return GADMAdapterNendErrorWithCodeAndDescription(code, description);
}

NSError *_Nullable GADMAdapterNendValidateSpotID(NSString *_Nullable spotID) {
  if (!spotID) {
    return GADMAdapterNendErrorWithCodeAndDescription(GADMAdapterNendInvalidServerParameters,
                                                      @"Spot ID must not be nil.");
  }

  if (![spotID isKindOfClass:[NSString class]]) {
    return GADMAdapterNendErrorWithCodeAndDescription(GADMAdapterNendInvalidServerParameters,
                                                      @"Spot ID must be a string.");
  }

  if (spotID.integerValue == 0) {
    return GADMAdapterNendErrorWithCodeAndDescription(GADMAdapterNendInvalidServerParameters,
                                                      @"Spot ID must be valid.");
  }

  return nil;
}

NSError *_Nullable GADMAdapterNendValidateAPIKey(NSString *_Nullable APIKey) {
  if (!APIKey) {
    return GADMAdapterNendErrorWithCodeAndDescription(GADMAdapterNendInvalidServerParameters,
                                                      @"API key must not be nil.");
  }

  if (![APIKey isKindOfClass:[NSString class]]) {
    return GADMAdapterNendErrorWithCodeAndDescription(GADMAdapterNendInvalidServerParameters,
                                                      @"API key must be a string.");
  }

  if (!APIKey.length) {
    return GADMAdapterNendErrorWithCodeAndDescription(GADMAdapterNendInvalidServerParameters,
                                                      @"API key must be valid.");
  }

  return nil;
}

/// Find closest supported ad size from a given ad size.
/// Returns nil if no supported size matches.
GADAdSize GADSupportedAdSizeFromRequestedSize(GADAdSize gadAdSize) {
  NSArray<NSValue *> *potentials = @[
    NSValueFromGADAdSize(GADAdSizeBanner),
    NSValueFromGADAdSize(GADAdSizeLargeBanner),
    NSValueFromGADAdSize(GADAdSizeMediumRectangle),
    NSValueFromGADAdSize(GADAdSizeLeaderboard),
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);

  return closestSize;
}

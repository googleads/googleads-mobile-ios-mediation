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

NSError *GADChartboostErrorWithDescription(NSString *description) {
  description = [description copy];
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:@"com.google.mediation.chartboost"
                                       code:0
                                   userInfo:userInfo];
  return error;
}

NSError *adRequestErrorTypeForCBLoadError(CBLoadError error) {
  NSString *description = nil;
  switch (error) {
    case CBLoadErrorInternal:
      description = @"Internal error.";
      break;
    case CBLoadErrorInternetUnavailable:
      description = @"Internet unavailable.";
      break;
    case CBLoadErrorTooManyConnections:
      description = @"Too many connections.";
      break;
    case CBLoadErrorWrongOrientation:
      description = @"Wrong orientation.";
      break;
    case CBLoadErrorFirstSessionInterstitialsDisabled:
      description = @"Interstitial disabled.";
      break;
    case CBLoadErrorNetworkFailure:
      description = @"Network failure.";
      break;
    case CBLoadErrorNoAdFound:
      description = @"No ad found.";
      break;
    case CBLoadErrorSessionNotStarted:
      description = @"Session not started.";
      break;
    case CBLoadErrorImpressionAlreadyVisible:
      description = @"Impression already visible.";
      break;
    case CBLoadErrorUserCancellation:
      description = @"User cancellation.";
      break;
    case CBLoadErrorNoLocationFound:
      description = @"No location found.";
      break;
    case CBLoadErrorAssetDownloadFailure:
      description = @"Error downloading asset.";
      break;
    case CBLoadErrorPrefetchingIncomplete:
      description = @"Video prefetching is not finished.";
      break;
    case CBLoadErrorWebViewScriptError:
      description = @"Web view script error.";
      break;
    case CBLoadErrorInternetUnavailableAtShow:
      description = @"Internet unavailable while presenting.";
      break;
    default:
      description = @"No inventory.";
      break;
  }

  return GADChartboostErrorWithDescription(description);
}

NSError *NSErrorWithCHBCacheError(CHBCacheError *error)
{
    return GADChartboostErrorWithDescription([error description]);
}

NSError *NSErrorWithCHBShowError(CHBShowError *error)
{
    return GADChartboostErrorWithDescription([error description]);
}

NSError *NSErrorWithCHBClickError(CHBClickError *error)
{
    return GADChartboostErrorWithDescription([error description]);
}

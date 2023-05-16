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

#import "GADMAdapterYahooUtils.h"
#import <YahooAds/YahooAds.h>
#import "GADMAdapterYahooConstants.h"

void GADMAdapterYahooMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

BOOL GADMAdapterYahooInitializeYASAdsWithSiteID(NSString *_Nullable siteID) {
  if (YASAds.sharedInstance.isInitialized) {
    return YES;
  }

  if (!siteID.length) {
    siteID = [NSBundle.mainBundle objectForInfoDictionaryKey:GADMAdapterYahooSiteID];
  }

  NSLog(@"[YahooAdapter] Initializing Yahoo Mobile SDK with the site ID: %@", siteID);
  BOOL isInitialized = [YASAds initializeWithSiteId:siteID];
  YASAds.logLevel = YASLogLevelError;

  return isInitialized;
}

NSError *_Nonnull GADMAdapterYahooErrorWithCodeAndDescription(GADMAdapterYahooErrorCode code,
                                                              NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterYahooErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

CGSize GADMAdapterYahooSupportedAdSizeFromRequestedSize(GADAdSize adSize) {
  NSArray *potentials = @[
    NSValueFromGADAdSize(GADAdSizeBanner), NSValueFromGADAdSize(GADAdSizeMediumRectangle),
    NSValueFromGADAdSize(GADAdSizeLeaderboard)
  ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(adSize, potentials);
  if (IsGADAdSizeValid(closestSize)) {
    return CGSizeFromGADAdSize(closestSize);
  }

  return CGSizeZero;
}

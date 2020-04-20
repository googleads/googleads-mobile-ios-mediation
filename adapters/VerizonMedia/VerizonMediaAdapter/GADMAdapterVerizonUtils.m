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

#import "GADMAdapterVerizonUtils.h"

#import <VerizonAdsCore/VASAds+Private.h>
#import <VerizonAdsCore/VASPEXRegistry.h>
#import <VerizonAdsStandardEdition/VerizonAdsStandardEdition.h>
#import <VerizonAdsURIExperience/VerizonAdsURIExperience.h>

#import "GADMAdapterVerizonConstants.h"
#import "GADMVerizonPrivacy_Internal.h"

void GADMAdapterVerizonMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

BOOL GADMAdapterVerizonInitializeVASAdsWithSiteID(NSString *_Nullable siteID) {
  if (![VASAds.sharedInstance isInitialized]) {
    if (!siteID.length) {
      siteID = [NSBundle.mainBundle objectForInfoDictionaryKey:kGADMAdapterVerizonMediaSiteID];
    }
    BOOL isInitialized = [VASStandardEdition initializeWithSiteId:siteID];
    
    [GADMVerizonPrivacy.sharedInstance updatePrivacyData];
    VASAds.logLevel = VASLogLevelError;
      
    return isInitialized;
  }
  return YES;
}

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

#import "GADMAdapterTapjoyUtils.h"

#import <Tapjoy/Tapjoy.h>

#import "GADMAdapterTapjoyConstants.h"

void GADMAdapterTapjoyMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

void GADMAdapterTapjoyMutableArrayAddObject(NSMutableArray *_Nullable array,
                                            NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  }
}

void GADMAdapterTapjoyMutableArrayRemoveObject(NSMutableArray *_Nullable array,
                                               NSObject *_Nonnull object) {
  if (object) {
    [array removeObject:object];  // Allow pattern.
  }
}

void GADMAdapterTapjoyMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                              id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

void GADMAdapterTapjoyMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

void GADMAdapterTapjoyMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                       id<NSCopying> _Nullable key,
                                                       id _Nullable value) {
  if (value && key) {
    dictionary[key] = value;  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterTapjoyErrorWithCodeAndDescription(GADMAdapterTapjoyErrorCode code,
                                                               NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  return [NSError errorWithDomain:GADMAdapterTapjoyErrorDomain code:code userInfo:userInfo];
}

NSDictionary<NSString *, id> *_Nonnull GADMAdapterTapjoyAuctionDataForResponseData(
    NSDictionary<id, id> *_Nullable responseData) {
  NSMutableDictionary<NSString *, id> *auctionData = [[NSMutableDictionary alloc] init];

  if (responseData) {
    GADMAdapterTapjoyMutableDictionarySetObjectForKey(auctionData, TJ_AUCTION_DATA,
                                                      responseData[TJ_AUCTION_DATA]);
    GADMAdapterTapjoyMutableDictionarySetObjectForKey(auctionData, TJ_AUCTION_ID,
                                                      responseData[TJ_AUCTION_ID]);
  }

  return auctionData;
}

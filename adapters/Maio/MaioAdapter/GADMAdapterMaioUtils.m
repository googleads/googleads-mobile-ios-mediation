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

#import "GADMAdapterMaioUtils.h"
#import "GADMMaioConstants.h"

//@implementation GADMAdapterMaioUtils : NSObject
/**
 *  MaioFailReason の文字列表記を取得します。
 */
static NSString *_Nonnull GADMAdapterMaioStringFromFailReason(MaioFailReason failReason) {
  switch (failReason) {
    case MaioFailReasonUnknown:
      return @"MaioFailReasonUnknown";
    case MaioFailReasonNetworkConnection:
      return @"MaioFailReasonNetworkConnection";
    case MaioFailReasonNetworkServer:
      return @"MaioFailReasonNetworkServer";
    case MaioFailReasonNetworkClient:
      return @"MaioFailReasonNetworkClient";
    case MaioFailReasonSdk:
      return @"MaioFailReasonSdk";
    case MaioFailReasonDownloadCancelled:
      return @"MaioFailReasonDownloadCancelled";
    case MaioFailReasonAdStockOut:
      return @"MaioFailReasonAdStockOut";
    case MaioFailReasonVideoPlayback:
      return @"MaioFailReasonVideoPlayback";
    case MaioFailReasonIncorrectMediaId:
      return @"MaioFailReasonInCorrectMediaId";
    case MaioFailReasonIncorrectZoneId:
      return @"MaioFailReasonInCorrectZoneId";
    case MaioFailReasonNotFoundViewContext:
      return @"MaioFailReasonNotFoundViewContext";
  }
  // Error to indicate that the error is new and has not been supported by the adapter yet.
  return [NSString stringWithFormat:@"maio SDK failed with reason code: %ld", (long)failReason];
}

void GADMAdapterMaioMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

void GADMAdapterMaioMutableArrayAddObject(NSMutableArray *_Nullable array,
                                          NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  } else {
    NSLog(@"Cannot add nil object to array. Array: %@", array);
  }
}

void GADMAdapterMaioMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

void GADMAdapterMaioMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                            id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterMaioErrorWithCodeAndDescription(GADMAdapterMaioErrorCode code,
                                                             NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMMaioErrorDomain code:code userInfo:userInfo];
  return error;
}

NSError *_Nonnull GADMAdapterMaioSDKErrorForFailReason(MaioFailReason reason) {
  NSString *description =
      [NSString stringWithFormat:@"maio SDK returned a load failure callback with reason: %@",
                                 GADMAdapterMaioStringFromFailReason(reason)];
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMMaioSDKErrorDomain code:reason userInfo:userInfo];
  return error;
}

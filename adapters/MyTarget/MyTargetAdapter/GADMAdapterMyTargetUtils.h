// Copyright 2017 Google LLC
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

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import "GADMediationAdapterMyTarget.h"

#define MTRGLogInfo()                                                                    \
  if (GADMAdapterMyTargetUtils.logEnabled) {                                             \
    NSLog(@"[%@ info] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); \
  }
#define MTRGLogDebug(format, ...)                               \
  if (GADMAdapterMyTargetUtils.logEnabled) {                    \
    NSLog(@"[%@ debug] %@", NSStringFromClass([self class]),    \
          [NSString stringWithFormat:(format), ##__VA_ARGS__]); \
  }
#define MTRGLogError(message)                                            \
  if (GADMAdapterMyTargetUtils.logEnabled) {                             \
    NSLog(@"[%@ error] %@", NSStringFromClass([self class]), (message)); \
  }

/// Sets |value| for |key| in |dictionary| if |value| is not nil.
void GADMAdapterMyTargetMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                         id<NSCopying> _Nullable key,
                                                         id _Nullable value);

/// Safely removes the |object| for |key| in |dictionary| if |key| is not nil.
void GADMAdapterMyTargetMutableDictionaryRemoveObjectForKey(
    NSMutableDictionary *_Nonnull dictionary, id _Nullable key);

/// Returns an SDK specific NSError with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterMyTargetSDKErrorWithDescription(NSString *_Nonnull description);

/// Returns an adapter specific NSError with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterMyTargetAdapterErrorWithDescription(NSString *_Nonnull description);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterMyTargetErrorWithCodeAndDescription(GADMAdapterMyTargetErrorCode code,
                                                                 NSString *_Nonnull description);

/// Sets myTarget's customParams from |networkExtras|.
void GADMAdapterMyTargetFillCustomParams(MTRGCustomParams *_Nonnull customParams,
                                         id<GADAdNetworkExtras> _Nullable networkExtras);

/// Gets the myTarget slot ID from the specified |credentials|.
NSUInteger GADMAdapterMyTargetSlotIdFromCredentials(
    NSDictionary<NSString *, id> *_Nullable credentials);

/// Returns a GADNativeAdImage from the specified myTarget |imageData|.
GADNativeAdImage *_Nullable GADMAdapterMyTargetNativeAdImageWithImageData(
    MTRGImageData *_Nullable imageData);

/// Returns the closest MTRGAdSize size from the requested GADAdSize.
MTRGAdSize *_Nullable GADMAdapterMyTargetSizeFromRequestedSize(
    GADAdSize gadAdSize, NSError *_Nullable __autoreleasing *_Nullable error);

@interface GADMAdapterMyTargetUtils : NSObject

/// Indicates whether debug logs are enabled for the myTarget adapter.
@property(class, nonatomic, assign) BOOL logEnabled;

@end

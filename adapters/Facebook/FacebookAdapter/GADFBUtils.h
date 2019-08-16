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

#import <Foundation/Foundation.h>

/// Macro wrapper for NSLog only if debug mode is enabled.
#if DEBUG
#define GADFB_LOG(fmt, ...) NSLog(fmt, ##__VA_ARGS__);
#else
/// If debug mode is not enabled, macro doesn't do anything when called.
#define GADFB_LOG(...)
#endif

/// Returns an NSError with NSLocalizedDescriptionKey and NSLocalizedFailureReasonErrorKey values
/// set to |description|.
NSError *_Nonnull GADFBErrorWithDescription(NSString *_Nonnull description);

/// Set the mediation service information in the Facebook Audience Network SDK.
void GADFBConfigureMediationService(void);

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterFacebookMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Sets |value| for |key| in |dictionary| if |value| is not nil.
void GADMAdapterFacebookMutableDictionarySet(NSMutableDictionary *_Nonnull dictionary,
                                             id<NSCopying> _Nullable key, id _Nullable value);

// Copyright 2019 Google Inc.
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
@import GoogleMobileAds;
#import <IronSource/IronSource.h>

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterIronSourceMutableSetAddObject(NSMutableSet *_Nullable set,
                                              NSObject *_Nonnull object);

/// Sets |value| for |key| in |mapTable| if |value| is not nil.
void GADMAdapterMaioMapTableSetObjectForKey(NSMapTable *_Nullable mapTable,
                                            id<NSCopying> _Nullable key, id _Nullable value);

/// Holds Shared code for IronSource adapters.
@interface GADMAdapterIronSourceUtils : NSObject

// IronSource Util methods.
+ (BOOL)isEmpty:(id)value;
+ (NSError *)createErrorWith:(NSString *)description
                   andReason:(NSString *)reason
               andSuggestion:(NSString *)suggestion;

+ (void)onLog:(NSString *)log;
+ (NSString *)getAdMobSDKVersion;

@end

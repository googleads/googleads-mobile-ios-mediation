// Copyright 2017 Google Inc.
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
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/IronSource.h>

/// Holds Shared code for IronSource adapters.
@interface GADMAdapterIronSourceBase : NSObject

// IronSource parameters keys.
extern NSString *const kGADMAdapterIronSourceAppKey;
extern NSString *const kGADMAdapterIronSourceIsTestEnabled;
extern NSString *const kGADMAdapterIronSourceInstanceId;
extern NSString *const kGADMAdapterIronSourceAdapterVersion;

/// Yes if we want to show IronSource adapter logs.
@property(nonatomic, assign) BOOL isLogEnabled;
/// Holds the ID of the ad instance to be presented.
@property(nonatomic, strong) NSString *instanceId;

+ (NSString *)adapterVersion;
+ (Class<GADAdNetworkExtras>)networkExtrasClass;
- (void)stopBeingDelegate;

// IronSource Util methods.
- (void)onLog:(NSString *)log;
- (BOOL)isEmpty:(id)value;
- (NSError *)createErrorWith:(NSString *)description
                   andReason:(NSString *)reason
               andSuggestion:(NSString *)suggestion;
- (void)initIronSourceSDKWithAppKey:(NSString *)appKey adUnit:(NSString *)adUnit;

@end

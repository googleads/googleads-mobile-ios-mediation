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

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IASDKCore/IASDKCore.h>

#define GADMAdapterFyberLog(format, args...) NSLog(@"FyberAdapter: " format, ##args)

/// Safely adds |object| to |set| if |object| is not nil.
void GADMAdapterFyberMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Creates and returns an NSError with the specified code and description.
NSError *_Nonnull GADMAdapterFyberErrorWithCodeAndDescription(NSInteger code,
                                                              NSString *_Nonnull description);

/// Creates and returns a GADVersionNumber from a specified string.
GADVersionNumber GADMAdapterFyberVersionFromString(NSString *_Nonnull versionString);

/// Creates an ad request object for Fyber from a given spot ID and connector.
IAAdRequest *_Nonnull GADMAdapterFyberBuildRequestWithSpotIDAndConnector(
    NSString *_Nonnull spotID, id<GADMAdNetworkConnector> _Nonnull connector);

/// Creates an ad request object for Fyber from a given spot ID and configuration.
IAAdRequest *_Nonnull GADMAdapterFyberBuildRequestWithSpotIDAndAdConfiguration(
    NSString *_Nonnull spotID, GADMediationAdConfiguration *_Nonnull adConfiguration);

/// Creates an ad request object for Fyber from the specified information.
IAAdRequest *_Nonnull GADMAdapterFyberBuildRequestWithSpotID(NSString *_Nonnull spotID,
                                                             NSString *_Nullable keywords,
                                                             CLLocation *_Nullable location);

/// Initializes the Fyber SDK with the given app ID. Returns YES if Fyber is initialized
/// successfully, otherwise NO and sets |error|.
BOOL GADMAdapterFyberInitializeWithAppID(NSString *_Nonnull appID,
                                         NSError *__autoreleasing _Nullable *_Nullable error);

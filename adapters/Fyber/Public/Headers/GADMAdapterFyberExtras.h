// Copyright 2020 Google LLC
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

@interface GADMAdapterFyberExtras : NSObject <GADAdNetworkExtras>

/// Use this to pass the user's info
@property(nonatomic, copy, nullable) IAUserData *userData;

/// Use this to pass keywords
@property(nonatomic, copy, nullable) NSString *keywords;

/// Controls whether presented ads will start in a muted state or not.
@property(nonatomic, assign) BOOL muteAudio;

@end

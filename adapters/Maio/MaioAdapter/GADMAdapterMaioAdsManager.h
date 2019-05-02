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

#import <Foundation/Foundation.h>
@import Maio;

typedef enum { UNINITIALIZED, INITIALIZING, INITIALIZED } MaioInitState;

typedef void (^MaioInitCompletionHandler)(NSError *_Nullable error);

@interface GADMAdapterMaioAdsManager : NSObject <MaioDelegate>

+ (GADMAdapterMaioAdsManager *)getMaioAdsManagerByMediaId:(NSString *)mediaId;
- (void)initializeMaioSDKWithCompletionHandler:(void (^)(NSError *))completionHandler;
- (NSError *)loadAdForZoneId:(NSString *)zoneId delegate:(id<MaioDelegate>)delegate;
- (void)showAdForZoneId:(NSString *)zoneId rootViewController:(UIViewController *)viewcontroller;
- (void)setAdTestMode:(BOOL)adTestMode;

@end

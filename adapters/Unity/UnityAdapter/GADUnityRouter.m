// Copyright 2021 Google LLC.
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


#import "GADUnityRouter.h"
#import <UnityAds/UnityAds.h>
#import "GADMAdapterUnityUtils.h"

@interface UnityAdsAdapterInitializationDelegate : NSObject<UnityAdsInitializationDelegate>
@property(nonatomic, copy) void (^ initializationCompleteBlock)(void);
@property(nonatomic, copy) void (^ initializationFailedBlock)(UnityAdsInitializationError error, NSString *message);
@end

@implementation UnityAdsAdapterInitializationDelegate
- (void)initializationComplete {
    if (self.initializationCompleteBlock) {
        self.initializationCompleteBlock();
    }
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(nonnull NSString *)message {
    if (self.initializationFailedBlock) {
        self.initializationFailedBlock(error, message);
    }
}

@end

@implementation GADUnityRouter

+ (GADUnityRouter *)sharedRouter {
    static GADUnityRouter * sharedRouter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRouter = [[GADUnityRouter alloc] init];
    });
    return sharedRouter;
}

- (void)sdkInitializeWithGameId:(NSString *)gameId withCompletionHandler:(void (^)(NSError *))complete {
    if ([UnityAds isInitialized] && complete != nil) {
        complete(nil);
    }
    
    static dispatch_once_t unityInitToken;
    dispatch_once(&unityInitToken, ^{
        GADMAdapterUnityConfigureMediationService();
        
        UnityAdsAdapterInitializationDelegate *initDelegate = [[UnityAdsAdapterInitializationDelegate alloc] init];
        
        initDelegate.initializationCompleteBlock = ^{
            if (complete != nil) {
                complete(nil);
            }
        };
        initDelegate.initializationFailedBlock = ^(UnityAdsInitializationError error, NSString *message) {
            if (complete != nil) {
                NSError *adapterError = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdInitializationFailure, message);
                complete(adapterError);
            }
        };
        [UnityAds initialize:gameId testMode:NO initializationDelegate:initDelegate];
    });
}

@end


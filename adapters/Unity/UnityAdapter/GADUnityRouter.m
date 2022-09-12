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

@interface UnityAdsAdapterInitializationDelegate : NSObject <UnityAdsInitializationDelegate>
@property(nonatomic, copy) void (^initializationCompleteBlock)(void);
@property(nonatomic, copy) void (^initializationFailedBlock)
    (UnityAdsInitializationError error, NSString *message);
@end

@implementation UnityAdsAdapterInitializationDelegate
- (void)initializationComplete {
  if (self.initializationCompleteBlock) {
    self.initializationCompleteBlock();
  }
}

- (void)initializationFailed:(UnityAdsInitializationError)error
                 withMessage:(nonnull NSString *)message {
  if (self.initializationFailedBlock) {
    self.initializationFailedBlock(error, message);
  }
}
@end

typedef void (^InitCompletionHandler)(NSError *);

@interface GADUnityRouter ()
@property(nonatomic, strong) NSMutableArray *completionBlocks;
@end

@implementation GADUnityRouter

+ (GADUnityRouter *)sharedRouter {
  static GADUnityRouter *sharedRouter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedRouter = [[GADUnityRouter alloc] init];
    sharedRouter.completionBlocks = [NSMutableArray array];
  });
  return sharedRouter;
}

- (void)sdkInitializeWithGameId:(NSString *)gameId
          withCompletionHandler:(InitCompletionHandler)complete {
  if ([UnityAds isInitialized]) {
    if (complete != nil) {
      complete(nil);
    }
    return;
  }
  // If this method was called multiple times from different threads, we want to call all completion
  // handlers once initialization is done.
  if (complete != nil) {
    @synchronized(self.completionBlocks) {
      GADMAdapterUnityMutableArrayAddObject(self.completionBlocks, complete);
    }
  }

  static dispatch_once_t unityInitToken;
  dispatch_once(&unityInitToken, ^{
    GADMAdapterUnityConfigureMediationService();

    UnityAdsAdapterInitializationDelegate *initDelegate =
        [[UnityAdsAdapterInitializationDelegate alloc] init];

    initDelegate.initializationCompleteBlock = ^{
      [[GADUnityRouter sharedRouter] callCompletionBlocks:nil];
    };
    initDelegate.initializationFailedBlock =
        ^(UnityAdsInitializationError error, NSString *message) {
          NSError *adapterError = GADMAdapterUnityErrorWithCodeAndDescription(
              GADMAdapterUnityErrorAdInitializationFailure, message);
          [[GADUnityRouter sharedRouter] callCompletionBlocks:adapterError];
        };
    [UnityAds initialize:gameId testMode:NO initializationDelegate:initDelegate];
  });
}

- (void)callCompletionBlocks:(NSError *)error {
  @synchronized(self.completionBlocks) {
    for (InitCompletionHandler block in self.completionBlocks) {
      block(error);
    }
    [self.completionBlocks removeAllObjects];
  }
}

@end

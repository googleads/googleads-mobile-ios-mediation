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

#import "GADMAdapterUnitySingleton.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"

@interface GADMAdapterUnitySingleton () <UnityAdsExtendedDelegate>

@end

@implementation GADMAdapterUnitySingleton

+ (instancetype)sharedInstance {
  static GADMAdapterUnitySingleton *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [[self alloc] init];
  });
  return sharedManager;
}

- (id)init {
  self = [super init];
    if (self) {
      self.placementsInUse = [[NSMutableSet alloc] init];
    }
  return self;
}

- (void)initializeWithGameID:(NSString *)gameID
                    completeBlock:(UnitySingletonCompletion)completeBlock{
  if ([UnityAds isInitialized]) {
    completeBlock(nil, @"UnityAds Initialization Succeeded");
    return;
  }

  self.completeBlock = completeBlock;
  
  UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
  [mediationMetaData setName:kGADMAdapterUnityMediationNetworkName];
  [mediationMetaData setVersion:kGADMAdapterUnityVersion];
  [mediationMetaData set:@"adapter_version" value:[UnityAds getVersion]];
  [mediationMetaData commit];
  
  [UnityAds addDelegate:self];
  [UnityAds initialize:gameID testMode:false enablePerPlacementLoad:true];
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsPlacementStateChanged:(NSString *)placementId
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
    if ((newState == kUnityAdsPlacementStateWaiting || newState == kUnityAdsPlacementStateReady) && self.completeBlock) {
      self.completeBlock(nil, @"UnityAds Initialization Succeeded");
      self.completeBlock = nil;
    }
}

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(NSString *)message {
    if (error == kUnityAdsErrorNotInitialized || error == kUnityAdsErrorInvalidArgument || error == kUnityAdsErrorInitializedFailed || error == kUnityAdsErrorInitSanityCheckFail) {
        if (self.completeBlock) {
            self.completeBlock(&error, @"Unity Ads Initialization Failed");
            self.completeBlock = nil;
        }
    }
    return;
}

- (void)unityAdsDidFinish:(NSString *)placementID withFinishState:(UnityAdsFinishState)state {
}

- (void)unityAdsDidStart:(NSString *)placementID {
}

- (void)unityAdsReady:(NSString *)placementID {
}

- (void)unityAdsDidClick:(NSString *)placementID {
}

@end

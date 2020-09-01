//
//  GADMUnityInitializationDelegate.m
//  AdMob-TestApp-Local
//
//  Created by Kavya Katooru on 6/25/20.
//  Copyright © 2020 Unity Ads. All rights reserved.
//
// Copyright 2020 Google Inc.
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

#import "GADMUnityInitializationDelegate.h"
#import "GADUnityError.h"
#import "GADMAdapterUnityUtils.h"

@interface GADMUnityInitializationDelegate ()<UnityAdsInitializationDelegate>

@end

@implementation GADMUnityInitializationDelegate

-(nonnull instancetype)initWithCompletionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  self = [super init];
  if (self) {
      initCompletionBlock = completionHandler;
  }
  return self;
}

// UnityAdsInitialization Delegate methods
- (void)initializationComplete {
  NSLog(@"Unity Ads initialized successfully");
  initCompletionBlock(nil);
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(nonnull NSString *)message {
  NSError *err = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdInitializationFailure, message);
  initCompletionBlock(err);
}

@end

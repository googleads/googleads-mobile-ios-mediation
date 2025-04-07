// Copyright 2021 Google LLC
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

#import "GADMAdapterAppLovinInitializer.h"

#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMediationAdapterAppLovin.h"

@implementation GADMAdapterAppLovinInitializer

+ (void)initializeWithSDKKey:(nonnull NSString *)SDKKey
           completionHandler:(nonnull GADMAdapterAppLovinInitCompletionHandler)completionHandler {
  if ([[ALSdk shared] isInitialized]) {
    completionHandler();
    return;
  }

  ALSdkInitializationConfiguration *config = [ALSdkInitializationConfiguration
      configurationWithSdkKey:SDKKey
                 builderBlock:^(ALSdkInitializationConfigurationBuilder *_Nonnull builder) {
                   builder.mediationProvider = ALMediationProviderAdMob;
                   builder.pluginVersion = GADMAdapterAppLovinAdapterVersion;
                 }];

  [[ALSdk shared] initializeWithConfiguration:config
                            completionHandler:^(ALSdkConfiguration *_Nonnull configuration) {
                              [GADMAdapterAppLovinUtils log:@"Finished initializing ALSDK."];
                              completionHandler();
                            }];
}

@end

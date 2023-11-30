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

#import "GADMAdapterVungleRouter.h"
#import <VungleAdsSDK/VungleAdsSDK.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleUtils.h"

static NSString *const _Nonnull GADMAdapterVungleNullPubRequestID = @"null";

@implementation GADMAdapterVungleRouter {
  /// Indicates whether the Vungle SDK is initializing.
  BOOL _isInitializing;

  /// Set to hold any ad delegates to trigger for initialization.
  NSMutableSet<id<GADMAdapterVungleDelegate>> *_delegates;
}

+ (nonnull GADMAdapterVungleRouter *)sharedInstance {
  static GADMAdapterVungleRouter *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[GADMAdapterVungleRouter alloc] init];
  });
  return instance;
}

- (void)initWithAppId:(nonnull NSString *)appId
             delegate:(nullable id<GADMAdapterVungleDelegate>)delegate {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *version = [GADMAdapterVungleVersion stringByReplacingOccurrencesOfString:@"."
                                                                            withString:@"_"];
    [VungleAds setIntegrationName:@"admob" version:version];
  });
  if ([VungleAds isInitialized]) {
    [delegate initialized:YES error:nil];
    return;
  }
  @synchronized(_delegates) {
    GADMAdapterVungleMutableSetAddObject(_delegates, delegate);
  }
  if (_isInitializing) {
    return;
  }

  _isInitializing = YES;
  [VungleAds initWithAppId:appId
                completion:^(NSError *_Nullable error) {
                  self->_isInitializing = NO;
                  @synchronized(self->_delegates) {
                    for (id<GADMAdapterVungleDelegate> del in self->_delegates) {
                      [del initialized:error == nil error:error];
                    }
                    [self->_delegates removeAllObjects];
                  }
                }];
}

@end

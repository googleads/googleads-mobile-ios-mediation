//
// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SampleRewardedAd.h"
#import "SampleRewardedAdController.h"
#import "SampleRewardedAdDelegate.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@implementation SampleRewardedAd

- (instancetype)initWithAdUnitID:(NSString *)adUnit {
  self = [super init];
  if (self) {
    _adUnit = [adUnit copy];
    _ready = NO;
  }
  return self;
}

- (void)fetchAd:(SampleAdRequest *)request {
  if (!self.adUnit) {
    if (self.enableDebugLogging) {
      NSLog(@"Ad fail to load due to ad unit ID missing.");
    }
    [_delegate rewardedAdDidFailToLoadWithError:SampleErrorCodeBadRequest];
  }
  int randomValue = arc4random() % 100;
  if (randomValue < 85) {
    _reward = 5;
    _ready = YES;
    [_delegate rewardedAdDidReceiveAd:self];
  } else if (randomValue < 90) {
    [_delegate rewardedAdDidFailToLoadWithError:SampleErrorCodeUnknown];
  } else if (randomValue < 95) {
    [_delegate rewardedAdDidFailToLoadWithError:SampleErrorCodeNetworkError];
  } else {
    [_delegate rewardedAdDidFailToLoadWithError:SampleErrorCodeNoInventory];
  }
}

- (void)presentFromRootViewController:(UIViewController *)viewController {
  if (![self isReady]) {
    return;
  }
  self.ready = NO;
  SampleRewardedAdController *rewardedAdVC =
      [[SampleRewardedAdController alloc] initWithRewardedAd:self];
  rewardedAdVC.modalPresentationStyle = UIModalPresentationFullScreen;
  rewardedAdVC.delegate = _delegate;
  [viewController presentViewController:rewardedAdVC animated:YES completion:nil];
}

@end

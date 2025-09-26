// Copyright 2025 Google LLC
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

#import "SampleAppOpenAd.h"
#import "SampleAppOpenAdController.h"
#import "SampleAppOpenAdDelegate.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@implementation SampleAppOpenAd

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
    [_delegate appOpenAdDidFailToLoadWithError:SampleErrorCodeBadRequest];
  }
  int randomValue = arc4random() % 100;
  if (randomValue < 85) {
    _ready = YES;
    [_delegate appOpenAdDidReceiveAd:self];
  } else if (randomValue < 90) {
    [_delegate appOpenAdDidFailToLoadWithError:SampleErrorCodeUnknown];
  } else if (randomValue < 95) {
    [_delegate appOpenAdDidFailToLoadWithError:SampleErrorCodeNetworkError];
  } else {
    [_delegate appOpenAdDidFailToLoadWithError:SampleErrorCodeNoInventory];
  }
}

- (void)presentFromRootViewController:(UIViewController *)viewController {
  if (![self isReady]) {
    return;
  }
  self.ready = NO;

  [_delegate appOpenAdWillPresent:self];

  SampleAppOpenAdController *appOpenAdVC =
      [[SampleAppOpenAdController alloc] initWithAppOpenAd:self];
  appOpenAdVC.modalPresentationStyle = UIModalPresentationFullScreen;
  appOpenAdVC.delegate = _delegate;
  [viewController presentViewController:appOpenAdVC animated:YES completion:nil];
}

@end

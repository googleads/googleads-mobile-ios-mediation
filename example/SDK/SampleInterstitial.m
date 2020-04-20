//
// Copyright (C) 2015 Google, Inc.
//
// SampleInterstitial.m
// Sample Ad Network SDK
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

#import "SampleInterstitial.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SampleInterstitial ()
@end

@implementation SampleInterstitial

- (instancetype)initWithAdUnitID:(NSString *)adUnitID {
  self = [super init];
  if (self) {
    _adUnit = adUnitID;
    self.interstitialLoaded = NO;
  }
  return self;
}

- (void)fetchAd:(SampleAdRequest *)request {
  // If the publisher didn't set an ad unit, return a bad request.
  if (!self.adUnit) {
    [self.delegate interstitial:self didFailToLoadAdWithErrorCode:SampleErrorCodeBadRequest];
    return;
  }

  int randomValue = arc4random_uniform(100);
  if (randomValue < 85) {
    self.interstitialLoaded = YES;
    [self.delegate interstitialDidLoad:self];
  } else if (randomValue < 90) {
    [self.delegate interstitial:self didFailToLoadAdWithErrorCode:SampleErrorCodeUnknown];
  } else if (randomValue < 95) {
    [self.delegate interstitial:self didFailToLoadAdWithErrorCode:SampleErrorCodeNetworkError];
  } else {
    [self.delegate interstitial:self didFailToLoadAdWithErrorCode:SampleErrorCodeNoInventory];
  }
}

- (void)show {
  if (!self.isInterstitialLoaded) {
    NSLog(@"Sample interstitial is not ready to show.");
    return;
  }

  // Notify the developer that a full screen view will be presented.
  [self.delegate interstitialWillPresentScreen:self];

  __weak SampleInterstitial *weakSelf = self;
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"Sample Interstitial"
                       message:
                           @"You are viewing a sample interstitial ad.\n\n\nPress Close to dismiss "
                           @"\nthe interstitial or press Click to simulate clicking an interstitial"
                preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *close =
      [UIAlertAction actionWithTitle:@"Close"
                               style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction *action) {
                               SampleInterstitial *strongSelf = weakSelf;
                               [strongSelf.delegate interstitialWillDismissScreen:strongSelf];
                               [strongSelf.delegate interstitialDidDismissScreen:strongSelf];
                             }];
  UIAlertAction *click =
      [UIAlertAction actionWithTitle:@"Click"
                               style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *action) {
                               SampleInterstitial *strongSelf = weakSelf;
                               if (!strongSelf) {
                                 return;
                               }
                               [strongSelf.delegate interstitialWillDismissScreen:strongSelf];
                               [strongSelf.delegate interstitialDidDismissScreen:strongSelf];
                               [strongSelf.delegate interstitialWillLeaveApplication:strongSelf];
                               [[UIApplication sharedApplication]
                                   openURL:[NSURL URLWithString:@"https://www.google.com"]];
                             }];
  [alert addAction:close];
  [alert addAction:click];

  [UIApplication.sharedApplication.keyWindow.rootViewController
      presentViewController:alert
                   animated:YES
                 completion:^(void) {
                   weakSelf.interstitialLoaded = NO;
                 }];
}

@end

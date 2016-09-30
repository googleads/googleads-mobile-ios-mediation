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

@import Foundation;
@import UIKit;

#import "SampleInterstitial.h"

#import "SampleAdRequest.h"

@interface SampleInterstitial () <UIAlertViewDelegate>
@end

@implementation SampleInterstitial

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
  // Notify the developer that a full screen view will be presented.
  [self.delegate interstitialWillPresentScreen:self];

  [[[UIAlertView alloc]
          initWithTitle:@"Sample Interstitial"
                message:@"You are viewing a sample interstitial ad.\n\n\nPress Close to dismiss "
                @"the interstitial or press Click to simulate clicking an interstitial"
               delegate:self
      cancelButtonTitle:@"Close"
      otherButtonTitles:@"Click", nil] show];
  self.interstitialLoaded = NO;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
  [self.delegate interstitialWillDismissScreen:self];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.google.com"]];
    [self.delegate interstitialWillLeaveApplication:self];
  }
  [self.delegate interstitialDidDismissScreen:self];
}

@end

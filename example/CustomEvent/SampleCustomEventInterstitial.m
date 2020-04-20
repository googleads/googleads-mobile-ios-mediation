//
// Copyright (C) 2015 Google, Inc.
//
// SampleCustomEventInsterstitial.m
// Sample Ad Network Custom Event
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

#import "SampleCustomEventInterstitial.h"

/// Constant for Sample Ad Network custom event error domain.
static NSString *const customEventErrorDomain = @"com.google.CustomEvent";

@interface SampleCustomEventInterstitial () <SampleInterstitialAdDelegate>

/// The Sample Ad Network interstitial.
@property(nonatomic, strong) SampleInterstitial *interstitial;

@end

@implementation SampleCustomEventInterstitial
@synthesize delegate;

#pragma mark GADCustomEventInterstitial implementation

- (void)requestInterstitialAdWithParameter:(NSString *)serverParameter
                                     label:(NSString *)serverLabel
                                   request:(GADCustomEventRequest *)request {
  self.interstitial = [[SampleInterstitial alloc] initWithAdUnitID:serverParameter];
  self.interstitial.delegate = self;
  SampleAdRequest *adRequest = [[SampleAdRequest alloc] init];
  adRequest.testMode = request.isTesting;
  adRequest.keywords = request.userKeywords;
  [self.interstitial fetchAd:adRequest];
}

/// Present the interstitial ad as a modal view using the provided view controller.
- (void)presentFromRootViewController:(UIViewController *)rootViewController {
  if ([self.interstitial isInterstitialLoaded]) {
    [self.interstitial show];
  }
}

#pragma mark SampleInterstitialAdDelegate implementation

- (void)interstitialDidLoad:(SampleInterstitial *)interstitial {
  [self.delegate customEventInterstitialDidReceiveAd:self];
}

- (void)interstitial:(SampleInterstitial *)interstitial
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *error = [NSError errorWithDomain:customEventErrorDomain code:errorCode userInfo:nil];
  [self.delegate customEventInterstitial:self didFailAd:error];
}

- (void)interstitialWillPresentScreen:(SampleInterstitial *)interstitial {
  [self.delegate customEventInterstitialWillPresent:self];
}

- (void)interstitialWillDismissScreen:(SampleInterstitial *)interstitial {
  [self.delegate customEventInterstitialWillDismiss:self];
}

- (void)interstitialDidDismissScreen:(SampleInterstitial *)interstitial {
  [self.delegate customEventInterstitialDidDismiss:self];
}

- (void)interstitialWillLeaveApplication:(SampleInterstitial *)interstitial {
  [self.delegate customEventInterstitialWasClicked:self];
  [self.delegate customEventInterstitialWillLeaveApplication:self];
}

@end

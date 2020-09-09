//
// Copyright (C) 2015 Google, Inc.
//
// SampleCustomEventBanner.m
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

#import "SampleCustomEventBanner.h"

#import <Foundation/Foundation.h>
#import <SampleAdSDK/SampleAdSDK.h>

/// Constant for Sample Ad Network custom event error domain.
static NSString *const customEventErrorDomain = @"com.google.CustomEvent";

@interface SampleCustomEventBanner () <SampleBannerAdDelegate>

/// The Sample Ad Network banner.
@property(nonatomic, strong) SampleBanner *bannerAd;

@end

@implementation SampleCustomEventBanner

@synthesize delegate;

#pragma mark GADCustomEventBanner implementation

- (void)requestBannerAd:(GADAdSize)adSize
              parameter:(NSString *)serverParameter
                  label:(NSString *)serverLabel
                request:(GADCustomEventRequest *)request {
  // Create the bannerView with the appropriate size.
  self.bannerAd =
      [[SampleBanner alloc] initWithFrame:CGRectMake(0, 0, adSize.size.width, adSize.size.height)];

  self.bannerAd.delegate = self;
  self.bannerAd.adUnit = serverParameter;
  SampleAdRequest *adRequest = [[SampleAdRequest alloc] init];
  adRequest.testMode = request.isTesting;
  adRequest.keywords = request.userKeywords;
  [self.bannerAd fetchAd:adRequest];
}

#pragma mark SampleBannerAdDelegate implementation

- (void)bannerDidLoad:(SampleBanner *)banner {
  [self.delegate customEventBanner:self didReceiveAd:banner];
}

- (void)banner:(SampleBanner *)banner didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *error = [NSError errorWithDomain:customEventErrorDomain code:errorCode userInfo:nil];
  [self.delegate customEventBanner:self didFailAd:error];
}

- (void)bannerWillLeaveApplication:(SampleBanner *)banner {
  [self.delegate customEventBannerWasClicked:self];
  [self.delegate customEventBannerWillLeaveApplication:self];
}

@end

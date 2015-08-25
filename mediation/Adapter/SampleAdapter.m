//
// Copyright (C) 2015 Google, Inc.
//
// SampleAdapter.m
// Sample Ad Network Adapter
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

@import GoogleMobileAds;

#import "SampleAdapter.h"

#import "GADMAdNetworkConnectorProtocol.h"
#import "GADMEnums.h"
#import "SampleBanner.h"
#import "SampleInterstitial.h"

/// Constant for adapter error domain.
static NSString *const adapterErrorDomain = @"com.google.SampleAdapter";

@interface SampleAdapter () <SampleBannerAdDelegate, SampleInterstitialAdDelegate>
/// Connector from Google Mobile Ads SDK to receive ad configurations.
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
/// Handle banner ads from Sample SDK.
@property(nonatomic, strong) SampleBanner *bannerAd;
/// Handle interstitial ads from Sample SDK.
@property(nonatomic, strong) SampleInterstitial *interstitialAd;
@end

@implementation SampleAdapter

+ (NSString *)adapterVersion {
  return @"1.0";
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  // OPTIONAL: Create your own class implementating GADAdNetworkExtras and return that class type
  // here for your publishers to use. This class does not use extras.

  return Nil;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
  }
  return self;
}

- (void)getInterstitial {
  self.interstitialAd = [[SampleInterstitial alloc] init];
  self.interstitialAd.delegate = self;
  self.interstitialAd.adUnit = [self.connector credentials][@"ad_unit"];

  SampleAdRequest *request = [[SampleAdRequest alloc] init];
  // Setup request parameters.
  request.testMode = self.connector.testMode;
  request.keywords = self.connector.userKeywords;

  [self.interstitialAd fetchAd:request];
  NSLog(@"Requesting interstitial from Sample Ad Network");
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  if (!GADAdSizeEqualToSize(adSize, kGADAdSizeBanner) &&
      !GADAdSizeEqualToSize(adSize, kGADAdSizeMediumRectangle) &&
      !GADAdSizeEqualToSize(adSize, kGADAdSizeFullBanner) &&
      !GADAdSizeEqualToSize(adSize, kGADAdSizeLeaderboard)) {
    NSString *errorDescription =
        [NSString stringWithFormat:@"Invalid ad type %@, not going to get ad.",
                                   NSStringFromGADAdSize(adSize)];
    NSDictionary *errorInfo = [NSDictionary
        dictionaryWithObjectsAndKeys:errorDescription, NSLocalizedDescriptionKey, nil];
    NSError *error = [NSError errorWithDomain:kGADErrorDomain
                                         code:kGADErrorMediationInvalidAdSize
                                     userInfo:errorInfo];
    [self.connector adapter:self didFailAd:error];
    return;
  }
  self.bannerAd =
      [[SampleBanner alloc] initWithFrame:CGRectMake(0, 0, adSize.size.width, adSize.size.height)];

  self.bannerAd.delegate = self;
  self.bannerAd.adUnit = [self.connector credentials][@"ad_unit"];

  // Setup request parameters.
  SampleAdRequest *request = [[SampleAdRequest alloc] init];
  request.testMode = self.connector.testMode;
  request.keywords = self.connector.userKeywords;
  [self.bannerAd fetchAd:request];
  NSLog(@"Requesting banner from Sample Ad Network");
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  if ([self.interstitialAd isInterstitialLoaded]) {
    [self.interstitialAd show];
  }
}

- (void)stopBeingDelegate {
  self.bannerAd.delegate = nil;
  self.interstitialAd.delegate = nil;
}

#pragma mark SampleBannerAdDelegate methods

- (void)bannerDidLoad:(SampleBanner *)banner {
  [self.connector adapter:self didReceiveAdView:banner];
}

- (void)banner:(SampleBanner *)banner didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *adapterError = [NSError errorWithDomain:adapterErrorDomain code:errorCode userInfo:nil];
  [self.connector adapter:self didFailInterstitial:adapterError];
}

- (void)bannerWillLeaveApplication:(SampleBanner *)banner {
  [self.connector adapterDidGetAdClick:self];
  [self.connector adapterWillLeaveApplication:self];
}

#pragma mark SampleInterstitialAdDelegate methods

- (void)interstitialDidLoad:(SampleInterstitial *)interstitial {
  [self.connector adapterDidReceiveInterstitial:self];
}

- (void)interstitial:(SampleInterstitial *)interstitial
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *adapterError = [NSError errorWithDomain:adapterErrorDomain code:errorCode userInfo:nil];
  [self.connector adapter:self didFailInterstitial:adapterError];
}

- (void)interstitialWillPresentScreen:(SampleInterstitial *)interstitial {
  [self.connector adapterWillPresentInterstitial:self];
}

- (void)interstitialWillDismissScreen:(SampleInterstitial *)interstitial {
  [self.connector adapterWillDismissInterstitial:self];
}

- (void)interstitialDidDismissScreen:(SampleInterstitial *)interstitial {
  [self.connector adapterDidDismissInterstitial:self];
}

- (void)interstitialWillLeaveApplication:(SampleInterstitial *)interstitial {
  [self.connector adapterDidGetAdClick:self];
  [self.connector adapterWillLeaveApplication:self];
}

@end

//
// Copyright (C) 2017 Google, Inc.
//
//  AdSourceConfig.m
//  MediationExample
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

#import "AdSourceConfig.h"
#import "../CustomEvent/SampleCustomEventConstants.h"
#import "MediationExample-Swift.h"

NSString *const kCustomEventAppOpenAdUnitID = @"ca-app-pub-3940256099942544/9565801779";
NSString *const kCustomEventBannerAdUnitID = @"ca-app-pub-3940256099942544/2493674513";
NSString *const kCustomEventInterstitialAdUnitID = @"ca-app-pub-3940256099942544/3970407716";
NSString *const kCustomEventRewardedAdUnitID = @"ca-app-pub-3940256099942544/7193106110";
NSString *const kCustomEventRewardedInterstitialAdUnitID =
    @"ca-app-pub-3940256099942544/4447671619";
NSString *const kCustomEventNativeAdUnitID = @"ca-app-pub-3940256099942544/2099734914";
NSString *const kCustomEventSwiftAppOpenAdUnitID = @"ca-app-pub-3940256099942544/5813720025";
NSString *const kCustomEventSwiftBannerAdUnitID = @"ca-app-pub-3940256099942544/5878320677";
NSString *const kCustomEventSwiftInterstitialAdUnitID = @"ca-app-pub-3940256099942544/6597517739";
NSString *const kCustomEventSwiftRewardedAdUnitID = @"ca-app-pub-3940256099942544/4906631573";
NSString *const kCustomEventSwiftRewardedInterstitialAdUnitID =
    @"ca-app-pub-3940256099942544/8877607887";
NSString *const kCustomEventSwiftNativeAdUnitID = @"ca-app-pub-3940256099942544/1645833135";

@implementation AdSourceConfig

+ (instancetype)configWithType:(AdSourceType)adSourceType {
  return [[AdSourceConfig alloc] initWithType:adSourceType];
}

- (instancetype)initWithType:(AdSourceType)adSourceType {
  self = [super init];
  if (self) {
    _adSourceType = adSourceType;
  }
  return self;
}

- (NSString *)appOpenAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventAppOpenAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftAppOpenAdUnitID;
  }
}

- (NSString *)bannerAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventBannerAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftBannerAdUnitID;
  }
}

- (NSString *)interstitialAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventInterstitialAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftInterstitialAdUnitID;
  }
}

- (NSString *)nativeAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventNativeAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftNativeAdUnitID;
  }
}

- (NSString *)rewardedAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventRewardedAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftRewardedAdUnitID;
  }
}

- (NSString *)rewardedInterstitialAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventRewardedInterstitialAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftRewardedInterstitialAdUnitID;
  }
}

- (NSString *)awesomenessKey {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return SampleCustomEventExtraKeyAwesomeness;
    case AdSourceTypeCustomEventSwift:
      return [SampleCustomEventConstantsSwift awesomenessKey];
  }
}

- (NSString *)title {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return @"Objective-C Custom Event";
    case AdSourceTypeCustomEventSwift:
      return @"Swift Custom Event";
  }
}

@end

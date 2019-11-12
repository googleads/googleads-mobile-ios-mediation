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
@import SampleAdSDKAdapter;

NSString *const kCustomEventBannerAdUnitID = @"ca-app-pub-3940256099942544/2493674513";
NSString *const kCustomEventInterstitialAdUnitID = @"ca-app-pub-3940256099942544/3970407716";
NSString *const kCustomEventNativeAdUnitID = @"ca-app-pub-3940256099942544/2099734914";
NSString *const kCustomEventRewardedAdUnitID = @"ca-app-pub-3940256099942544/7193106110";
NSString *const kAdapterBannerAdUnitID = @"ca-app-pub-3940256099942544/5855720519";
NSString *const kAdapterInterstitialAdUnitID = @"ca-app-pub-3940256099942544/8809186917";
NSString *const kAdapterNativeAdUnitID = @"ca-app-pub-3940256099942544/2239335711";
NSString *const kAdapterRewardedAdUnitID = @"ca-app-pub-3940256099942544/2762906516";
NSString *const kCustomEventSwiftBannerAdUnitID = @"ca-app-pub-3940256099942544/5878320677";
NSString *const kCustomEventSwiftInterstitialAdUnitID = @"ca-app-pub-3940256099942544/6597517739";
NSString *const kCustomEventSwiftNativeAdUnitID = @"ca-app-pub-3940256099942544/1645833135";
NSString *const kCustomEventSwiftRewardedAdUnitID = @"ca-app-pub-3940256099942544/4906631573";

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

- (NSString *)bannerAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventBannerAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftBannerAdUnitID;
    case AdSourceTypeAdapter:
      return kAdapterBannerAdUnitID;
  }
}

- (NSString *)interstitialAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventInterstitialAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftInterstitialAdUnitID;
    case AdSourceTypeAdapter:
      return kAdapterInterstitialAdUnitID;
  }
}

- (NSString *)nativeAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventNativeAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftNativeAdUnitID;
    case AdSourceTypeAdapter:
      return kAdapterNativeAdUnitID;
  }
}

- (NSString *)rewardedAdUnitID {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return kCustomEventRewardedAdUnitID;
    case AdSourceTypeCustomEventSwift:
      return kCustomEventSwiftRewardedAdUnitID;
    case AdSourceTypeAdapter:
      return kAdapterRewardedAdUnitID;
  }
}

- (NSString *)awesomenessKey {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return SampleCustomEventExtraKeyAwesomeness;
    case AdSourceTypeCustomEventSwift:
      return [SampleCustomEventConstantsSwift awesomenessKey];
    case AdSourceTypeAdapter:
      return SampleAdapterExtraKeyAwesomeness;
  }
}

- (NSString *)title {
  switch (self.adSourceType) {
    case AdSourceTypeCustomEventObjC:
      return @"Objective-C Custom Event";
    case AdSourceTypeCustomEventSwift:
      return @"Swift Custom Event";
    case AdSourceTypeAdapter:
      return @"SampleAdSDK Adapter";
  }
}

@end

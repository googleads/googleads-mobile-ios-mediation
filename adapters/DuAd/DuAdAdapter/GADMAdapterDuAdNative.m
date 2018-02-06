// Copyright 2016 Google Inc.
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

#import "GADMAdapterDuAdNative.h"

@import DUModuleSDK;

#import "GADDuAdAdapterDelegate.h"
#import "GADDuAdNativeAd.h"
#import "GADDuAdNetworkExtras.h"

@interface GADMAdapterDuAdNative () {
    /// Connector from Google Mobile Ads SDK to receive ad configurations.
    __weak id<GADMAdNetworkConnector> _connector;
    
    /// DuAd Audience Network native ad wrapper.
    GADDuAdNativeAd *_nativeAd;
}
@end

@implementation GADMAdapterDuAdNative

+ (NSString *)adapterVersion {
    return @"1.0.7.1.0";
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    NSLog(@"native -------- networkExtrasClass");
    return [GADDuAdNetworkExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
    NSLog(@"native -------- initWithGADMAdNetworkConnector");
    self = [self init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSLog(@"native -------- initWithGADMAdNetworkConnector----dispatch_once");
            id obj = [connector networkExtras];
            NSLog(@"native -------- initWithGADMAdNetworkConnector----dispatch_once--obj : %@", obj);
            GADDuAdNetworkExtras *networkExtras = [obj isKindOfClass:[GADDuAdNetworkExtras class]] ? obj : nil;
            NSLog(@"native -------- initWithGADMAdNetworkConnector----dispatch_once--networkExtras : %@", networkExtras);
            if (networkExtras) {
                NSLog(@"native -------- initWithGADMAdNetworkConnector----has networkExtras");
                if (networkExtras.appLicense && networkExtras.placementIds) {
                    NSDictionary *nativeIds = [[NSMutableDictionary alloc] init];
                    for (NSString *pid in networkExtras.placementIds) {
                        [nativeIds setValue:pid forKey:@"pid"];
                    }
                    NSDictionary *config = [NSDictionary dictionaryWithObject:nativeIds forKey:@"native"];
                    [DUAdNetwork initWithConfigDic:config withLicense:networkExtras.appLicense];
                    NSLog(@"native -------- initWithGADMAdNetworkConnector----networkExtras.userId : %@, config : %@", networkExtras.appLicense, config);
                }
            }
        });
        _nativeAd = [[GADDuAdNativeAd alloc] initWithGADMAdNetworkConnector:connector adapter:self];
        _connector = connector;
        NSLog(@"native -------- initWithGADMAdNetworkConnector----next step");
    }
    return self;
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
    [_nativeAd getNativeAdWithAdTypes:adTypes options:options];
}

- (void)stopBeingDelegate {
    [_nativeAd stopBeingDelegate];
}

- (void)getInterstitial {
    return;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    return;
}

- (BOOL)handlesUserClicks {
    return YES;
}

- (BOOL)handlesUserImpressions {
    return YES;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
    return;
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
    return YES;
}
@end

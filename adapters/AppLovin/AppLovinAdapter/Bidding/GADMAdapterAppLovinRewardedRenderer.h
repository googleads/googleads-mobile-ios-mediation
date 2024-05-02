// Copyright 2018 Google LLC
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

#import <AppLovinSDK/AppLovinSDK.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// Wrapper for AppLovin's rewarded ad. Used to request and present rewarded ads from AppLovin SDK.
@interface GADMAdapterAppLovinRewardedRenderer : NSObject <GADMediationRewardedAd>

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, copy, nonnull, readonly)
    GADMediationRewardedLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of rewarded presentation events.
@property(nonatomic, weak, nullable) id<GADMediationRewardedAdEventDelegate> delegate;

/// An AppLovin rewarded ad.
@property(nonatomic, nullable) ALAd *ad;

/// The AppLovin zone identifier used to load an ad.
@property(nonatomic, copy, nullable, readonly) NSString *zoneIdentifier;

/// The AdMob UI settings.
@property(nonatomic, copy, nonnull, readonly) NSDictionary<NSString *, id> *settings;

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)handler;
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Request a rewarded ad from AppLovin SDK.
- (void)requestRewardedAd;

@end

//
// Copyright (C) 2015 Google, Inc.
//
// SampleInterstitialAdDelegate.h
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

#import <Foundation/Foundation.h>

#import "SampleAdRequest.h"

@class SampleInterstitial;

@protocol SampleInterstitialAdDelegate<NSObject>

/// Sent when an interstitial ad has loaded.
- (void)interstitialDidLoad:(SampleInterstitial *)interstitial;

/// Sent when banner ad has failed to load.
- (void)interstitial:(SampleInterstitial *)interstitial
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode;

/// Sent when an interstitial is about to be shown.
- (void)interstitialWillPresentScreen:(SampleInterstitial *)interstitial;

/// Sent when an interstitial is about to be dismissed.
- (void)interstitialWillDismissScreen:(SampleInterstitial *)interstitial;

/// Sent when an interstitial has been dismissed.
- (void)interstitialDidDismissScreen:(SampleInterstitial *)interstitial;

/// Sent when an interstitial is clicked and an external application is launched.
- (void)interstitialWillLeaveApplication:(SampleInterstitial *)interstitial;

@end

// Copyright 2025 Google LLC
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

#import "SampleAdRequest.h"
#import "SampleAppOpenAdDelegate.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// The SampleAppOpenAd class is used for requesting and presenting a sample app open ad.
@interface SampleAppOpenAd : NSObject

/// Delegate for receiving app open ad notifications.
@property(nonatomic, weak) id<SampleAppOpenAdDelegate> delegate;

/// The ad unit ID.
@property(readonly, nonatomic, copy) NSString *_Nonnull adUnit;

/// Indicates whether the app open ad is ready to be presented.
@property(nonatomic, getter=isReady) BOOL ready;

/// A flag that indicates whether debug logging is on.
@property(nonatomic) BOOL enableDebugLogging;

/// Initialized an app open ad with the provided ad unit ID.
- (nonnull instancetype)initWithAdUnitID:(NSString *_Nonnull)adUnit;

/// Requests an app open ad and calls the provided completion handler when the request finishes.
- (void)fetchAd:(SampleAdRequest *_Nonnull)request;

/// Present the app open ad on screen.
- (void)presentFromRootViewController:(UIViewController *_Nonnull)viewController;

@end

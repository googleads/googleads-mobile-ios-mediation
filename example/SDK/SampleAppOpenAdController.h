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

#import <UIKit/UIKit.h>

#import "SampleAppOpenAd.h"
#import "SampleAppOpenAdDelegate.h"

/// This is an app open ad. This class initializes with SampleAppOpenAd instance.
@interface SampleAppOpenAdController : UIViewController

/// Designated initializer.
- (nonnull instancetype)initWithAppOpenAd:(nonnull SampleAppOpenAd *)appOpenAd
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Unavailable.
- (nonnull instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                                 bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/// Unavailable.
- (nonnull instancetype)initWithCoder:(nonnull NSCoder *)aDecoder NS_UNAVAILABLE;

/// Sample app open ad delegate.
@property(nonatomic, weak) id<SampleAppOpenAdDelegate> delegate;

@end

//
// Copyright (C) 2015 Google, Inc.
//
// SampleBanner.h
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
#import <UIKit/UIKit.h>

#import "SampleAdRequest.h"
#import "SampleBannerAdDelegate.h"

@interface SampleBanner : UILabel

/// Identifier for banner ad placement.
@property(nonatomic, copy) NSString *adUnit;

/// Delegate object that receives state change notifications.
@property(nonatomic, weak) id<SampleBannerAdDelegate> delegate;

/// Request a banner ad.
- (void)fetchAd:(SampleAdRequest *)request;

@end

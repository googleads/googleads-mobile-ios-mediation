// Copyright 2017 Google LLC
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

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

typedef NS_ENUM(NSInteger, GADMAdapterNendInterstitialType) {
  GADMAdapterNendInterstitialTypeNormal = 1,  // << nend normal interstitial ad type
  GADMAdapterNendInterstitialTypeVideo = 2,   // << nend interstitial video ad type
};

typedef NS_ENUM(NSInteger, GADMAdapterNendNativeType) {
  GADMAdapterNendNativeTypeNormal = 1,  // << nend normal native ad type
  GADMAdapterNendNativeTypeVideo = 2,   // << nend native video ad type
};

/// Network extras for the nend adapter.
@interface GADMAdapterNendExtras : NSObject <GADAdNetworkExtras>

/// nend interstitial ad type.
@property(nonatomic) GADMAdapterNendInterstitialType interstitialType;

/// nend native ad type.
@property(nonatomic) GADMAdapterNendNativeType nativeType;

/// nend user ID.
@property(nonatomic, copy) NSString *userId;

@end

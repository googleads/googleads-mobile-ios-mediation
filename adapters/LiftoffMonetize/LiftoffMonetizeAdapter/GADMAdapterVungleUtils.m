// Copyright 2019 Google LLC
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

#import "GADMAdapterVungleUtils.h"
#import "GADMAdapterVungleConstants.h"

NSError *_Nonnull GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorCode code,
                                                               NSString *_Nonnull description) {
  NSDictionary<NSString *, NSString *> *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterVungleErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

const CGSize kVNGBannerShortSize = {300, 50};
GADAdSize GADMAdapterVungleAdSizeForAdSize(GADAdSize adSize, NSString *_Nonnull placementId) {
    if ([VungleAds isInLine:placementId]) {
        return adSize;
    }
  if (adSize.size.height >= GADAdSizeMediumRectangle.size.height &&
      adSize.size.width >= GADAdSizeMediumRectangle.size.width) {
    return GADAdSizeMediumRectangle;
  }

  // An array of supported ad sizes.
  GADAdSize shortBannerSize = GADAdSizeFromCGSize(kVNGBannerShortSize);
  NSArray<NSValue *> *potentials = @[
    NSValueFromGADAdSize(GADAdSizeBanner), NSValueFromGADAdSize(GADAdSizeLeaderboard),
    NSValueFromGADAdSize(shortBannerSize)
  ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(adSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.height == GADAdSizeBanner.size.height) {
    if (size.width < GADAdSizeBanner.size.width) {
      return shortBannerSize;
    } else {
      return GADAdSizeBanner;
    }
  } else if (size.height == GADAdSizeLeaderboard.size.height) {
    return GADAdSizeLeaderboard;
  }
  return GADAdSizeInvalid;
}

VungleAdSize *_Nonnull GADMAdapterVungleConvertGADAdSizeToBannerSize(GADAdSize adSize) {
    // MREC
    if (GADAdSizeEqualToSize(adSize, GADAdSizeMediumRectangle)) {
      return VungleAdSize.VungleAdSizeMREC;
    }
    // LeaderBoard
    if (GADAdSizeEqualToSize(adSize, GADAdSizeLeaderboard)) {
      return VungleAdSize.VungleAdSizeLeaderboard;
    }
    //BannerRegular
    if (GADAdSizeEqualToSize(adSize, GADAdSizeBanner)) {
      return VungleAdSize.VungleAdSizeBannerRegular;
    }
    //BannerShort
    GADAdSize shortBannerSize = GADAdSizeFromCGSize(kVNGBannerShortSize);
    if (GADAdSizeEqualToSize(adSize, shortBannerSize)) {
      return VungleAdSize.VungleAdSizeBannerShort;
    }
    //Custom size
    return [VungleAdSize VungleAdSizeFromCGSize:adSize.size];
}

VungleAdSize *_Nonnull GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSize adSize, NSString *_Nonnull placementId) {
    return [VungleAdSize VungleValidAdSizeFromCGSizeWithSize:adSize.size placementId:placementId];
}

@implementation GADMAdapterVungleUtils

+ (nonnull NSString *)findAppID:(nullable NSDictionary *)serverParameters {
  NSString *appId = serverParameters[GADMAdapterVungleApplicationID];
  if (!appId) {
    NSString *const message = @"Liftoff Monetize app ID should be specified!";
    NSLog(message);
    return @"";
  }
  return appId;
}

+ (nonnull NSString *)findPlacement:(nullable NSDictionary *)serverParameters {
  NSString *placementId = serverParameters[GADMAdapterVunglePlacementID];
  return placementId ? placementId : @"";
}

#pragma mark - Safe Collection utility methods.

void GADMAdapterVungleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

@end

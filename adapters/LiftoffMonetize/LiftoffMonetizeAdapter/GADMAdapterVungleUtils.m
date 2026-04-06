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

#import <VungleAdsSDK/VungleAdsSDK.h>

NSError *_Nonnull GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorCode code,
                                                               NSString *_Nonnull description) {
  NSDictionary<NSString *, NSString *> *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterVungleErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

VungleAdSize *_Nonnull GADMAdapterVungleConvertGADAdSizeToVungleAdSize(
    GADAdSize adSize, NSString *_Nonnull placementId) {
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

+ (void)updateVungleCOPPAStatusIfNeeded {
  NSNumber *tagForChildDirectedTreatment =
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  NSNumber *tagForUnderAgeOfConsent =
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent;
  if ([tagForChildDirectedTreatment isEqual:@YES] || [tagForUnderAgeOfConsent isEqual:@YES]) {
    [VunglePrivacySettings setCOPPAStatus:YES];
  } else if ([tagForChildDirectedTreatment isEqual:@NO] || [tagForUnderAgeOfConsent isEqual:@NO]) {
    [VunglePrivacySettings setCOPPAStatus:NO];
  }
}

+ (void)logCustomSizeForBannerPlacement:(NSString *_Nonnull)placementId
                                 adSize:(GADAdSize)adSize
                           bannerViewAd:(VungleBannerView *_Nullable)adViewAd {
  // Size not supported for non-inline placements — may include GADAdSizeLargeBanner (320x100),
  // GADAdSizeFullBanner (468x60), GADAdSizeSkyscraper (120x600), GADAdSizeFluid,
  // GADAdSizeInvalid, or a custom size.
  if (![VungleAds isInLine:placementId] &&
      !GADAdSizeEqualToSize(adSize, GADAdSizeBanner) &&           // 320x50
      !GADAdSizeEqualToSize(adSize, GADAdSizeMediumRectangle) &&  // 300x250
      !GADAdSizeEqualToSize(adSize, GADAdSizeLeaderboard)) {      // 728x90
    adViewAd.adapterAdFormat = [adViewAd.adapterAdFormat stringByAppendingString:@"-custom"];
    NSString *customSizeMismatchMessage =
        [NSString stringWithFormat:@"CustomBannerSizeMismatch:w-%.0f|h-%.0f", adSize.size.width,
                                   adSize.size.height];
    [VungleMediationLogger logErrorForAd:adViewAd message:customSizeMismatchMessage];
    NSLog(@"Banner size is unsupported for non-inline Liftoff placements. "
          @"Use a Liftoff inline placement ID to serve this banner size: placementId=%@ adSize=%@",
          placementId, NSStringFromGADAdSize(adSize));
  }
}

#pragma mark - Safe Collection utility methods.

void GADMAdapterVungleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

@end

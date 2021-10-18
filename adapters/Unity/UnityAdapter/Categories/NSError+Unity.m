//
//  NSError+Unity.m
//  AdMob-TestApp-Local
//
//  Created by Vita Solomina on 2021-10-18.
//  Copyright © 2021 Unity Ads. All rights reserved.
//

#import "NSError+Unity.h"
#import "GADMAdapterUnityUtils.h"
#import "GADMAdapterUnityConstants.h"

@implementation NSError (Unity)
+ (NSError*)noValidGameId {
    return GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorInvalidServerParameters, @"UnityAds mediation configurations did not contain a valid game ID.");
}

+ (NSError *)unsupportedBannerGADAdSize:(GADAdSize)adSize {
    NSString *errorMsg = [NSString stringWithFormat: @"UnityAds supported banner sizes are not a good fit for the requested size: %@", NSStringFromGADAdSize(adSize)];
    return GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorSizeMismatch, errorMsg);
}

+ (NSError *)adNotAvailablePerPlacement:(NSString*)placementId {
    NSString *errorMsg = [NSString stringWithFormat:@"No ad available for the placement ID: %@", placementId];
    return GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorPlacementStateNoFill, errorMsg);
}
@end

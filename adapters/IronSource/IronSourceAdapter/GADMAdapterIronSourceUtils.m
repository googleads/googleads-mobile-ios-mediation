// Copyright 2019 Google Inc.
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

#import "GADMAdapterIronSourceUtils.h"
#import "GADMAdapterIronSourceConstants.h"

void GADMAdapterIronSourceMutableSetAddObject(NSMutableSet *_Nullable set,
                                              NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

void GADMAdapterIronSourceMapTableSetObjectForKey(NSMapTable *_Nullable mapTable,
                                                  id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

void GADMAdapterIronSourceMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable,
                                                     id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterIronSourceErrorWithCodeAndDescription(
    GADMAdapterIronSourceErrorCode code, NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

@implementation GADMAdapterIronSourceUtils

#pragma mark Utils Methods

+ (BOOL)isEmpty:(nullable id)value {
  return value == nil || [value isKindOfClass:[NSNull class]] ||
         ([value respondsToSelector:@selector(length)] && [(NSString *)value length] == 0) ||
         ([value respondsToSelector:@selector(length)] && [(NSData *)value length] == 0) ||
         ([value respondsToSelector:@selector(count)] && [(NSArray *)value count] == 0);
}

+ (void)onLog:(nonnull NSString *)log {
  NSLog(@"IronSourceAdapter: %@", log);
}

+ (nonnull NSString *)getAdMobSDKVersion {
  return [NSString stringWithFormat:@"v%ld%ld%ld",
                                    GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                    GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                    GADMobileAds.sharedInstance.versionNumber.patchVersion];
}

+ (nullable ISBannerSize *)ironSourceAdSizeFromRequestedSize:(GADAdSize)size {
  GADAdSize banner = GADAdSizeBanner;
  GADAdSize rectangle = GADAdSizeMediumRectangle;
  GADAdSize large = GADAdSizeLargeBanner;

  NSArray<NSValue *> *potentials = @[
    NSValueFromGADAdSize(banner), NSValueFromGADAdSize(rectangle), NSValueFromGADAdSize(large)
  ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(size, potentials);
  CGSize closestCGSize = CGSizeFromGADAdSize(closestSize);
  if (CGSizeEqualToSize(CGSizeFromGADAdSize(banner), closestCGSize)) {
    return ISBannerSize_BANNER;
  }
  if (CGSizeEqualToSize(CGSizeFromGADAdSize(large), closestCGSize)) {
    return ISBannerSize_LARGE;
  }
  if (CGSizeEqualToSize(CGSizeFromGADAdSize(rectangle), closestCGSize)) {
    return ISBannerSize_RECTANGLE;
  }

  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"Unable to retrieve IronSource size from GADAdSize: %@",
                                       NSStringFromGADAdSize(size)]];

  return nil;
}

+ (NSArray<ISAAdFormat *> *_Nullable)adFormatsToInitializeForAdUnits:(nonnull NSSet *)adUnits
{
    NSMutableArray<ISAAdFormat *> *adFormatsToInitialize = [NSMutableArray array];
    
    if ([adUnits member:IS_INTERSTITIAL] != nil)
    {
        ISAAdFormat *interstitial = [[ISAAdFormat alloc] initWithAdFormatType: ISAAdFormatTypeInterstitial];
        [adFormatsToInitialize addObject: interstitial];
    }
    
    if ([adUnits member:IS_REWARDED_VIDEO] != nil)
    {
        ISAAdFormat *rewarded = [[ISAAdFormat alloc] initWithAdFormatType: ISAAdFormatTypeRewarded];
        [adFormatsToInitialize addObject: rewarded];
    }
    
    if ([adUnits member:IS_BANNER] != nil)
    {
        ISAAdFormat *banner = [[ISAAdFormat alloc] initWithAdFormatType: ISAAdFormatTypeBanner];
        [adFormatsToInitialize addObject: banner];
    }
    
    return [adFormatsToInitialize copy];
}

+ (nonnull NSMutableDictionary<NSString *, NSString *> *)getExtraParamsWithWatermark:(nullable NSData *)watermarkData {
    NSMutableDictionary<NSString *, NSString *> *extraParams = [[NSMutableDictionary alloc] init];
    
    if (watermarkData != nil) {
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        if (watermarkString){
            [extraParams setObject:watermarkString forKey:GADMAdapterIronSourceWatermark];
        }
    }
    return extraParams;
}

@end

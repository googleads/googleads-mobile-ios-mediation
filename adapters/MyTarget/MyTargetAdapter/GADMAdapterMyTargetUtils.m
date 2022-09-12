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

#import "GADMAdapterMyTargetUtils.h"

#import "GADMAdapterMyTargetConstants.h"

#import "GADMediationAdapterMyTarget.h"

#import "GADMAdapterMyTargetExtras.h"

void GADMAdapterMyTargetMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                         id<NSCopying> _Nullable key,
                                                         id _Nullable value) {
  if (value && key) {
    dictionary[key] = value;  // Allow pattern.
  }
}

void GADMAdapterMyTargetMutableDictionaryRemoveObjectForKey(
    NSMutableDictionary *_Nonnull dictionary, id _Nullable key) {
  if (key) {
    [dictionary removeObjectForKey:key];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterMyTargetSDKErrorWithDescription(NSString *_Nonnull description) {
  NSDictionary<NSString *, id> *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  return [NSError errorWithDomain:GADMAdapterMyTargetSDKErrorDomain code:0 userInfo:userInfo];
}

NSError *_Nonnull GADMAdapterMyTargetAdapterErrorWithDescription(NSString *_Nonnull description) {
  NSDictionary<NSString *, id> *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  return [NSError errorWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                             code:1000
                         userInfo:userInfo];
}

NSError *_Nonnull GADMAdapterMyTargetErrorWithCodeAndDescription(GADMAdapterMyTargetErrorCode code,
                                                                 NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

void GADMAdapterMyTargetFillCustomParams(MTRGCustomParams *_Nonnull customParams,
                                         id<GADAdNetworkExtras> _Nullable networkExtras) {
  if (!networkExtras || ![networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]]) return;

  GADMAdapterMyTargetExtras *adapterExtras = (GADMAdapterMyTargetExtras *)networkExtras;
  NSDictionary<NSString *, NSString *> *parameters = adapterExtras.parameters;
  if (!parameters) return;

  for (NSString *key in parameters.allKeys) {
    NSString *value = parameters[key];
    [customParams setCustomParam:value forKey:key];
  }
}

NSUInteger GADMAdapterMyTargetSlotIdFromCredentials(
    NSDictionary<NSString *, id> *_Nullable credentials) {
  id slotIdValue = credentials[GADMAdapterMyTargetSlotIdKey];
  if (!slotIdValue) {
    return 0;
  }

  if ([slotIdValue isKindOfClass:[NSString class]]) {
    NSNumberFormatter *formatString = [[NSNumberFormatter alloc] init];
    NSString *slotIdString = (NSString *)slotIdValue;
    NSNumber *slotIdNumber = [formatString numberFromString:slotIdString];
    return (slotIdNumber ? slotIdNumber.unsignedIntegerValue : 0);
  } else if ([slotIdValue isKindOfClass:[NSNumber class]]) {
    NSNumber *slotIdNumber = (NSNumber *)slotIdValue;
    return slotIdNumber.unsignedIntegerValue;
  }
  return 0;
}

GADNativeAdImage *_Nullable GADMAdapterMyTargetNativeAdImageWithImageData(
    MTRGImageData *_Nullable imageData) {
  if (!imageData) {
    return nil;
  }

  GADNativeAdImage *nativeAdImage = nil;
  if (imageData.image) {
    nativeAdImage = [[GADNativeAdImage alloc] initWithImage:imageData.image];
  } else if (imageData.url) {
    NSURL *url = [NSURL URLWithString:imageData.url];
    nativeAdImage = [[GADNativeAdImage alloc] initWithURL:url scale:1.0];
  }
  return nativeAdImage;
}

MTRGAdSize *_Nullable GADMAdapterMyTargetSizeFromRequestedSize(
    GADAdSize gadAdSize, NSError *_Nullable __autoreleasing *_Nullable error) {
  /// Find closest supported ad size from a given ad size.
  MTRGAdSize *adSizeAdaptive =
      [MTRGAdSize adSizeForCurrentOrientationForWidth:gadAdSize.size.width];
  GADAdSize gadAdSizeAdaptive = GADAdSizeFromCGSize(adSizeAdaptive.size);
  NSArray<NSValue *> *potentials = @[
    NSValueFromGADAdSize(GADAdSizeBanner), NSValueFromGADAdSize(GADAdSizeMediumRectangle),
    NSValueFromGADAdSize(GADAdSizeLeaderboard), NSValueFromGADAdSize(gadAdSizeAdaptive)
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  if (GADAdSizeEqualToSize(closestSize, GADAdSizeBanner)) {
    return [MTRGAdSize adSize320x50];
  } else if (GADAdSizeEqualToSize(closestSize, GADAdSizeMediumRectangle)) {
    return [MTRGAdSize adSize300x250];
  } else if (GADAdSizeEqualToSize(closestSize, GADAdSizeLeaderboard)) {
    return [MTRGAdSize adSize728x90];
  } else {
    CGFloat width = closestSize.size.width;
    CGFloat height = closestSize.size.height;
    if (width > 0 && height >= GADMAdapterMyTargetBannerHeightMin &&
        height < GADMAdapterMyTargetBannerAspectRatioMin * width) {
      // Adaptive
      return [MTRGAdSize adSizeForCurrentOrientationForWidth:width];
    }
  }
  if (error) {
    NSString *description =
        [NSString stringWithFormat:@"MyTarget's supported banner sizes are not valid for the "
                                   @"requested ad size. Requested ad size: %@",
                                   NSStringFromGADAdSize(gadAdSize)];
    *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorBannerSizeMismatch, description);
  }
  return nil;
}

@implementation GADMAdapterMyTargetUtils

static BOOL _isLogEnabled = YES;

+ (BOOL)logEnabled {
  return _isLogEnabled;
}

+ (void)setLogEnabled:(BOOL)logEnabled {
  _isLogEnabled = logEnabled;
}

@end

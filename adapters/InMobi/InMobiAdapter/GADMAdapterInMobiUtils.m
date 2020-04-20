//
//  GADMAdapterInMobiUtils.m
//  Adapter
//  Copyright © 2019 Google. All rights reserved.
//

#import "GADMAdapterInMobiUtils.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK.h>

#include <stdatomic.h>

#import "GADMAdapterInMobiConstants.h"

NSInteger GADMAdapterInMobiAdMobErrorCodeForInMobiCode(NSInteger inMobiErrorCode) {
  NSInteger errorCode;
  switch (inMobiErrorCode) {
    case kIMStatusCodeNoFill:
      errorCode = kGADErrorNoFill;
      break;
    case kIMStatusCodeRequestTimedOut:
      errorCode = kGADErrorTimeout;
      break;
    case kIMStatusCodeServerError:
      errorCode = kGADErrorServerError;
      break;
    case kIMStatusCodeInternalError:
      errorCode = kGADErrorInternalError;
      break;
    default:
      errorCode = kGADErrorInternalError;
      break;
  }
  return errorCode;
}

void GADMAdapterInMobiMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

void GADMAdapterInMobiMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                              id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

void GADMAdapterInMobiMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

void GADMAdapterInMobiMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                       id<NSCopying> _Nullable key,
                                                       id _Nullable value) {
  if (value && key) {
    dictionary[key] = value;  // Allow pattern.
  }
}

void GADMAdapterInMobiCacheSetObjectForKey(NSCache *_Nonnull cache, id<NSCopying> _Nullable key,
                                           id _Nullable value) {
  if (value && key) {
    [cache setObject:value forKey:key];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterInMobiErrorWithCodeAndDescription(NSInteger code,
                                                               NSString *_Nonnull description) {
  NSDictionary<NSString *, NSString *> *errorInfo = @{NSLocalizedDescriptionKey : description};
  return [NSError errorWithDomain:kGADMAdapterInMobiErrorDomain code:code userInfo:errorInfo];
}

NSError *_Nullable GADMAdapterInMobiValidatePlacementIdentifier(
    NSNumber *_Nonnull placementIdentifier) {
  if (placementIdentifier.longLongValue) {
    return nil;
  }

  return GADMAdapterInMobiErrorWithCodeAndDescription(
      kGADErrorInvalidRequest, @"[InMobi] Error - Placement ID not specified.");
}

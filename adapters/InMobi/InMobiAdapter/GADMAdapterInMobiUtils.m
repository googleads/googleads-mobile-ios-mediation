//
//  GADMAdapterInMobiUtils.m
//  Adapter
//  Copyright © 2019 Google. All rights reserved.
//

#import "GADMAdapterInMobiUtils.h"
@import InMobiSDK;

void GADMAdapterInMobiMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];
  }
}

@implementation GADMAdapterInMobiUtils

// Convert InMobi Error codes to Google's

+ (NSInteger)getAdMobErrorCode:(NSInteger)inmobiErrorCode {
  NSInteger errorCode;
  switch (inmobiErrorCode) {
    case kIMStatusCodeNoFill:
      errorCode = kGADErrorMediationNoFill;
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

@end

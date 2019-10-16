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

#import "GADMAdapterIMobileHelper.h"

@implementation GADMAdapterIMobileHelper

/// Create NSError from descritption.
+ (NSError *)errorWithDescritption:(NSString *)descritption
                              code:(NSInteger)code {

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:descritption, NSLocalizedDescriptionKey, nil];
    return [NSError errorWithDomain:@"com.google.mediation.imobile" code:code userInfo:userInfo];
}

/// Convert i-mobile fail result to AdMob error code.
+ (NSInteger)getAdMobErrorWithIMobileResult:(ImobileSdkAdsFailResult)iMobileResult {
    switch (iMobileResult) {
        case IMOBILESDKADS_ERROR_PARAM:
        case IMOBILESDKADS_ERROR_AUTHORITY:
            return kGADErrorInvalidArgument;
        case IMOBILESDKADS_ERROR_RESPONSE:
        case IMOBILESDKADS_ERROR_UNKNOWN:
            return kGADErrorInternalError;
        case IMOBILESDKADS_ERROR_NETWORK_NOT_READY:
        case IMOBILESDKADS_ERROR_NETWORK:
            return kGADErrorNetworkError;
        case IMOBILESDKADS_ERROR_AD_NOT_READY:
        case IMOBILESDKADS_ERROR_NOT_FOUND:
            return kGADErrorMediationNoFill;
        case IMOBILESDKADS_ERROR_SHOW_TIMEOUT:
            return kGADErrorTimeout;
        default:
            return kGADErrorInternalError;
    }
}

@end

//
//  Copyright © 2018 Google. All rights reserved.
//

#import <AdColony/AdColony.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

typedef NS_ENUM(NSInteger, GADMAdapterAdColonyErrorCode) {
  /// Missing server parameters.
  GADMAdapterAdColonyErrorMissingServerParameters = 101,
  /// Root view controller is nil.
  GADMAdapterAdColonyErrorRootViewControllerNil = 102,
  /// The AdColony SDK returned an initialization error.
  GADMAdapterAdColonyErrorInitialization = 103,
  /// The AdColony SDK does not support being configured twice within a five second period.
  GADMAdapterAdColonyErrorConfigureRateLimit = 104,
  /// Failed to show ad.
  GADMAdapterAdColonyErrorShow = 105,
  /// Zone used for rewarded video is not a rewarded video zone on AdColony portal.
  GADMAdapterAdColonyErrorZoneNotRewarded = 106
};

@interface GADMediationAdapterAdColony : NSObject <GADRTBAdapter>

@property(class, nonatomic, strong, readonly) AdColonyAppOptions *appOptions;

@end

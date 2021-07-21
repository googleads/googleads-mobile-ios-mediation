//
//  GADMediationAdapterVerizon.h
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMAdapterVerizonBaseClass.h"

typedef NS_ENUM(NSInteger, GADMAdapterVerizonErrorCode) {
  /// Missing server parameters.
  GADMAdapterVerizonErrorInvalidServerParameters = 101,
  /// Banner Size Mismatch.
  GADMAdapterVerizonErrorBannerSizeMismatch = 102,
  /// The Verizon SDK returned an initialization error.
  GADMAdapterVerizonErrorInitialization = 103
};

@interface GADMediationAdapterVerizon : GADMAdapterVerizonBaseClass <GADMediationAdapter>

@end

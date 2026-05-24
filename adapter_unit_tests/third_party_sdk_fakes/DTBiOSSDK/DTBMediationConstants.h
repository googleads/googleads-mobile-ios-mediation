#import <Foundation/Foundation.h>

#ifndef DTBMediationConstants_h
#define DTBMediationConstants_h

typedef NS_ENUM(NSInteger, DTBAdErrorCode) {
  SampleErrorCodeBadRequest,    ///< Bad request.
  SampleErrorCodeUnknown,       ///< Unknown error.
  SampleErrorCodeNetworkError,  ///< Network error.
  SampleErrorCodeNoInventory,   ///< No inventory.
};

#endif /* DTBMediationConstants_h */
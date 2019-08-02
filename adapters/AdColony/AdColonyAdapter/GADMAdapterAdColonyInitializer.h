//
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;
#import <AdColony/AdColony.h>

#define DEBUG_LOGGING 0

#if DEBUG_LOGGING
#define NSLogDebug(...) NSLog(__VA_ARGS__)
#else
#define NSLogDebug(...)
#endif

typedef enum {
  INIT_STATE_UNINITIALIZED,
  INIT_STATE_INITIALIZED,
  INIT_STATE_INITIALIZING
} AdColonyAdapterInitState;

@interface GADMAdapterAdColonyInitializer : NSObject

+ (instancetype)sharedInstance;

- (void)initializeAdColonyWithAppId:(NSString *)appId
                              zones:(NSArray *)newZones
                            options:(AdColonyAppOptions *)options
                           callback:(void (^)(NSError *))callback;

@end

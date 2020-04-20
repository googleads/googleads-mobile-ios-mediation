//
//  Copyright © 2018 Google. All rights reserved.
//

#import <AdColony/AdColony.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// AdColony SDK init state.
typedef NS_ENUM(NSInteger, GADMAdapterAdColonyInitState) {
  GADMAdapterAdColonyInitStateUninitialized,  ///< AdColony SDK is not initialized.
  GADMAdapterAdColonyInitStateInitializing,   ///< AdColony SDK is initializing.
  GADMAdapterAdColonyInitStateInitialized     ///< AdColony SDK is initialized.
};

/// AdColony adapter initialization completion handler.
typedef void (^GADMAdapterAdColonyInitCompletionHandler)(NSError *_Nullable error);

@interface GADMAdapterAdColonyInitializer : NSObject

/// The shared GADMAdapterAdColonyInitializer instance.
@property(class, atomic, readonly, nonnull) GADMAdapterAdColonyInitializer *sharedInstance;

/// Initializes AdColony SDK with the provided app ID, zone IDs and AdColonyAppOptions.
- (void)initializeAdColonyWithAppId:(nonnull NSString *)appId
                              zones:(nonnull NSArray<NSString *> *)newZones
                            options:(nonnull AdColonyAppOptions *)options
                           callback:(nonnull GADMAdapterAdColonyInitCompletionHandler)callback;

@end

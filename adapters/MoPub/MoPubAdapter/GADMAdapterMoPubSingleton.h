#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "GADMAdapterMoPubConstants.h"
#import "MPRewardedVideo.h"
#import "MoPub.h"

@interface GADMAdapterMoPubSingleton : NSObject

/// Shared instance.
@property(class, atomic, readonly, nonnull) GADMAdapterMoPubSingleton *sharedInstance;

/// Initializes MoPub SDK.
- (void)initializeMoPubSDKWithAdUnitID:(nonnull NSString *)adUnitID
                     completionHandler:(void (^_Nullable)(void))completionHandler;

/// Requests rewarded ads from MoPub SDK.
- (nullable NSError *)
    requestRewardedAdForAdUnitID:(nonnull NSString *)adUnitID
                        adConfig:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                        delegate:(nonnull id<MPRewardedVideoDelegate>)delegate;

@end

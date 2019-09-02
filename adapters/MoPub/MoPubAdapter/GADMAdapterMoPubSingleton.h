
#import <Foundation/Foundation.h>
#import "MPRewardedVideo.h"
#import "MoPub.h"
#import "MoPubAdapterConstants.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterMoPubSingleton : NSObject

+ (nonnull instancetype)sharedInstance;

- (void)initializeMoPubSDKWithAdUnitID:(nonnull NSString *)adUnitID
                     completionHandler:(void (^_Nullable)(void))completionHandler;
- (nullable NSError *)requestRewardedAdForAdUnitID:(nonnull NSString *)adUnitID
                                 adConfig:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                                 delegate:(nonnull id<MPRewardedVideoDelegate>)delegate;

@end

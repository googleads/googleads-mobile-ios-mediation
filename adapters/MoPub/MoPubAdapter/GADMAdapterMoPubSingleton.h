
#import <Foundation/Foundation.h>
#import "MPRewardedVideo.h"
#import "MoPub.h"
#import "MoPubAdapterConstants.h"
@import GoogleMobileAds;

@interface GADMAdapterMoPubSingleton : NSObject

+ (instancetype)sharedInstance;

- (void)initializeMoPubSDKWithAdUnitID:(NSString *)adUnitID
                     completionHandler:(void (^_Nullable)(void))completionHandler;
- (NSError *)requestRewardedAdForAdUnitID:(NSString *)adUnitID
                                 adConfig:(GADMediationRewardedAdConfiguration *)adConfig
                                 delegate:(id<MPRewardedVideoDelegate>)delegate;

@end

#import <Foundation/Foundation.h>
@import GoogleMobileAds;

@interface GADMAdapterVungleRewardedAd : NSObject<GADMediationRewardedAd>

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)handler;
- (nonnull instancetype)init NS_UNAVAILABLE;

- (void)requestRewardedAd;

@end

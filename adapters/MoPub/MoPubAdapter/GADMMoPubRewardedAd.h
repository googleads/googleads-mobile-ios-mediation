
#import <Foundation/Foundation.h>
@import GoogleMobileAds;

@interface GADMMoPubRewardedAd : NSObject <GADMediationRewardedAd>

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler;
@end

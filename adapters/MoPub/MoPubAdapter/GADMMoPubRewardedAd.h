
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMMoPubRewardedAd : NSObject <GADMediationRewardedAd>

- (void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler;
@end

//
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;

@interface GADMAdapterAdColonyRewardedAd : NSObject <GADMediationRewardedAd>

/// Render a rewarded ad with the provided ad configuration.
- (void)renderRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                         completionHandler:(GADRewardedLoadCompletionHandler)completionHandler;

@end

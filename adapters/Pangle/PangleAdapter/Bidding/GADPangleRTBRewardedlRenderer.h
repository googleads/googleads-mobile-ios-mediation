//
//  GADPangleRTBRewardedlRenderer.h
//  PangleAdapter
//
//  Created by bytedance on 2022/1/11.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADPangleRTBRewardedlRenderer : NSObject<GADMediationRewardedAd>

/// Asks the receiver to render the ad configuration.
- (void)renderRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END

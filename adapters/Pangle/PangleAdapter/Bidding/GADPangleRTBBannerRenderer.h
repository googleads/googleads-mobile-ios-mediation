//
//  GADPangleRTBBannerRenderer.h
//  PangleAdapter
//
//  Created by bytedance on 2022/1/11.
//

#import <Foundation/Foundation.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADPangleRTBBannerRenderer : NSObject<GADMediationBannerAd>

/// Asks the receiver to render the ad configuration.
- (void)renderBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:
                       (nonnull GADMediationBannerLoadCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END


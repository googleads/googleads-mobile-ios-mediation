//
//  GADPangleRTBAppOpenRenderer.h
//  Adapter
//
//  Created by bytedance on 2023/5/5.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADPangleRTBAppOpenRenderer : NSObject<GADMediationAppOpenAd>

- (void)renderAppOpenAdForAdConfiguration:
            (nonnull GADMediationAppOpenAdConfiguration *)adConfiguration
                      completionHandler:
(nonnull GADMediationAppOpenLoadCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END

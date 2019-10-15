//
//  GADFYBMediationRewardedAd.h
//  Adapter
//
//  Created by Fyber on 9/9/19.
//  Copyright © 2019 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

@interface GADFYBMediationRewardedAd : NSObject

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END

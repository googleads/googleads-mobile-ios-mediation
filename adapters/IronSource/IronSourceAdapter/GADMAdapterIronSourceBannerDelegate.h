//
//  GADMAdapterIronSourceBannerDelegate.h
//  Adapter
//
//  Created by alond on 30/08/2022.
//  Copyright © 2022 Google. All rights reserved.
//


@protocol GADMAdapterIronSourceBannerDelegate

typedef NS_ENUM(NSInteger, ISInstanceState);

- (void)bannerDidLoad:(UIViewController *)bannerView instanceId:(NSString *)instanceId;
- (void)bannerDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId;
- (void)bannerDidShow:(NSString *)instanceId;
- (void)didClickBanner:(NSString *)instanceId;
- (void)bannerWillLeaveApplication:(NSString *)instanceId;

- (void)setState:(NSString *)state;
- (NSString *)getState;

@end

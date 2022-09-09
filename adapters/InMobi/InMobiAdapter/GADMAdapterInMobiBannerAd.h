//
//  GADMAdapterInMobiBannerAd.h
//  IMAdMobAdapter
//
//  Created by Bavirisetti.Dinesh on 01/09/22.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/IMBanner.h>

@interface GADMAdapterInMobiBannerAd : NSObject<GADMediationBannerAd, IMBannerDelegate>

/// Initializes the banner ad renderer.
- (nonnull instancetype)initWithPlacementIdentifier:(nonnull NSNumber *)placementIdentifier;

- (void)loadBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler;
@end

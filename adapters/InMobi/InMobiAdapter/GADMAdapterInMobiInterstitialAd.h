//
//  GADMAdapterInMobiInterstitialAd.h
//  IMAdMobAdapter
//
//  Created by Bavirisetti.Dinesh on 02/09/22.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/IMInterstitial.h>

@interface GADMAdapterInMobiInterstitialAd : NSObject<GADMediationInterstitialAd, IMInterstitialDelegate>

/// Initializes the Interstitial ad renderer.
- (nonnull instancetype)initWithPlacementIdentifier:(nonnull NSNumber *)placementIdentifier;

- (void)loadInterstitialForAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler;
@end



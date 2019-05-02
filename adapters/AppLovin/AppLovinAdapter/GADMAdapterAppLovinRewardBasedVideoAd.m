//
//  GADMAdapterAppLovinRewardBasedVideoAd.m
//
//
//  Created by Thomas So on 5/20/17.
//
//

#import "GADMAdapterAppLovinRewardBasedVideoAd.h"
#import "GADMediationAdapterAppLovin.h"

@implementation GADMAdapterAppLovinRewardBasedVideoAd

/// TODO(Google): Remove this class once Google's server points to GADMediationAdapterAppLovin
/// directly to ask for a rewarded ad on non-open bidding requests.
+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterAppLovin class];
}

@end

#import "GADMAdapterVungleRewardBasedVideoAd.h"
#import "GADMediationAdapterVungle.h"

@implementation GADMAdapterVungleRewardBasedVideoAd

/// TODO(Google): Remove this class once Google's server points to GADMediationAdapterVungle
/// directly to ask for a rewarded ad.

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterVungle class];
}

@end

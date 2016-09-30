@import Foundation;

/// The purpose of the GADMAdapterUnityDataProvider protocol is to allow the singleton to interact
/// with the adapter.
@protocol GADMAdapterUnityDataProvider <NSObject>

/// Returns placement ID for either reward-based video ad or interstitial ad of Unity Ads network.
- (NSString *)getPlacementID;

@end
@import Foundation;

/// Unity Ads game ID.
static NSString *const GADMAdapterUnityGameID = @"gameId";

/// Unity Ads placement ID.
/// Unity Ads has moved from zoneId to placementId, but to keep backward compatibility, we are still
/// using zoneId as a value.
static NSString *const GADMAdapterUnityPlacementID = @"zoneId";

/// Ad mediation network adapter version.
static NSString *const GADMAdapterUnityVersion = @"2.0.4.0";

/// Ad mediation network name.
static NSString *const GADMAdapterUnityMediationNetworkName = @"AdMob";

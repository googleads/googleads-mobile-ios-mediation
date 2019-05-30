//
//  GADDuAdInitializer.h
//  Adapter
//

@import GoogleMobileAds;

@interface GADDuAdInitializer : NSObject

+ (id)sharedInstance;

- (void)initializeWithConnector:(id<GADMAdNetworkConnector>)connector;

- (void)initializeWithAppID:(NSString *)appID placmentIDs:(NSMutableSet *)placementIDs;

@end

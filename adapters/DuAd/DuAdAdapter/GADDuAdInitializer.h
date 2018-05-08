//
//  GADDuAdInitializer.h
//  Adapter
//

@import GoogleMobileAds;

@interface GADDuAdInitializer : NSObject

+ (id)sharedInstance;

- (void)initWithConnector:(id<GADMAdNetworkConnector>)connector;

@end

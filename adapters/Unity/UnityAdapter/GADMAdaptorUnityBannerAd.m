@import Foundation;
@import GoogleMobileAds;

#import "GADMAdaptorUnityBannerAd.h"
#import "GADUnityError.h"
#import "GADMAdapterUnityConstants.h"

// #import "UnityAds/UADSBanner.h"

@interface GADMAdaptorUnityBannerAd ()
@property (nonatomic) NSString* placementId;
@property (nonatomic) UIViewController* rootViewController;

@end
@implementation GADMAdaptorUnityBannerAd

  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  UIViewController *rootViewController;

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
                                       adapter:(id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (instancetype)init {
  return nil;
}

-(void)dealloc {
    [UnityAdsBanner destroy];
}


- (void)getBannerWithSize:(GADAdSize)adSize{
    self.placementId = [[[_connector credentials] objectForKey:GADMAdapterUnityPlacementID] copy];
    NSString *gameId = [[[_connector credentials] objectForKey:GADMAdapterUnityGameID] copy];

    if (self.placementId == nil) {
    	id<GADMAdNetworkConnector> strongConnector = _connector;
  		NSError *error = GADUnityErrorWithDescription(@"Placement ID not found");
  		[strongConnector adapter:_adapter didFailAd:error];
        return;
    }

    _rootViewController = [_connector viewControllerForPresentingModalView];
    if (!rootViewController) {
        NSError* error = GADUnityErrorWithDescription(@"Root view controller cannot be nil.");
        [_connector adapter:_adapter didFailAd:error];
        return;
    }

    [UnityAdsBanner loadBanner:self.placementId];
}


- (void)stopBeingDelegate{
	
}

#pragma mark - UnityAdsBannerDelegate

-(void)unityAdsBannerDidLoad:(NSString *)placementId view:(UIView *)view {
    id<GADMAdNetworkConnector> strongConnector = _connector;
    id<GADMAdNetworkAdapter> strongAdapter = _adapter;
    if (strongAdapter && strongConnector) {
        [strongConnector adapter:strongAdapter didReceiveAdView:view];
    }
}

-(void)unityAdsBannerDidUnload:(NSString *)placementId {

}

-(void)unityAdsBannerDidShow:(NSString *)placementId {

}

-(void)unityAdsBannerDidHide:(NSString *)placementId {

}

-(void)unityAdsBannerDidClick:(NSString *)placementId {
    id<GADMAdNetworkConnector> strongConnector = _connector;
    id<GADMAdNetworkAdapter> strongAdapter = _adapter;
    if (strongAdapter && strongConnector) {
        [strongConnector adapterDidGetAdClick:strongAdapter];
    }
}

-(void)unityAdsBannerDidError:(NSString *)message {
    id<GADMAdNetworkConnector> strongConnector = _connector;
    id<GADMAdNetworkAdapter> strongAdapter = _adapter;
    NSError* error = GADUnityErrorWithDescription(@"Unknown banner error occured");
    if (strongConnector && strongAdapter) {
        [strongConnector adapter:strongAdapter didFailAd:error];
    }
}

@end

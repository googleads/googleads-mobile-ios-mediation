//
//  Copyright © 2017 AppLovin, Inc. All rights reserved.
//

@import GoogleMobileAds;

@interface GADMAdapterAppLovinExtras : NSObject<GADAdNetworkExtras>
// Optional settings
// Disable audio for video ads, must be set on each ad request
@property BOOL muteAudio;
@end

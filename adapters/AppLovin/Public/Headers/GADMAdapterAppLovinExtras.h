//
//  GADMAdapterAppLovinExtras.h
//
//
//  Created by Thomas So on 1/11/18.
//
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <AppLovinSDK/AppLovinSDK.h>

@interface GADMAdapterAppLovinExtras : NSObject<GADAdNetworkExtras>

/// Use this to mute audio for video ads. Must be set on each ad request.
@property(nonatomic, assign) BOOL muteAudio;

@end

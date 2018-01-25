//
//  GADMAdapterAppLovinExtras.h
//
//
//  Created by Thomas So on 1/11/18.
//
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <AppLovinSDk/AppLovinSDK.h>

@interface GADMAdapterAppLovinExtras : NSObject<GADAdNetworkExtras>

/**
 * Use this to mute audio for video ads. Must be set on each ad request.
 */
@property (nonatomic, assign) BOOL muteAudio;

/**
 * The accompanying zone identifier with this ad request, if any.
 */
@property (nonatomic, copy, alnullable) NSString *zoneIdentifier;

@end

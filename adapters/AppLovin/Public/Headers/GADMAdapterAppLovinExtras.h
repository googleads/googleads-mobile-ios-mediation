//
//  GADMAdapterAppLovinExtras.h
//
//
//  Created by Thomas So on 1/11/18.
//
//

#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterAppLovinExtras : NSObject<GADAdNetworkExtras>

// Optional: Disable audio for video ads, must be set on each ad request.
@property (nonatomic, assign) BOOL muteAudio;

@end

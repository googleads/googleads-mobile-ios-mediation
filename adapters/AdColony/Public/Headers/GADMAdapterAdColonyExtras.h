//
// Copyright 2016, AdColony, Inc.
//

#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterAdColonyExtras : NSObject<GADAdNetworkExtras>

/// Enables reward dialogs to be shown before an advertisement.
@property BOOL showPrePopup;

/// Enables reward dialogs to be shown after an advertisement.
@property BOOL showPostPopup;

@end

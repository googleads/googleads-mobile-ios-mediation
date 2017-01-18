//
// Copyright 2016, AdColony, Inc.
//

#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterAdColonyExtras : NSObject<GADAdNetworkExtras>

// Optional custom identifier for the current user for rewarded video, this will be used within server authoritative rewards.
// This must be 128 characters or less.
@property NSString *userId;

// Enables reward dialogs to be shown before an advertisement.
@property BOOL showPrePopup;

// Enables reward dialogs to be shown after an advertisement.
@property BOOL showPostPopup;

@end

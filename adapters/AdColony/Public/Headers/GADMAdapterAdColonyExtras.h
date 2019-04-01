//
// Copyright 2016, AdColony, Inc.
//

#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterAdColonyExtras : NSObject<GADAdNetworkExtras>

/// Optional custom identifier for the current user for rewarded video, this will be used within
/// server authoritative rewards.
/// This must be 128 characters or less.
@property NSString *userId;

/// Enables reward dialogs to be shown before an advertisement.
@property BOOL showPrePopup;

/// Enables reward dialogs to be shown after an advertisement.
@property BOOL showPostPopup;

/// Enables test ads for your application without changing dashboard settings.
@property BOOL testMode;

/// Inform AdColony that GDPR should be considered for the user.
@property (nonatomic) BOOL gdprRequired;

/// End user's IAB compatiable GDPR consent string.
/// See: https://github.com/AdColony/AdColony-iOS-SDK-3/wiki/GDPR
@property (nonatomic) NSString *gdprConsentString;

@end

//
//  VungleAdNetworkExtras.h
//
//  Copyright © 2016 Vungle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GoogleMobileAds/GADAdNetworkExtras.h>

@interface VungleAdNetworkExtras : NSObject<GADAdNetworkExtras>

/*!
 * @brief NSString with user identifier that will be passed if the ad is incentivized.
 * @discussion Optional. The value passed as 'user' in the an incentivized server-to-server call.
 */
@property(nonatomic, copy) NSString *_Nullable userId;

/*!
 * @brief Controls whether presented ads will start in a muted state or not.
 */
@property(nonatomic, assign) BOOL muted;

@property(nonatomic, assign) NSUInteger ordinal;

@property(nonatomic, assign) NSTimeInterval flexViewAutoDismissSeconds;

@property(nonatomic, copy) NSArray<NSString *> *_Nullable allPlacements;

@property(nonatomic, copy) NSString *_Nullable playingPlacement;

@end

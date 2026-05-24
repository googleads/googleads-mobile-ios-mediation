#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdExperienceConfig.h>
#import <FBAudienceNetwork/FBAdExtraHint.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBRewardedVideoAdDelegate;

/**
 * Fake FBRewardedVideoAd interface. This header contains subset of properties and methods of actual
 * public header.
 */
@interface FBRewardedVideoAd : NSObject

/**
 * The FBRewardedVideoAdDelegate object.
 */
@property(nonatomic, weak, nullable) id<FBRewardedVideoAdDelegate> delegate;

/**
 * FBAdExtraHint to provide extra info. Note: FBAdExtraHint is deprecated in AudienceNetwork. See
 * FBAdExtraHint for more details.
 */
@property(nonatomic, copy, nullable) FBAdExtraHint *extraHint;

/**
 * FBAdExperiencConfig to provide additional ad configuration.
 */
@property(nonatomic, copy, nullable) FBAdExperienceConfig *adExperienceConfig;

/**
 * Initializes a FBRewardedVideoAd matching the given placement id.
 *
 * @param placementID The id of the ad placement. You can create your placement id from Facebook
 * developers page.
 */
- (instancetype)initWithPlacementID:(NSString *)placementID;

/**
 * Begins loading the FBRewardedVideoAd content.
 */
- (void)loadAd;

/**
 * Begins loading the FBRewardedVideoAd content from a bid payload attained through a server side
 * bid.
 */
- (void)loadAdWithBidPayload:(NSString *)bidPayload;

/**
 * Presents the rewarded video ad modally from the specified view controller.
 *
 * @param rootViewController The view controller that will be used to present the rewarded video ad.
 */
- (BOOL)showAdFromRootViewController:(UIViewController *)rootViewController;

@end

/**
 * The methods declared by the FBRewardedVideoAdDelegate protocol allow the adopting delegate to
 * respond to messages from the FBRewardedVideoAd class and thus respond to operations such as
 * whether the ad has been loaded, the person has clicked the ad or closed video/end card.
 */
@protocol FBRewardedVideoAdDelegate <NSObject>

@optional

/**
 * Sent after an ad has been clicked by the person.
 *
 * @param rewardedVideoAd A FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd;

/**
 * Sent when an ad has been successfully loaded.
 *
 * @param rewardedVideoAd A FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd;

/**
 * Sent after a FBRewardedVideoAd object has been dismissed from the screen, returning control to
 * your application.
 *
 * @param rewardedVideoAd A FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd;

/**
 * Sent immediately before a FBRewardedVideoAd object will be dismissed from the screen.
 *
 * @param rewardedVideoAd A FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdWillClose:(FBRewardedVideoAd *)rewardedVideoAd;

/**
 * Sent after a FBRewardedVideoAd fails to load the ad.
 *
 * @param rewardedVideoAd A FBRewardedVideoAd object sending the message.
 * @param error An error object containing details of the error.
 */
- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error;

/**
 * Sent after the FBRewardedVideoAd object has finished playing the video successfully. Reward the
 * user on this callback.
 *
 * @param rewardedVideoAd A FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd;

/**
 * Sent immediately before the impression of a FBRewardedVideoAd object will be logged.
 *
 * @param rewardedVideoAd A FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd;

@end

NS_ASSUME_NONNULL_END
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdExtraHint.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBAdViewDelegate;

/**
 * Fake FBAdView interface. This header contains subset of properties and methods of actual public
 * header.
 */
@interface FBAdView : UIView

/**
 * Initializes an instance of FBAdView matching the given placement id with a given bidding payload.
 *
 * @param placementID The id of the ad placement. You can create your placement id from Facebook
 * developers page.
 * @param bidPayload The bid payload sent from the server.
 * @param rootViewController The view controller that will be used to present the ad and the app
 * store view.
 * @param error An out value that returns any error encountered during init.
 */
- (nullable instancetype)initWithPlacementID:(NSString *)placementID
                                  bidPayload:(NSString *)bidPayload
                          rootViewController:(nullable UIViewController *)rootViewController
                                       error:(NSError *__autoreleasing *)error
    NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (nullable instancetype)initWithCoder:(NSCoder *)code NS_UNAVAILABLE;

/**
 * Begins loading the FBAdView content from a bid payload attained through a server side bid.
 *
 * You can implement `adViewDidLoad:` and `adView:didFailWithError:` methods
 * of `FBAdViewDelegate` if you would like to be notified as loading succeeds or fails.
 *
 * @param bidPayload The payload of the ad bid. You can get your bid id from Facebook bidder
 * endpoint.
 */
- (void)loadAdWithBidPayload:(NSString *)bidPayload;

/**
 * The FBAdViewDelegate object.
 */
@property(nonatomic, weak, nullable) id<FBAdViewDelegate> delegate;

/**
 * FBAdExtraHint to provide extra info. Note: FBAdExtraHint is deprecated in AudienceNetwork. See
 * FBAdExtraHint for more details.
 */
@property(nonatomic, strong, nullable) FBAdExtraHint *extraHint;

@end

/**
 * Fake FBAdViewDelegate protocol.
 */
@protocol FBAdViewDelegate <NSObject>

@optional

/**
 * A view controller that is used to present modal content.
 */
@property(nonatomic, readonly, strong) UIViewController *viewControllerForPresentingModalView;

/**
 * Sent after an ad has been clicked by the person.
 *
 * @param adView An FBAdView object sending the message.
 */
- (void)adViewDidClick:(FBAdView *)adView;

/**
 * When an ad is clicked, the modal view will be presented. And when the user finishes the
 * interaction with the modal view and dismiss it, this message will be sent, returning control
 * to the application.
 *
 * @param adView An FBAdView object sending the message.
 */
- (void)adViewDidFinishHandlingClick:(FBAdView *)adView;

/**
 * Sent when an ad has been successfully loaded.
 *
 * @param adView An FBAdView object sending the message.
 */
- (void)adViewDidLoad:(FBAdView *)adView;

/**
 * Sent after an FBAdView fails to load the ad.
 *
 * @param adView An FBAdView object sending the message.
 * @param error An error object containing details of the error.
 */
- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error;

/**
 * Sent immediately before the impression of an FBAdView object will be logged.
 *
 * @param adView An FBAdView object sending the message.
 */
- (void)adViewWillLogImpression:(FBAdView *)adView;

/**
 * Sent when the dynamic height of an FBAdView is set dynamically.
 *
 * @param adView An FBAdView object sending the message.
 * @param dynamicHeight The height that needs to be set dynamically.
 */
- (void)adView:(FBAdView *)adView setDynamicHeight:(double)dynamicHeight;

/**
 * Sent when the position of an FBAdView is set dynamically.
 *
 * @param adView An FBAdView object sending the message.
 * @param dynamicPosition CGPoint that indicates the new point of origin for the adView.
 */
- (void)adView:(FBAdView *)adView setDynamicPosition:(CGPoint)dynamicPosition;

/**
 * Sent when the origin of an FBAdView is to be changed during an animation lasting a specific
 * amount of time.
 *
 * @param position CGPoint specifying the new origin of the FBAdView
 * @param duration CGFloat specifying the duration in seconds of the animation.
 */
- (void)adView:(FBAdView *)controller
    animateToPosition:(CGPoint)position
         withDuration:(CGFloat)duration;

/**
 * Sent after an FBAdView fails to load the fullscreen view of an ad.
 *
 * @param adView An FBAdView object sending the message.
 * @param error An error object containing details of the error.
 */
- (void)adView:(FBAdView *)adView fullscreenDidFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END

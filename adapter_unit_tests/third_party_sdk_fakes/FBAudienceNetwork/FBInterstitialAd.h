#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdExtraHint.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBInterstitialAdDelegate;

/**
 * Fake FBInterstitialAd interface. This header contains subset of properties and methods of actual
 * public header.
 */
@interface FBInterstitialAd : NSObject

/**
 * The delegate of this interstitial ad.
 */
@property(nonatomic, weak, nullable) id<FBInterstitialAdDelegate> delegate;

/**
 * FBAdExtraHint to provide extra info. Note: FBAdExtraHint is deprecated in AudienceNetwork. See
 * FBAdExtraHint for more details.
 */
@property(nonatomic, strong, nullable) FBAdExtraHint *extraHint;

/**
 * This is a method to initialize an FBInterstitialAd matching the given placement id.
 *
 * @param placementID The id of the ad placement. You can create your placement id from Facebook
 * developers page.
 */
- (instancetype)initWithPlacementID:(NSString *)placementID;

/**
 * Begins loading the FBInterstitialAd content from a bid payload attained through a server side
 * bid.
 *
 * You can implement `adViewDidLoad:` and `adView:didFailWithError:` methods
 * of `FBAdViewDelegate` if you would like to be notified as loading succeeds or fails.
 *
 * @param bidPayload The payload of the ad bid. You can get your bid id from Facebook bidder
 * endpoint.
 */
- (void)loadAdWithBidPayload:(NSString *)bidPayload;

/**
 * Presents the interstitial ad modally from the specified view controller.
 *
 * @param rootViewController The view controller that will be used to present the interstitial ad.
 */
- (BOOL)showAdFromRootViewController:(nullable UIViewController *)rootViewController;

@end

/**
 * The methods declared by the FBInterstitialAdDelegate protocol allow the adopting delegate to
 * respond to messages from the FBInterstitialAd class and thus respond to operations such as
 * whether the interstitial ad has been loaded, user has clicked or closed the interstitial.
 */
@protocol FBInterstitialAdDelegate <NSObject>

@optional

/**
 * Sent after an ad in the FBInterstitialAd object is clicked. The appropriate app store view or
 * app browser will be launched.
 *
 * @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd;

/**
 * Sent after an FBInterstitialAd object has been dismissed from the screen, returning control
 * to your application.
 *
 * @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd;

/**
 * Sent immediately before an FBInterstitialAd object will be dismissed from the screen.
 *
 * @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd;

/**
 * Sent when an FBInterstitialAd successfully loads an ad.
 *
 * @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd;

/**
 * Sent when an FBInterstitialAd failes to load an ad.
 *
 * @param interstitialAd An FBInterstitialAd object sending the message.
 * @param error An error object containing details of the error.
 */
- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error;

/**
 * Sent immediately before the impression of an FBInterstitialAd object will be logged.
 *
 * @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd;

@end

NS_ASSUME_NONNULL_END

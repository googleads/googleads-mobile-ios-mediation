#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdSettings.h>
#import <FBAudienceNetwork/FBNativeAdBase.h>

@protocol FBNativeBannerAdDelegate;

/**
 * The fake FBNativeBannerAd interface. This header contains subset of properties and methods of
 * actual public header.
 */
@interface FBNativeBannerAd : FBNativeAdBase

@property(nonatomic, weak, nullable) id<FBNativeBannerAdDelegate> delegate;

/**
 * Initialize with placementId.
 */
- (nonnull instancetype)initWithPlacementID:(nonnull NSString *)placementID;

/**
 * This is a method to associate FBNativeBannerAd with the UIView you will use to display the native
 * ads and set clickable areas.
 *
 * @param view The UIView you created to render all the native ads data elements.
 * @param iconImageView The UIImageView you created to render the icon.
 * @param viewController The UIViewController that will be used to present
 * SKStoreProductViewController (iTunes Store product information). If nil is passed, the top view
 * controller currently shown will be used.
 * @param clickableViews An array of UIView you created to render the native ads data element, e.g.
 * CallToAction button, Icon image, which you want to specify as clickable.
 */
- (void)registerViewForInteraction:(nonnull UIView *)view
                     iconImageView:(nonnull UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews;

@end

/**
 * The methods declared by the FBNativeBannerAdDelegate protocol allow the adopting delegate to
 * respond to messages from the FBNativeBannerAd class and thus respond to operations such as
 * whether the native banner ad has been loaded.
 */
@protocol FBNativeBannerAdDelegate <NSObject>

@optional

/**
 * Sent when a FBNativeBannerAd has been successfully loaded.
 *
 * @param nativeBannerAd A FBNativeBannerAd object sending the message.
 */
- (void)nativeBannerAdDidLoad:(nonnull FBNativeBannerAd *)nativeBannerAd;

/**
 * Sent immediately before the impression of a FBNativeBannerAd object will be logged.
 *
 * @param nativeBannerAd A FBNativeBannerAd object sending the message.
 */
- (void)nativeBannerAdWillLogImpression:(nonnull FBNativeBannerAd *)nativeBannerAd;

/**
 * Sent when a FBNativeBannerAd is failed to load.
 *
 * @param nativeBannerAd A FBNativeBannerAd object sending the message.
 * @param error An error object containing details of the error.
 */
- (void)nativeBannerAd:(nonnull FBNativeBannerAd *)nativeBannerAd didFailWithError:(nullable NSError *)error;

/**
 * Sent after an ad has been clicked by the person.
 *
 * @param nativeBannerAd A FBNativeBannerAd object sending the message.
 */
- (void)nativeBannerAdDidClick:(nonnull FBNativeBannerAd *)nativeBannerAd;

@end

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdSettings.h>
#import <FBAudienceNetwork/FBNativeAdBase.h>

@protocol FBNativeAdDelegate;

/**
 * The fake FBNativeAd interface. This header contains subset of properties and methods of actual
 * public header.
 */
@interface FBNativeAd : FBNativeAdBase

/**
 * The FBNativeAdDelegate object.
 */
@property(nonatomic, weak, nullable) id<FBNativeAdDelegate> delegate;

/**
 * Initialize with placementId.
 */
- (nonnull instancetype)initWithPlacementID:(NSString *)placementID;

/**
 * This is a method to associate FBNativeAd with the UIView you will use to display the native ads
 * and set clickable areas.
 *
 * @param view The UIView you created to render all the native ads data elements.
 * @param mediaView The FBMediaView you created to render the media (cover image / video / carousel)
 * @param iconImageView The UIImageView you created to render the icon. Image will be set
 * @param viewController The UIViewController that will be used to present
 * SKStoreProductViewController (iTunes Store product information). If nil is passed, the top view
 * controller currently shown will be used.
 * @param clickableViews An array of UIView you created to render the native ads data element, e.g.
 * CallToAction button, Icon image, which you want to specify as clickable.
 */
- (void)registerViewForInteraction:(nonnull UIView *)view
                         mediaView:(nonnull FBMediaView *)mediaView
                     iconImageView:(nullable UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews;

@end

/**
 * The methods declared by the FBNativeAdDelegate protocol allow the adopting delegate to respond to
 * messages from the FBNativeAd class and thus respond to operations such as whether the native ad
 * has been loaded.
 */
@protocol FBNativeAdDelegate <NSObject>

@optional

/**
 * Sent when a FBNativeAd has been successfully loaded.
 *
 * @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdDidLoad:(nonnull FBNativeAd *)nativeAd;

/**
 * Sent when a FBNativeAd has succesfully downloaded all media
 */
- (void)nativeAdDidDownloadMedia:(nonnull FBNativeAd *)nativeAd;

/**
 * Sent immediately before the impression of a FBNativeAd object will be logged.
 * @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdWillLogImpression:(nonnull FBNativeAd *)nativeAd;

/**
 * Sent when a FBNativeAd is failed to load.
 *
 * @param nativeAd A FBNativeAd object sending the message.
 * @param error An error object containing details of the error.
 */
- (void)nativeAd:(nonnull FBNativeAd *)nativeAd didFailWithError:(nonnull NSError *)error;

/**
 * Sent after an ad has been clicked by the person.
 *
 * @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdDidClick:(nonnull FBNativeAd *)nativeAd;

/**
 * When an ad is clicked, the modal view will be presented. And when the user finishes the
 * interaction with the modal view and dismiss it, this message will be sent, returning control to
 * the application.
 *
 * @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdDidFinishHandlingClick:(nonnull FBNativeAd *)nativeAd;

@end

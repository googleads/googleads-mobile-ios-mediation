#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FBNativeAdBase;

/**
 * Minimum dimensions of the view - width
 */
extern const CGFloat FBAdOptionsViewWidth;
/**
 * Minimum dimensions of the view - height
 */
extern const CGFloat FBAdOptionsViewHeight;

/**
 * The fake FBAdOptionsView interface. This header contains subset of properties and methods of
 * actual public header.
 */
@interface FBAdOptionsView : UIView

/**
 * The native ad that provides AdOptions info, such as click url. Setting this updates the nativeAd.
 */
@property(nonatomic, weak, readwrite, nullable) FBNativeAdBase *nativeAd;

@end

NS_ASSUME_NONNULL_END

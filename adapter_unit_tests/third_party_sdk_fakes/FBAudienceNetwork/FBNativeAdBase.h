#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdExtraHint.h>
#import <FBAudienceNetwork/FBAdSettings.h>

@class FBMediaView;

/**
 * Type of ad format.
 */
typedef NS_ENUM(NSInteger, FBAdFormatType) {
  FBAdFormatTypeUnknown = 0,
  FBAdFormatTypeImage,
  FBAdFormatTypeVideo,
  FBAdFormatTypeCarousel
};

/**
 * Determines if caching of the ad's assets should be done before calling adDidLoad.
 */
typedef NS_ENUM(NSInteger, FBNativeAdsCachePolicy) {
  /// No ad content is cached
  FBNativeAdsCachePolicyNone,
  /// All content is cached
  FBNativeAdsCachePolicyAll,
};

/**
 * The fake FBNativeAdBase interface. This header contains subset of properties and methods of
 * actual public header.
 */
@interface FBNativeAdBase : NSObject

/**
 * Typed access to the headline that the advertiser entered when they created their ad. This is
 * usually the ad's main title.
 */
@property(nonatomic, readonly, nullable) NSString *headline;

/**
 * Typed access to the name of the Facebook Page or mobile app that represents the business running
 * the ad.
 */
@property(nonatomic, readonly, nullable) NSString *advertiserName;

/**
 * Typed access to the ad social context, for example "Over half a million users".
 */
@property(nonatomic, readonly, nullable) NSString *socialContext;

/**
 * Typed access to the call to action phrase of the ad, for example "Install Now".
 */
@property(nonatomic, readonly, nullable) NSString *callToAction;

/**
 * Typed access to the body text, truncated at length 90, which contains the text that the
 * advertiser entered when they created their ad. This often tells people what the ad is promoting.
 */
@property(nonatomic, readonly, nullable) NSString *bodyText;

/**
 * Typed access to the icon image. Only available after ad is successfully loaded.
 */
@property(nonatomic, readonly, nullable) UIImage *iconImage;

/**
 * FBAdExtraHint to provide extra info. Note: FBAdExtraHint is deprecated in AudienceNetwork. See
 * FBAdExtraHint for more details.
 */
@property(nonatomic, nullable) FBAdExtraHint *extraHint;

/**
 * Whether a FBNativeAd is connected with a UIView, which used to display the native ads.
 */
@property(nonatomic, getter=isRegistered) BOOL registered;

/**
 * Creates a new instance of a FBNativeAdBase from a bid payload. The actual subclass returned will
 * depend on the contents of the payload.
 *
 * @param placementId The placement ID of the ad.
 * @param bidPayload The bid payload received from the server.
 * @param error An out value that returns any error encountered during init.
 */
+ (nullable instancetype)nativeAdWithPlacementId:(nonnull NSString *)placementId
                                      bidPayload:(nonnull NSString *)bidPayload
                                           error:(NSError *__autoreleasing *)error;

/**
 * This is a method to disconnect a FBNativeAd with the UIView you used to display the native ads.
 */
- (void)unregisterView;

/**
 * Begins loading the FBNativeAd content from a bid payload attained through a server side bid.
 *
 * @param bidPayload The payload of the ad bid. You can get your bid payload from Facebook bidder
 * endpoint.
 */
- (void)loadAdWithBidPayload:(nonnull NSString *)bidPayload;

@end

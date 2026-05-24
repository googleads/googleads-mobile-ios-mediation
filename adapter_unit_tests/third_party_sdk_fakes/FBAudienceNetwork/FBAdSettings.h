#import <Foundation/Foundation.h>

/**
 * Fake FBAdSettings interface. This header contains subset of properties and
 * methods of actual public header.
 */
@interface FBAdSettings : NSObject

/**
 * Generates bidder token that needs to be included in the server side bid request to Facebook
 * endpoint.
 */
@property(class, nonatomic, copy, readonly) NSString *bidderToken;

/**
 * Configures the ad control for treatment as mixed audience directed.
 * Information for Mixed Audience Apps and Services:
 * https://developers.facebook.com/docs/audience-network/coppa
 */
@property(class, nonatomic, getter=isMixedAudience) BOOL mixedAudience;

/**
 * The name of the mediation service.
 * If an ad provided service is mediating Audience Network in their sdk, it is required to set the
 * name of the mediation service.
 */
@property(class, nonatomic, copy) NSString *mediationService;

/**
 * Reset the settings.
 */
+ (void)resetSettings;

@end

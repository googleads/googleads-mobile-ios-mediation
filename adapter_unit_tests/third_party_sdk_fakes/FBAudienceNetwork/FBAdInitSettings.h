#import <Foundation/Foundation.h>

/**
 * Fake FBAdInitSettings interface. This header contains subset of properties and methods of actual
 * public header.
 */
@interface FBAdInitSettings : NSObject

/**
 * Designated initializer for FBAdInitSettings.
 * If an ad provided service is mediating Audience Network in their sdk, it is required to set the
 * name of the mediation service.
 *
 * @param placementIDs An array of placement identifiers.
 * @param mediationService String to identify mediation provider.
 */
- (nonnull instancetype)initWithPlacementIDs:(nonnull NSArray<NSString *> *)placementIDs
                            mediationService:(nonnull NSString *)mediationService;

@end
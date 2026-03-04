#import <Foundation/Foundation.h>

/**
 * Fake FBAdExtraHint interface. This header contains subset of properties and
 * methods of actual public header.
 */
@interface FBAdExtraHint : NSObject <NSCopying>

/**
 * The data of this extra hint.
 */
@property(nonatomic, copy, nullable) NSString *mediationData;

@end

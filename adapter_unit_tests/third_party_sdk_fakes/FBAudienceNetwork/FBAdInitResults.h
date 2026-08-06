#import <Foundation/Foundation.h>

/**
 * Fake FBAdInitResults interface. This header contains subset of properties and methods of actual
 * public header.
 */
@interface FBAdInitResults : NSObject
/**
 * Boolean which says whether initialization was successful.
 */
@property(nonatomic, assign, readonly, getter=isSuccess) BOOL success;

/**
 * Message which provides more details about initialization result.
 */
@property(nonatomic, copy, readonly) NSString *message;
@end
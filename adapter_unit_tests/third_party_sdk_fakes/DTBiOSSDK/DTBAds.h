#import <Foundation/Foundation.h>

@interface DTBAds : NSObject
@property(class, atomic, readonly, strong, nonnull) DTBAds *sharedInstance;
@property(nonatomic, readonly) BOOL isReady;
+ (nonnull NSString *)version;
@end
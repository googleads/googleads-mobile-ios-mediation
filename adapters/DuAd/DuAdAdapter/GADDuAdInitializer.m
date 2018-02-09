//
//  GADDuAdInitializer.m
//  Adapter
//

@import DUModuleSDK;

#import "GADDuAdInitializer.h"
#import "GADDuAdNetworkExtras.h"

@interface GADDuAdInitializer ()

@property(nonatomic, strong) NSMutableArray *m_nativeIds;

@end

@implementation GADDuAdInitializer

+ (id)sharedInstance
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(id)init {
    self=[super init];
    if (self) {
        if(!self.m_nativeIds) {
            self.m_nativeIds = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

- (void) initWithConnector:(id<GADMAdNetworkConnector>)connector {
    if (connector) {
        id obj = [connector networkExtras];
        GADDuAdNetworkExtras *networkExtras = [obj isKindOfClass:[GADDuAdNetworkExtras class]] ? obj : nil;
        if (networkExtras) {
            if (networkExtras.appLicense && networkExtras.placementIds) {
                BOOL modified = NO;
                NSMutableArray *tmp = [[NSMutableArray alloc] init];
                for (NSString *pid in networkExtras.placementIds) {
                    if ([self.m_nativeIds indexOfObject:pid] == NSNotFound) {
                        [tmp addObject:pid];
                        modified = YES;
                    }
                }
                if (modified) {
                    [self.m_nativeIds addObjectsFromArray:tmp];
                    NSMutableArray *nativeIds = [[NSMutableArray alloc] init];
                    for (NSString *pid in self.m_nativeIds) {
                        NSDictionary *nativeId = [[NSMutableDictionary alloc] init];
                        [nativeId setValue:pid forKey:@"pid"];
                        [nativeIds addObject:nativeId];
                    }
                    NSDictionary *config = [NSDictionary dictionaryWithObject:nativeIds forKey:@"native"];
                    [DUAdNetwork initWithConfigDic:config withLicense:networkExtras.appLicense];
                }
            }
        }
    }
}

@end



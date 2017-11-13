//
//  GADMMaioParameter.h
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioParameter.h"

/// Maio media ID.
static NSString *const GADMMaioAdapterMediaId = @"mediaId";

/// Maio zone ID.
static NSString *const GADMMaioAdapterZoneId = @"zoneId";


@implementation GADMMaioParameter

- (instancetype)initWithMediaId:(NSString *)mediaId zoneId:(NSString *)zoneId {
    self = [super init];
    if (self) {
        _mediaId = mediaId;
        _zoneId = zoneId;
    }
    return self;
}

/**
 * Custom Eventパラメータ文字列をMaio用に変換します。
 */
+ (GADMMaioParameter*)parameterWithJsonString:(NSString*)jsonString {
    GADMMaioParameter *result;
    NSError *error;
    id json = [self jsonObjectWithString:jsonString error:&error];
    if (json) {
        result = [[GADMMaioParameter alloc] initWithMediaId:json[GADMMaioAdapterMediaId] zoneId:json[GADMMaioAdapterZoneId]];
    }
    else {
        NSLog(@"%@", error);
        result = [[GADMMaioParameter alloc] initWithMediaId:jsonString zoneId:nil];
    }
    
    return result;
}


#pragma mark - private

/**
 *  JSON 文字列を JSON オブジェクトに変換します。
 */
+ (id)jsonObjectWithString:(NSString *)jsonString error:(NSError **)error {
    if ([jsonString length] == 0) return nil;
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}

@end

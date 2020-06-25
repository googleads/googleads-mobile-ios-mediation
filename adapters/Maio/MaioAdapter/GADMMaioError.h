//
//  GADMMaioError.h
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Maio;

@interface GADMMaioError : NSObject

+ (NSError *)errorWithDescription:(NSString *)description;
+ (NSError *)errorWithDescription:(NSString *)description errorCode:(NSInteger)errorCode;
+ (NSString *)stringFromFailReason:(MaioFailReason)failReason;
+ (NSString *)stringFromErrorCode:(NSInteger)errorCode;

+ (BOOL)codeIsAboutLoad:(NSInteger)errorCode;
+ (BOOL)codeIsAboutShow:(NSInteger)errorCode;

@end

//
//  GADMMaioError.h
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Maio;

@interface GADMMaioError : NSObject

+ (NSError *) errorWithDescription: (NSString *)description;
+ (NSString *)stringFromFailReason:(MaioFailReason)failReason;

@end

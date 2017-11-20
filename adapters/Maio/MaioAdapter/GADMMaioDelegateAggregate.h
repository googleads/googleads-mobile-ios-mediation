//
//  GADMMaioDelegateAggregate.h
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Maio;

@interface GADMMaioDelegateAggregate : NSObject <MaioDelegate>
@property (nonatomic) NSHashTable<id<MaioDelegate>>* delegates;

+ (instancetype)sharedInstance;
@end

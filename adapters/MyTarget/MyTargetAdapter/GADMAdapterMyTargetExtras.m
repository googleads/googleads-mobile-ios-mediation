//
//  GADMAdapterMyTargetExtras.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 04.10.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

#import "GADMAdapterMyTargetExtras.h"

@implementation GADMAdapterMyTargetExtras

- (instancetype)init {
  self = [super init];
  if (self) {
    _isDebugMode = YES;
  }
  return self;
}

@end

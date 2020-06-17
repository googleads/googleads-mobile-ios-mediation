//
//  GADMAdapterNendExtras.m
//  NendAdapter
//
//  Copyright © 2017 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendExtras.h"

@implementation GADMAdapterNendExtras

- (instancetype)init {
  self = [super init];
  if (self) {
    // Default values.
    _interstitialType = GADMAdapterNendInterstitialTypeNormal;
    _nativeType = GADMAdapterNendNativeTypeNormal;
  }
  return self;
}

@end

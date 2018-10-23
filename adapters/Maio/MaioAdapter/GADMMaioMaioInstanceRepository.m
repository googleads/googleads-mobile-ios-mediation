//
//  GADMMaioMaioInstanceRepository.m
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioMaioInstanceRepository.h"

@implementation GADMMaioMaioInstanceRepository

static NSMutableDictionary<NSString*, MaioInstance*> *_collection;

+ (void)initialize {
  if (self == [GADMMaioMaioInstanceRepository class]) {
    _collection = @{}.mutableCopy;
  }
}

- (MaioInstance *)maioInstanceByMediaId:(NSString *)mediaId {
  @synchronized(self) {
    return _collection[mediaId];
  }
}

- (void)addMaioInstance:(nonnull MaioInstance *)instance {
  @synchronized(self) {
    _collection[instance.mediaId] = instance;
  }
}

@end

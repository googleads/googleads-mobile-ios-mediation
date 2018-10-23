//
//  GADMMaioMaioInstanceRepository.m
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioMaioInstanceRepository.h"
#import "GADMMaioDelegateAggregate.h"

@implementation GADMMaioMaioInstanceRepository

static NSMutableDictionary<NSString*, MaioInstance*> *_collection;

+ (void)initialize {
  if (self == [GADMMaioMaioInstanceRepository class]) {
    _collection = @{}.mutableCopy;
  }
}

- (MaioInstance *)maioInstanceByMediaId:(NSString *)mediaId {
  @synchronized(self) {
    MaioInstance *exists = _collection[mediaId];
    if (exists) {
      return exists;
    }
    MaioInstance *instance = [self generateMaioInstanceWithMediaId:mediaId];
    [self addMaioInstance:instance];
    return instance;
  }
}

- (void)addMaioInstance:(nonnull MaioInstance *)instance {
  @synchronized(self) {
    _collection[instance.mediaId] = instance;
  }
}

- (MaioInstance*)generateMaioInstanceWithMediaId:(NSString*)mediaId {
  id<MaioDelegate> delegate = [GADMMaioDelegateAggregate sharedInstance];
  return [Maio startWithNonDefaultMediaId:mediaId delegate:delegate];
}

@end

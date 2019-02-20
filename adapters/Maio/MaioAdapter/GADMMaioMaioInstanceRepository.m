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
    id<MaioDelegate> delegate = [GADMMaioDelegateAggregate sharedInstance];
    MaioInstance *instance = [Maio startWithNonDefaultMediaId:mediaId
                                                     delegate:delegate];
    _collection[instance.mediaId] = instance;
    return instance;
  }
}

@end

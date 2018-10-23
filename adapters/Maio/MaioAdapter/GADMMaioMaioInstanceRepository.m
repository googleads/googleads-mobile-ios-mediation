//
//  GADMMaioMaioInstanceRepository.m
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioMaioInstanceRepository.h"

@interface GADMMaioMaioInstanceWrapper : NSObject
@property (nonatomic, readonly) MaioInstance* instance;
@property (nonatomic) BOOL isInitialized;
@end

@implementation GADMMaioMaioInstanceWrapper
- (instancetype)initWithMaioInstance:(MaioInstance*)instance
                         initialized:(BOOL)initialized {
  self = [super init];
  if (self) {
    _instance = instance;
    _isInitialized = initialized;
  }
  return self;
}
@end

@implementation GADMMaioMaioInstanceRepository

static NSMutableDictionary<NSString*, GADMMaioMaioInstanceWrapper*>
    *_collection;

+ (void)initialize {
  if (self == [GADMMaioMaioInstanceRepository class]) {
    _collection = @{}.mutableCopy;
  }
}

- (MaioInstance *)maioInstanceByMediaId:(NSString *)mediaId {
  @synchronized(self) {
    return _collection[mediaId].instance;
  }
}

- (void)addMaioInstance:(nonnull MaioInstance *)instance {
  @synchronized(self) {
    GADMMaioMaioInstanceWrapper *wrapper =
      [[GADMMaioMaioInstanceWrapper alloc] initWithMaioInstance:instance
                                                    initialized:NO];
    _collection[instance.mediaId] = wrapper;
  }
}

- (void)setInitialized:(BOOL)value mediaId:(NSString *)mediaId {
  @synchronized(self) {
    GADMMaioMaioInstanceWrapper *wrapper = _collection[mediaId];
    if (!wrapper) {
      return;
    }
    wrapper.isInitialized = value;
  }
}

@end

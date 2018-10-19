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
- (instancetype)initWithMaioInstance:(MaioInstance*)instance initialized:(BOOL)initialized {
  self = [super init];
  if (self) {
    _instance = instance;
    _isInitialized = initialized;
  }
  return self;
}
@end

@implementation GADMMaioMaioInstanceRepository

static MaioInstance *_maioInstance = nil;

/// YES if maio SDK is initialized.
static BOOL _isInitialized = NO;

- (MaioInstance *)maioInstanceByMediaId:(NSString *)mediaId {
  return _maioInstance;
}

- (void)addMaioInstance:(MaioInstance *)instance {
  _maioInstance = instance;
}

- (BOOL)isInitializedWithMediaId:(NSString *)mediaId {
  @synchronized(self) {
    return _isInitialized;
  }
}

- (void)setInitialized:(BOOL)value mediaId:(NSString *)mediaId {
  @synchronized(self) {
    _isInitialized = value;
  }
}

@end

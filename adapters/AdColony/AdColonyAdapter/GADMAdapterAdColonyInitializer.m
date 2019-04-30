//
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMAdapterAdColonyInitializer.h"
#import "GADMAdapterAdColonyHelper.h"

@implementation GADMAdapterAdColonyInitializer

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static GADMAdapterAdColonyInitializer *instance;
  dispatch_once(&onceToken, ^{
    instance = [[GADMAdapterAdColonyInitializer alloc] init];
  });
  return instance;
}

- (id)init {
  if (self = [super init]) {
    _zones = [NSSet set];
    _callbacks = [NSArray array];
  }
  return self;
}

- (void)initializeAdColonyWithAppId:(NSString *)appId
                              zones:(NSArray *)newZones
                            options:(AdColonyAppOptions *)options
                           callback:(void (^)(NSError *))callback {
  @synchronized(self) {
    NSLogDebug(@"new zones: %@", newZones);
    NSLogDebug(@"old zones: %@", self.zones);

    // Even if ADC configure should be smart with configuring with superset/subset of zones, manage
    // it here too.
    NSSet *oldZones = [NSSet setWithSet:self.zones];
    self.zones = [self.zones setByAddingObjectsFromArray:newZones];
    if (![oldZones isEqualToSet:self.zones]) {
      self.adColonyAdapterInitState = INIT_STATE_UNINITIALIZED;
    }

    // If ADC options have already been set, used directly or from previous configure here, use it
    // Only build new options if not previously set.
    if (options && self.adColonyAdapterInitState == INIT_STATE_INITIALIZED) {
      [AdColony setAppOptions:options];
    }

    if (self.adColonyAdapterInitState == INIT_STATE_INITIALIZED) {
      if (callback) {
        callback(nil);
      }
    } else {
      if (callback) {
        self.callbacks = [self.callbacks arrayByAddingObject:callback];
      }

      // Don't allow multiple config requests, the 2nd will use the results of the previous.
      if (self.adColonyAdapterInitState == INIT_STATE_UNINITIALIZED) {
        self.adColonyAdapterInitState = INIT_STATE_INITIALIZING;
        __weak typeof(self) weakSelf = self;
        NSLogDebug(@"zones: %@", [self.zones allObjects]);
        [AdColony configureWithAppID:appId
                             zoneIDs:[self.zones allObjects]
                             options:options
                          completion:^(NSArray<AdColonyZone *> *_Nonnull zones) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            @synchronized(strongSelf) {
                              if (zones.count < 1) {
                                strongSelf.adColonyAdapterInitState = INIT_STATE_UNINITIALIZED;
                                NSError *error =
                                    [NSError errorWithDomain:@"GADMAdapterAdColonyInitializer"
                                                        code:0
                                                    userInfo:@{
                                                      NSLocalizedDescriptionKey :
                                                          @"Failed to configure the zoneID."
                                                    }];
                                for (void (^localCallback)() in strongSelf.callbacks) {
                                  localCallback(error);
                                }
                              }
                              strongSelf.adColonyAdapterInitState = INIT_STATE_INITIALIZED;
                              for (void (^localCallback)() in strongSelf.callbacks) {
                                localCallback(nil);
                              }
                              strongSelf.callbacks = [NSArray array];
                            }
                          }];
      }
    }
  }
}

@end

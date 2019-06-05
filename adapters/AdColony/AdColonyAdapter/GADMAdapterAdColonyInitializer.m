//
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMAdapterAdColonyInitializer.h"
#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyHelper.h"

typedef void (^GADMAdapterAdColonyInitCompletionHandler)(NSError *_Nullable error);

@interface GADMAdapterAdColonyInitializer ()

@property(nonatomic, copy) NSSet *configuredZones;
@property(nonatomic, assign) AdColonyAdapterInitState adColonyAdapterInitState;
@property(nonatomic, copy) NSSet *zonesToBeConfigured;
@property(nonatomic, copy) NSMutableArray<GADMAdapterAdColonyInitCompletionHandler> *callbacks;
@property(nonatomic, assign) BOOL hasNewZones;
@property(nonatomic, assign) BOOL calledConfigureInLastFiveSeconds;

@end

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
    _configuredZones = [NSSet set];
    _zonesToBeConfigured = [NSMutableSet set];
    _callbacks = [[NSMutableArray alloc] init];
    _adColonyAdapterInitState = INIT_STATE_UNINITIALIZED;
  }
  return self;
}

- (void)initializeAdColonyWithAppId:(NSString *)appId
                              zones:(NSArray *)newZones
                            options:(AdColonyAppOptions *)options
                           callback:(GADMAdapterAdColonyInitCompletionHandler)callback {
  @synchronized(self) {
    if (self.adColonyAdapterInitState == INIT_STATE_INITIALIZING) {
      if (callback) {
        [self.callbacks addObject:callback];
      }
      return;
    }

    NSSet *newZonesSet;
    if (newZones) {
      newZonesSet = [NSSet setWithArray:newZones];
    }

    _hasNewZones = ![newZonesSet isSubsetOfSet:_configuredZones];

    if (_hasNewZones) {
      _zonesToBeConfigured = [_configuredZones setByAddingObjectsFromSet:newZonesSet];
      ;
      if (_calledConfigureInLastFiveSeconds) {
        NSError *error = [NSError
            errorWithDomain:kGADMAdapterAdColonyErrorDomain
                       code:0
                   userInfo:@{
                     NSLocalizedDescriptionKey :
                         @"The AdColony SDK does not support being configured twice "
                         @"within a five second period. This error can be mitigated by waiting "
                         @"for the Google Mobile Ads SDK's initialization completion "
                         @"handler to be called prior to loading ads."
                   }];
        callback(error);
        return;
      } else {
        _adColonyAdapterInitState = INIT_STATE_INITIALIZING;
        [self.callbacks addObject:callback];
        [self configureWithAppID:appId zoneIDs:[_zonesToBeConfigured allObjects] options:options];
        _zonesToBeConfigured = [NSSet set];
      }

    } else {
      if (options) {
        [AdColony setAppOptions:options];
      }

      if (_adColonyAdapterInitState == INIT_STATE_INITIALIZED) {
        if (callback) {
          callback(nil);
        }
      } else if (_adColonyAdapterInitState == INIT_STATE_INITIALIZING) {
        if (callback) {
          [self.callbacks addObject:callback];
        }
      }
    }
  }
}

- (void)configureWithAppID:(NSString *)appID
                   zoneIDs:(NSArray *)zoneIDs
                   options:(AdColonyAppOptions *)options {
  GADMAdapterAdColonyInitializer *__weak weakSelf = self;

  NSLogDebug(@"zones: %@", [self.zones allObjects]);
  _calledConfigureInLastFiveSeconds = YES;
  [AdColony configureWithAppID:appID
                       zoneIDs:zoneIDs
                       options:options
                    completion:^(NSArray<AdColonyZone *> *_Nonnull zones) {
                      GADMAdapterAdColonyInitializer *strongSelf = weakSelf;
                      NSMutableArray<GADMAdapterAdColonyInitCompletionHandler> *callbacks =
                          [NSMutableArray arrayWithArray:strongSelf.callbacks];
                      @synchronized(strongSelf) {
                        if (zones.count < 1) {
                          strongSelf.adColonyAdapterInitState = INIT_STATE_UNINITIALIZED;
                          NSError *error = [NSError
                              errorWithDomain:kGADMAdapterAdColonyErrorDomain
                                         code:0
                                     userInfo:@{
                                       NSLocalizedDescriptionKey : @"Failed to configure any zones."
                                     }];
                          for (GADMAdapterAdColonyInitCompletionHandler callback in callbacks) {
                            callback(error);
                          }
                        } else {
                          strongSelf.adColonyAdapterInitState = INIT_STATE_INITIALIZED;
                          for (GADMAdapterAdColonyInitCompletionHandler callback in callbacks) {
                            callback(nil);
                          }
                          strongSelf.configuredZones =
                              [strongSelf.configuredZones setByAddingObjectsFromArray:zoneIDs];
                        }
                      }
                      [strongSelf.callbacks removeObjectsInArray:callbacks];
                      [callbacks removeAllObjects];
                    }];

  dispatch_async(dispatch_get_main_queue(), ^{
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(clearCalledConfigureInLastFiveSeconds)
                                   userInfo:nil
                                    repeats:NO];
  });
}

- (void)clearCalledConfigureInLastFiveSeconds {
  _calledConfigureInLastFiveSeconds = NO;
}

@end

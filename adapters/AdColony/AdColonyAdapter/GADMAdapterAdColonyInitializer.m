//
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMAdapterAdColonyInitializer.h"

#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyHelper.h"

@implementation GADMAdapterAdColonyInitializer {
  /// AdColony zones that have already been configured.
  NSMutableSet<NSString *> *_configuredZones;

  /// AdColony SDK init state.
  GADMAdapterAdColonyInitState _adColonyAdapterInitState;

  /// An array of AdColony adapter initialization completion handler.
  NSMutableArray<GADMAdapterAdColonyInitCompletionHandler> *_callbacks;

  /// Holds whether there are new zones that need to be configured or not.
  BOOL _hasNewZones;

  /// Holds whether the AdColony SDK configuration is called within the last 5 seconds or not.
  BOOL _calledConfigureInLastFiveSeconds;

  /// Serial dispatch queue.
  dispatch_queue_t _lockQueue;

  /// A mutable set of all known zones that need to be configured on AdColony's SDK.
  NSMutableSet<NSString *> *_zonesToBeConfigured;
}

+ (nonnull GADMAdapterAdColonyInitializer *)sharedInstance {
  static dispatch_once_t onceToken;
  static GADMAdapterAdColonyInitializer *instance;
  dispatch_once(&onceToken, ^{
    instance = [[GADMAdapterAdColonyInitializer alloc] init];
  });
  return instance;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    _configuredZones = [[NSMutableSet alloc] init];
    _zonesToBeConfigured = [NSMutableSet set];
    _callbacks = [[NSMutableArray alloc] init];
    _adColonyAdapterInitState = GADMAdapterAdColonyInitStateUninitialized;
    _lockQueue = dispatch_queue_create("adColony-initializer", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)initializeAdColonyWithAppId:(nonnull NSString *)appId
                              zones:(nonnull NSArray<NSString *> *)newZones
                            options:(nonnull AdColonyAppOptions *)options
                           callback:(nonnull GADMAdapterAdColonyInitCompletionHandler)callback {
  dispatch_async(_lockQueue, ^{
    NSSet<NSString *> *newZonesSet = [NSSet setWithArray:newZones];
    self->_hasNewZones = ![newZonesSet isSubsetOfSet:self->_configuredZones];

    if (!self->_hasNewZones) {
      if (options) {
        [AdColony setAppOptions:options];
      }

      if (self->_adColonyAdapterInitState == GADMAdapterAdColonyInitStateInitialized) {
        callback(nil);
      } else if (self->_adColonyAdapterInitState == GADMAdapterAdColonyInitStateInitializing) {
        GADMAdapterAdColonyMutableArrayAddObject(self->_callbacks, callback);
      }

      return;
    }

    GADMAdapterAdColonyMutableSetAddObjectsFromArray(self->_zonesToBeConfigured,
                                                     newZonesSet.allObjects);
    if (self->_calledConfigureInLastFiveSeconds) {
      NSString *errorString =
          @"The AdColony SDK does not support being configured twice within a five second period. "
          @"This error can be mitigated by waiting for the Google Mobile Ads SDK's initialization "
          @"completion handler to be called prior to loading ads.";
      NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(
          GADMAdapterAdColonyErrorConfigureRateLimit, errorString);
      callback(error);
      return;
    }

    self->_adColonyAdapterInitState = GADMAdapterAdColonyInitStateInitializing;
    GADMAdapterAdColonyMutableArrayAddObject(self->_callbacks, callback);
    [self configureWithAppID:appId zoneIDs:self->_zonesToBeConfigured.allObjects options:options];
  });
}

/// This method must be called on the _lockQueue dispatch queue to avoid race conditions.
- (void)configureWithAppID:(nonnull NSString *)appID
                   zoneIDs:(nonnull NSArray<NSString *> *)zoneIDs
                   options:(nullable AdColonyAppOptions *)options {
  GADMAdapterAdColonyInitializer *__weak weakSelf = self;

  GADMAdapterAdColonyLog(@"Zones that are being configured: %@", zoneIDs);
  _calledConfigureInLastFiveSeconds = YES;
  [AdColony
      configureWithAppID:appID
                 zoneIDs:zoneIDs
                 options:options
              completion:^(NSArray<AdColonyZone *> *_Nonnull zones) {
                GADMAdapterAdColonyInitializer *strongSelf = weakSelf;
                if (!strongSelf) {
                  return;
                }
                dispatch_async(strongSelf->_lockQueue, ^{
                  NSError *error = nil;
                  if (zones.count) {
                    strongSelf->_adColonyAdapterInitState = GADMAdapterAdColonyInitStateInitialized;
                    for (AdColonyZone *zone in zones) {
                      NSString *zoneID = zone.identifier;
                      GADMAdapterAdColonyMutableSetAddObject(strongSelf->_configuredZones, zoneID);
                    }
                  } else {
                    strongSelf->_adColonyAdapterInitState =
                        GADMAdapterAdColonyInitStateUninitialized;
                    error = GADMAdapterAdColonyErrorWithCodeAndDescription(
                        GADMAdapterAdColonyErrorInitialization, @"Failed to configure all zones.");
                  }

                  for (GADMAdapterAdColonyInitCompletionHandler callback in strongSelf
                           ->_callbacks) {
                    callback(error);
                  }
                  [strongSelf->_callbacks removeAllObjects];
                });
              }];

  dispatch_after(GADMAdapterAdColonyDispatchTimeForInterval(5), _lockQueue, ^{
    // TODO: Discuss with AdColony if they can change their configure call to send a callback if
    // called a second time within a 5 second span. Alternatively, discuss with AdColony what the
    // side effects are of attempting to call configure every 5 seconds. By not retrying here, there
    // is a corner case where bidding zones are never initialized.
    self->_calledConfigureInLastFiveSeconds = NO;
  });
}

@end

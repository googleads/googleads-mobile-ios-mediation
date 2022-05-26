// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterTapjoySingleton.h"

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADMAdapterTapjoyConstants.h"
#import "GADMAdapterTapjoyDelegate.h"
#import "GADMAdapterTapjoyUtils.h"

@implementation GADMAdapterTapjoySingleton {
  /// Map table to hold the interstitial and rewarded ad delegates with placement name as key.
  NSMapTable<NSString *, id<GADMAdapterTapjoyDelegate>> *_adapterDelegates;

  /// Array to hold the Tapjoy SDK initialization delegates.
  NSMutableArray<TapjoyInitCompletionHandler> *_completionHandlers;

  /// Tapjoy SDK initialization state.
  GADMAdapterTapjoyInitState _initState;

  /// Serializes instance variable usage.
  dispatch_queue_t _lockQueue;
}

+ (nonnull instancetype)sharedInstance {
  static GADMAdapterTapjoySingleton *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[self alloc] init];
  });
  return sharedMyManager;
}

- (nonnull instancetype)init {
  if (self = [super init]) {
    _adapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                              valueOptions:NSPointerFunctionsWeakMemory];
    _completionHandlers = [[NSMutableArray alloc] init];
    _initState = GADMAdapterTapjoyInitStateUninitialized;
    _lockQueue = dispatch_queue_create("tapjoy-singleton", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)initializeTapjoySDKWithSDKKey:(nonnull NSString *)sdkKey
                              options:(nullable NSDictionary<NSString *, NSNumber *> *)options
                    completionHandler:(nullable TapjoyInitCompletionHandler)completionHandler {
  if (_initState == GADMAdapterTapjoyInitStateInitialized) {
    completionHandler(nil);
    return;
  }

  GADMAdapterTapjoyMutableArrayAddObject(_completionHandlers, completionHandler);
  if (_initState == GADMAdapterTapjoyInitStateInitializing) {
    return;
  }

  [self setupListeners];
  _initState = GADMAdapterTapjoyInitStateInitializing;
  if (options) {
    [Tapjoy connect:sdkKey options:options];
  } else {
    [Tapjoy connect:sdkKey];
  }
}

- (void)setupListeners {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tjcConnectSuccess:)
                                               name:TJC_CONNECT_SUCCESS
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tjcConnectFail:)
                                               name:TJC_CONNECT_FAILED
                                             object:nil];
}

- (void)tjcConnectSuccess:(nonnull NSNotification *)notifyObj {
  _initState = GADMAdapterTapjoyInitStateInitialized;
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_SUCCESS object:nil];
  for (TapjoyInitCompletionHandler completionHandler in _completionHandlers) {
    completionHandler(nil);
  }
  [_completionHandlers removeAllObjects];
}

- (void)tjcConnectFail:(nonnull NSNotification *)notifyObj {
  _initState = GADMAdapterTapjoyInitStateUninitialized;
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_FAILED object:nil];

  NSError *adapterError = GADMAdapterTapjoyErrorWithCodeAndDescription(
      GADMAdapterTapjoyErrorInitializationFailure, @"Tapjoy SDK failed to initialize.");
  for (TapjoyInitCompletionHandler completionHandler in _completionHandlers) {
    completionHandler(adapterError);
  }
  [_completionHandlers removeAllObjects];
}

- (nullable TJPlacement *)requestAdForPlacementName:(nonnull NSString *)placementName
                                        bidResponse:(nullable NSString *)bidResponse
                                           delegate:
                                               (nonnull id<GADMAdapterTapjoyDelegate>)delegate {
  if ([self getDelegateForPlacementName:placementName]) {
    NSError *adapterError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorAdAlreadyLoaded,
        @"A request is already in processing for same placement name. "
        @"Can't make a new request for the same placement name.");
    [delegate didFailToLoadWithError:adapterError];
    return nil;
  }

  [self addDelegate:delegate forPlacementName:placementName];
  TJPlacement *tjPlacement = [TJPlacement placementWithName:placementName
                                             mediationAgent:GADMAdapterTapjoyMediationAgent
                                                mediationId:nil
                                                   delegate:self];
  tjPlacement.adapterVersion = GADMAdapterTapjoyVersion;
  tjPlacement.videoDelegate = self;
  if (bidResponse) {
    NSData *data = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary<id, id> *responseData =
        [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];

    NSDictionary<NSString *, id> *auctionData =
        GADMAdapterTapjoyAuctionDataForResponseData(responseData);
    tjPlacement.auctionData = auctionData;
  }
  [tjPlacement requestContent];
  return tjPlacement;
}

- (nullable TJPlacement *)
    requestAdForPlacementName:(nonnull NSString *)placementName
                     delegate:(nonnull id<TJPlacementDelegate, TJPlacementVideoDelegate>)delegate {
  return [self requestAdForPlacementName:placementName bidResponse:nil delegate:delegate];
}

- (void)addDelegate:(nonnull id<TJPlacementDelegate, TJPlacementVideoDelegate>)delegate
    forPlacementName:(nonnull NSString *)placementName {
  dispatch_async(_lockQueue, ^{
    GADMAdapterTapjoyMapTableSetObjectForKey(self->_adapterDelegates, placementName, delegate);
  });
}

- (void)removeDelegateForPlacementName:(nonnull NSString *)placementName {
  dispatch_async(_lockQueue, ^{
    GADMAdapterTapjoyMapTableRemoveObjectForKey(self->_adapterDelegates, placementName);
  });
}

- (BOOL)containsDelegateForPlacementName:(nonnull NSString *)placementName {
  __block BOOL containsDelegate = NO;
  dispatch_sync(_lockQueue, ^{
    if ([self->_adapterDelegates objectForKey:placementName]) {
      containsDelegate = YES;
    } else {
      containsDelegate = NO;
    }
  });
  return containsDelegate;
}

- (nullable id<TJPlacementDelegate, TJPlacementVideoDelegate>)getDelegateForPlacementName:
    (nonnull NSString *)placementName {
  __block id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate = nil;
  dispatch_sync(_lockQueue, ^{
    delegate = [self->_adapterDelegates objectForKey:placementName];
  });
  return delegate;
}

#pragma mark - TJPlacementDelegate methods
- (void)requestDidSucceed:(nonnull TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate requestDidSucceed:placement];
}

- (void)requestDidFail:(nonnull TJPlacement *)placement error:(nullable NSError *)error {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [self removeDelegateForPlacementName:placement.placementName];
  if (!error) {
    NSError *nullError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorUnknown, @"Tapjoy SDK placement unknown error.");
    [delegate requestDidFail:placement error:nullError];
    return;
  }
  [delegate requestDidFail:placement error:error];
}

- (void)contentIsReady:(nonnull TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate contentIsReady:placement];
}

- (void)contentDidAppear:(nonnull TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate contentDidAppear:placement];
}

- (void)didClick:(TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate didClick:placement];
}

- (void)contentDidDisappear:(nonnull TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [self removeDelegateForPlacementName:placement.placementName];
  [delegate contentDidDisappear:placement];
}

#pragma mark - Tapjoy Video

- (void)videoDidStart:(nonnull TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate videoDidStart:placement];
}

- (void)videoDidComplete:(nonnull TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate videoDidComplete:placement];
}

- (void)videoDidFail:(nonnull TJPlacement *)placement error:(nullable NSString *)errorMsg {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [self removeDelegateForPlacementName:placement.placementName];
  if (!errorMsg) {
    NSString *nullError = @"Tapjoy SDK placement unknown error.";
    [delegate videoDidFail:placement error:nullError];
    return;
  }
  [delegate videoDidFail:placement error:errorMsg];
}

@end

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

#import "GADMAdapterTapjoyConstants.h"
#import "GADMAdapterTapjoyUtils.h"

@implementation GADMAdapterTapjoySingleton {
  /// Map table to hold the interstitial and rewarded ad delegates with placement name as key.
  NSMapTable<NSString *, id<TJPlacementDelegate, TJPlacementVideoDelegate>> *_adapterDelegates;

  /// Array to hold the Tapjoy SDK initialization delegates.
  NSMutableArray<TapjoyInitCompletionHandler> *_completionHandlers;

  /// Tapjoy SDK initialization state.
  TapjoyInitState _initState;
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
    _initState = UNINITIALIZED;
  }
  return self;
}

- (void)initializeTapjoySDKWithSDKKey:(nonnull NSString *)sdkKey
                              options:(nonnull NSDictionary<NSString *, NSNumber *> *)options
                    completionHandler:(nullable TapjoyInitCompletionHandler)completionHandler {
  if (_initState == INITIALIZED) {
    completionHandler(nil);
    return;
  } else if (_initState == INITIALIZING) {
    GADMAdapterTapjoyMutableArrayAddObject(_completionHandlers, completionHandler);
    return;
  } else if (_initState == UNINITIALIZED) {
    [self setupListeners];
    GADMAdapterTapjoyMutableArrayAddObject(_completionHandlers, completionHandler);
    [Tapjoy connect:sdkKey options:options];
    _initState = INITIALIZING;
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
  _initState = INITIALIZED;
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_SUCCESS object:nil];
  for (TapjoyInitCompletionHandler completionHandler in _completionHandlers) {
    completionHandler(nil);
  }
  [_completionHandlers removeAllObjects];
}

- (void)tjcConnectFail:(nonnull NSNotification *)notifyObj {
  _initState = UNINITIALIZED;
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_FAILED object:nil];
  NSError *adapterError =
      [NSError errorWithDomain:kGADMAdapterTapjoyErrorDomain
                          code:0
                      userInfo:@{NSLocalizedDescriptionKey : @"Tapjoy Connect failed."}];
  for (TapjoyInitCompletionHandler completionHandler in _completionHandlers) {
    completionHandler(adapterError);
  }
  [_completionHandlers removeAllObjects];
}

- (nullable TJPlacement *)
    requestAdForPlacementName:(nonnull NSString *)placementName
                  bidResponse:(nullable NSString *)bidResponse
                     delegate:(nonnull id<TJPlacementDelegate, TJPlacementVideoDelegate>)delegate {
  if ([self getDelegateForPlacementName:placementName]) {
    NSError *adapterError =
        [NSError errorWithDomain:kGADMAdapterTapjoyErrorDomain
                            code:0
                        userInfo:@{
                          NSLocalizedDescriptionKey :
                              @"A request is already in processing for same placement name. Can't "
                              @"make a new request for the same placement name."
                        }];
    [delegate requestDidFail:nil error:adapterError];
    return nil;
  }

  [self addDelegate:delegate forPlacementName:placementName];
  TJPlacement *tjPlacement = [TJPlacement placementWithName:placementName
                                             mediationAgent:kGADMAdapterTapjoyMediationAgent
                                                mediationId:nil
                                                   delegate:self];
  tjPlacement.adapterVersion = kGADMAdapterTapjoyVersion;
  tjPlacement.videoDelegate = self;
  if (bidResponse) {
    NSData *data = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingAllowFragments
                                                                   error:nil];

    NSDictionary *auctionData = @{
      TJ_AUCTION_DATA : responseData[TJ_AUCTION_DATA],
      TJ_AUCTION_ID : responseData[TJ_AUCTION_ID]
    };
    [tjPlacement setAuctionData:auctionData];
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
  @synchronized(_adapterDelegates) {
    [_adapterDelegates setObject:delegate forKey:placementName];
  }
}

- (void)removeDelegateForPlacementName:(nonnull NSString *)placementName {
  @synchronized(_adapterDelegates) {
    GADMAdapterTapjoyMapTableRemoveObjectForKey(_adapterDelegates, placementName);
  }
}

- (BOOL)containsDelegateForPlacementName:(nonnull NSString *)placementName {
  @synchronized(_adapterDelegates) {
    if ([_adapterDelegates objectForKey:placementName]) {
      return YES;
    } else {
      return NO;
    }
  }
}

- (nullable id<TJPlacementDelegate, TJPlacementVideoDelegate>)getDelegateForPlacementName:
    (nonnull NSString *)placementName {
  @synchronized(_adapterDelegates) {
    return [_adapterDelegates objectForKey:placementName];
  }
}

#pragma mark - TJPlacementDelegate methods
- (void)requestDidSucceed:(nonnull TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate requestDidSucceed:placement];
}

- (void)requestDidFail:(nonnull TJPlacement *)placement error:(nonnull NSError *)error {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [self removeDelegateForPlacementName:placement.placementName];
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

- (void)contentDidDisappear:(nonnull TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [self removeDelegateForPlacementName:placement.placementName];
  [delegate contentDidDisappear:placement];
}

#pragma mark Tapjoy Video
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

- (void)videoDidFail:(nonnull TJPlacement *)placement error:(nonnull NSString *)errorMsg {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [self removeDelegateForPlacementName:placement.placementName];
  [delegate videoDidFail:placement error:errorMsg];
}

@end

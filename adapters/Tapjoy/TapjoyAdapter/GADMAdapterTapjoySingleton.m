// Copyright 2019 Google LLC.
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

@interface GADMAdapterTapjoySingleton ()

@property(nonatomic)
    NSMapTable<NSString *, id<TJPlacementDelegate, TJPlacementVideoDelegate>> *adapterDelegates;
@property(nonatomic) NSMutableArray<TapjoyInitCompletionHandler> *completionHandlers;
@property(nonatomic) TapjoyInitState initState;

@end
@implementation GADMAdapterTapjoySingleton

+ (instancetype)sharedInstance {
  static GADMAdapterTapjoySingleton *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[self alloc] init];
  });
  return sharedMyManager;
}

- (instancetype)init {
  if (self = [super init]) {
    self.adapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                  valueOptions:NSPointerFunctionsWeakMemory];
    self.completionHandlers = [[NSMutableArray alloc] init];
    self.initState = UNINITIALIZED;
  }
  return self;
}

- (void)initializeTapjoySDKWithSDKKey:(NSString *)sdkKey
                              options:(NSDictionary<NSString *, NSNumber *> *)options
                    completionHandler:(TapjoyInitCompletionHandler)completionHandler {
  if (_initState == INITIALIZED) {
    completionHandler(nil);
    return;
  } else if (_initState == INITIALIZING) {
    [self.completionHandlers addObject:completionHandler];
    return;
  } else if (_initState == UNINITIALIZED) {
    [self setupListeners];
    [self.completionHandlers addObject:completionHandler];
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

- (void)tjcConnectSuccess:(NSNotification *)notifyObj {
  _initState = INITIALIZED;
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_SUCCESS object:nil];
  for (TapjoyInitCompletionHandler completionHandler in _completionHandlers) {
    completionHandler(nil);
  }
  [_completionHandlers removeAllObjects];
}

- (void)tjcConnectFail:(NSNotification *)notifyObj {
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

- (TJPlacement *)requestAdForPlacementName:(NSString *)placementName
                                  delegate:
                                      (id<TJPlacementDelegate, TJPlacementVideoDelegate>)delegate {
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
  [tjPlacement requestContent];
  return tjPlacement;
}

- (void)addDelegate:(id<TJPlacementDelegate, TJPlacementVideoDelegate>)delegate
    forPlacementName:(NSString *)placementName;
{
  @synchronized(self.adapterDelegates) {
    [self.adapterDelegates setObject:delegate forKey:placementName];
  }
}

- (void)removeDelegateForPlacementName:(NSString *)placementName {
  @synchronized(self.adapterDelegates) {
    [self.adapterDelegates removeObjectForKey:placementName];
  }
}

- (BOOL)containsDelegateForPlacementName:(NSString *)placementName {
  @synchronized(self.adapterDelegates) {
    if ([self.adapterDelegates objectForKey:placementName]) {
      return YES;
    } else {
      return NO;
    }
  }
}

- (id<TJPlacementDelegate, TJPlacementVideoDelegate>)getDelegateForPlacementName:
    (NSString *)placementName {
  @synchronized(_adapterDelegates) {
    return [_adapterDelegates objectForKey:placementName];
  }
}

#pragma mark - TJPlacementDelegate methods
- (void)requestDidSucceed:(TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate requestDidSucceed:placement];
}

- (void)requestDidFail:(TJPlacement *)placement error:(NSError *)error {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [self removeDelegateForPlacementName:placement.placementName];
  [delegate requestDidFail:placement error:error];
}

- (void)contentIsReady:(TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate contentIsReady:placement];
}

- (void)contentDidAppear:(TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate contentDidAppear:placement];
}

- (void)contentDidDisappear:(TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [self removeDelegateForPlacementName:placement.placementName];
  [delegate contentDidDisappear:placement];
}

#pragma mark Tapjoy Video
- (void)videoDidStart:(TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate videoDidStart:placement];
}

- (void)videoDidComplete:(TJPlacement *)placement {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [delegate videoDidComplete:placement];
}

- (void)videoDidFail:(TJPlacement *)placement error:(NSString *)errorMsg {
  id<TJPlacementDelegate, TJPlacementVideoDelegate> delegate =
      [self getDelegateForPlacementName:placement.placementName];
  [self removeDelegateForPlacementName:placement.placementName];
  [delegate videoDidFail:placement error:errorMsg];
}

@end

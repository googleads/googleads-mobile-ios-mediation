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

#import "GADMAdapterMaioAdsManager.h"
#import "GADMMaioConstants.h"
#import "GADMMaioError.h"

@interface GADMAdapterMaioAdsManager ()

@property(nonatomic, copy) NSString *mediaId;
@property(nonatomic, strong) NSMapTable<NSString *, id<MaioDelegate>> *adapterDelegates;
@property(nonatomic) MaioInitState initState;
@property(nonatomic, strong) NSMutableArray<MaioInitCompletionHandler> *completionHandlers;
@property(nonatomic, strong) MaioInstance *maioInstance;

@end

@implementation GADMAdapterMaioAdsManager

static NSMutableDictionary<NSString *, GADMAdapterMaioAdsManager *> *instances;

+ (void)load {
  instances = [[NSMutableDictionary alloc] init];
}

+ (GADMAdapterMaioAdsManager *)getMaioAdsManagerByMediaId:(NSString *)mediaId {
  @synchronized(instances) {
    GADMAdapterMaioAdsManager *instance = instances[mediaId];
    if (!instance) {
      instance = [[GADMAdapterMaioAdsManager alloc] initWithMediaId:mediaId];
      instances[mediaId] = instance;
    }
    return instance;
  }
}

- (instancetype)initWithMediaId:(NSString *)mediaId {
  self = [super init];
  if (self) {
    self.mediaId = mediaId;
    self.adapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                  valueOptions:NSPointerFunctionsWeakMemory];
    self.initState = UNINITIALIZED;
    self.completionHandlers = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)initializeMaioSDKWithCompletionHandler:(MaioInitCompletionHandler)completionHandler {
  if (self.initState == INITIALIZED) {
    completionHandler(nil);
    return;
  }

  if (self.initState != INITIALIZING) {
    self.maioInstance = [Maio startWithNonDefaultMediaId:self.mediaId delegate:self];
    self.initState = INITIALIZING;
  }
  @synchronized(self.completionHandlers) {
    [self.completionHandlers addObject:completionHandler];
  }
}

- (void)removeAdapterForZoneID:(NSString *)zoneId {
  @synchronized(self.adapterDelegates) {
    [self.adapterDelegates removeObjectForKey:zoneId];
  }
}

- (void)setAdTestMode:(BOOL)adTestMode {
  [self.maioInstance setAdTestMode:adTestMode];
}

- (void)addAdapter:(id<MaioDelegate>)delegate forZoneID:(NSString *)zoneId {
  @synchronized(self.adapterDelegates) {
    [self.adapterDelegates setObject:delegate forKey:zoneId];
  }
}

- (id<MaioDelegate>)getAdapterForZoneID:(NSString *)zoneId {
  @synchronized(self.adapterDelegates) {
    return [self.adapterDelegates objectForKey:zoneId];
  }
}

- (NSError *)loadAdForZoneId:(NSString *)zoneId delegate:(id<MaioDelegate>)delegate {
  if ([self getAdapterForZoneID:zoneId]) {
    NSString *errorDesc =
        [NSString stringWithFormat:@"Maio does not supporting requesting a second ad for the same "
                                   @"zone ID while the first request is still in progress."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    return [NSError errorWithDomain:kGADMMaioErrorDomain code:0 userInfo:errorInfo];
  } else {
    [self addAdapter:delegate forZoneID:zoneId];
  }

  if ([self.maioInstance canShowAtZoneId:zoneId]) {
    [delegate maioDidChangeCanShow:zoneId newValue:YES];
  }
  return nil;
}

- (void)showAdForZoneId:(NSString *)zoneId rootViewController:(UIViewController *)viewcontroller {
  id<MaioDelegate> delegate = [self getAdapterForZoneID:zoneId];
  if (delegate && [self.maioInstance canShowAtZoneId:zoneId]) {
    [self.maioInstance showAtZoneId:zoneId vc:viewcontroller];
  }
}

#pragma mark - MaioDelegate

- (void)maioDidInitialize {
  self.initState = INITIALIZED;

  NSArray<MaioInitCompletionHandler> *completionHandlersToCall = [self.completionHandlers copy];
  for (MaioInitCompletionHandler completionhandler in completionHandlersToCall) {
    completionhandler(nil);
  }
  [self.completionHandlers removeObjectsInArray:completionHandlersToCall];
}

- (void)maioDidChangeCanShow:(NSString *)zoneId newValue:(BOOL)newValue {
  id<MaioDelegate> delegate = [self getAdapterForZoneID:zoneId];
  if (delegate && [delegate respondsToSelector:@selector(maioDidChangeCanShow:newValue:)]) {
    [delegate maioDidChangeCanShow:zoneId newValue:newValue];
  }
}

- (void)maioWillStartAd:(NSString *)zoneId {
  id<MaioDelegate> delegate = [self getAdapterForZoneID:zoneId];
  if (delegate && [delegate respondsToSelector:@selector(maioWillStartAd:)]) {
    [delegate maioWillStartAd:zoneId];
  }
}

- (void)maioDidFinishAd:(NSString *)zoneId
               playtime:(NSInteger)playtime
                skipped:(BOOL)skipped
            rewardParam:(NSString *)rewardParam {
  id<MaioDelegate> delegate = [self getAdapterForZoneID:zoneId];
  if (delegate && [delegate respondsToSelector:@selector(maioDidFinishAd:
                                                                playtime:skipped:rewardParam:)]) {
    [delegate maioDidFinishAd:zoneId playtime:playtime skipped:skipped rewardParam:rewardParam];
  }
}

- (void)maioDidClickAd:(NSString *)zoneId {
  id<MaioDelegate> delegate = [self getAdapterForZoneID:zoneId];
  if (delegate && [delegate respondsToSelector:@selector(maioDidClickAd:)]) {
    [delegate maioDidClickAd:zoneId];
  }
}

- (void)maioDidCloseAd:(NSString *)zoneId {
  id<MaioDelegate> delegate = [self getAdapterForZoneID:zoneId];
  [self removeAdapterForZoneID:zoneId];
  if (delegate && [delegate respondsToSelector:@selector(maioDidCloseAd:)]) {
    [delegate maioDidCloseAd:zoneId];
  }
}

- (void)maioDidFail:(NSString *)zoneId reason:(MaioFailReason)reason {
  id<MaioDelegate> delegate = [self getAdapterForZoneID:zoneId];
  [self removeAdapterForZoneID:zoneId];
  if (delegate && [delegate respondsToSelector:@selector(maioDidFail:reason:)]) {
    [delegate maioDidFail:zoneId reason:reason];
  }
}

@end

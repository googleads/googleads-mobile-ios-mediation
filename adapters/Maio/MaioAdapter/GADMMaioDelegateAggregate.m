//
//  GADMMaioDelegateAggregate.m
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioDelegateAggregate.h"

@implementation GADMMaioDelegateAggregate
static GADMMaioDelegateAggregate *_instance = nil;

+ (instancetype)sharedInstance {
  if (!_instance) {
    _instance = [GADMMaioDelegateAggregate new];
  }
  return _instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.delegates = [NSHashTable weakObjectsHashTable];
  }
  return self;
}

#pragma mark - MaioDelegate

- (void)maioDidInitialize {
  for (id<MaioDelegate> delegate in self.delegates.allObjects) {
    if ([delegate respondsToSelector:@selector(maioDidInitialize)]) {
      [delegate maioDidInitialize];
    }
  }
}

- (void)maioDidChangeCanShow:(NSString *)zoneId newValue:(BOOL)newValue {
  for (id<MaioDelegate> delegate in self.delegates.allObjects) {
    if ([delegate
            respondsToSelector:@selector(maioDidChangeCanShow:newValue:)]) {
      [delegate maioDidChangeCanShow:zoneId newValue:newValue];
    }
  }
}

- (void)maioWillStartAd:(NSString *)zoneId {
  for (id<MaioDelegate> delegate in self.delegates.allObjects) {
    if ([delegate respondsToSelector:@selector(maioWillStartAd:)]) {
      [delegate maioWillStartAd:zoneId];
    }
  }
}

- (void)maioDidFinishAd:(NSString *)zoneId
               playtime:(NSInteger)playtime
                skipped:(BOOL)skipped
            rewardParam:(NSString *)rewardParam {
  for (id<MaioDelegate> delegate in self.delegates.allObjects) {
    if ([delegate respondsToSelector:@selector
                  (maioDidFinishAd:playtime:skipped:rewardParam:)]) {
      [delegate maioDidFinishAd:zoneId
                       playtime:playtime
                        skipped:skipped
                    rewardParam:rewardParam];
    }
  }
}

- (void)maioDidClickAd:(NSString *)zoneId {
  for (id<MaioDelegate> delegate in self.delegates.allObjects) {
    if ([delegate respondsToSelector:@selector(maioDidClickAd:)]) {
      [delegate maioDidClickAd:zoneId];
    }
  }
}

- (void)maioDidCloseAd:(NSString *)zoneId {
  for (id<MaioDelegate> delegate in self.delegates.allObjects) {
    if ([delegate respondsToSelector:@selector(maioDidCloseAd:)]) {
      [delegate maioDidCloseAd:zoneId];
    }
  }
}

- (void)maioDidFail:(NSString *)zoneId reason:(MaioFailReason)reason {
  for (id<MaioDelegate> delegate in self.delegates.allObjects) {
    if ([delegate respondsToSelector:@selector(maioDidFail:reason:)]) {
      [delegate maioDidFail:zoneId reason:reason];
    }
  }
}

@end

//
//  GADMAdapterAppLovinQueue.m
//
//
//  Created by Thomas So on 10/27/16.
//
//

#import "GADMAdapterAppLovinQueue.h"

@interface GADMAdapterAppLovinQueue ()
@property(nonatomic, strong) NSMutableArray *backingArray;
@property(nonatomic, strong) NSObject *lock;
@end

@implementation GADMAdapterAppLovinQueue
@dynamic empty, count;
@dynamic firstObject, lastObject;

static const NSUInteger ALQueueDefaultCapacity = 32;

#pragma mark - Initialization

+ (instancetype)queue {
  return [self queueWithCapacity:ALQueueDefaultCapacity];
}

+ (instancetype)queueWithCapacity:(NSUInteger)capacity {
  return [[GADMAdapterAppLovinQueue alloc] initWithCapacity:capacity];
}

- (instancetype)init {
  return [self initWithCapacity:ALQueueDefaultCapacity];
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
  self = [super init];
  if (self) {
    self.backingArray = [NSMutableArray arrayWithCapacity:capacity];
    self.lock = [[NSObject alloc] init];
  }
  return self;
}

#pragma mark - Queue Specific Methods

- (void)enqueue:(id)item {
  @synchronized(self.lock) {
    if (item) {
      [self.backingArray addObject:item];
    } else {
      [NSException raise:NSInvalidArgumentException
                  format:@"[%s]: attempt to insert nil value", __PRETTY_FUNCTION__];
    }
  }
}

- (void)enqueueObjectsFromArray:(NSArray *)array {
  @synchronized(self.lock) {
    [self.backingArray addObjectsFromArray:array];
  }
}

- (nullable id)dequeue {
  @synchronized(self.lock) {
    if (self.count > 0) {
      id obj = self.backingArray[0];
      [self.backingArray removeObjectAtIndex:0];
      return obj;
    }

    return nil;
  }
}

#pragma mark - Object Retrieval

- (nullable id)firstObject {
  @synchronized(self.lock) {
    if (self.count > 0) {
      return self.backingArray[0];
    }

    return nil;
  }
}

- (nullable id)lastObject {
  @synchronized(self.lock) {
    if (self.count > 0) {
      return self.backingArray[self.count - 1];
    }

    return nil;
  }
}

- (nullable id)objectAtIndex:(NSUInteger)index {
  @synchronized(self.lock) {
    if (index < self.count) {
      return self.backingArray[index];
    } else {
      [NSException raise:NSRangeException
                  format:@"[%s]: attempt to index stack of size %lu at index %lu",
                         __PRETTY_FUNCTION__, (unsigned long)self.count, (unsigned long)index];
      return nil;
    }
  }
}

#pragma mark - Dynamic Properties

- (NSUInteger)count {
  @synchronized(self.lock) {
    return self.backingArray.count;
  }
}

- (BOOL)isEmpty {
  @synchronized(self.lock) {
    return self.backingArray.count == 0;
  }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  GADMAdapterAppLovinQueue *copy = [[[self class] allocWithZone:zone] init];
  copy.backingArray = [self.backingArray copy];
  copy.lock = [[NSObject alloc] init];

  return copy;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if (self) {
    self.backingArray = [aDecoder decodeObjectForKey:@"backingArray"];
    self.lock = [[NSObject alloc] init];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.backingArray forKey:@"backingArray"];
}

#pragma mark - Description

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@> %@", NSStringFromClass([self class]), self.backingArray];
}

@end

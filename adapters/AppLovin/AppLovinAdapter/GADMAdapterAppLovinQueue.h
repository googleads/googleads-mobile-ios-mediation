//
//  GADMAdapterAppLovinQueue.h
//
//
//  Created by Thomas So on 10/27/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterAppLovinQueue<ObjectType> : NSObject <NSCopying, NSCoding>

#pragma mark - Initialization

+ (instancetype)queue;
+ (instancetype)queueWithCapacity:(NSUInteger)capacity;
- (instancetype)initWithCapacity:(NSUInteger)capacity;

#pragma mark - Queue Specific Methods

- (void)enqueue:(ObjectType)item;
- (void)enqueueObjectsFromArray:(NSArray<ObjectType> *)array;
- (nullable ObjectType)dequeue;

#pragma mark - Object Retrieval

@property(nonatomic, assign, readonly) NSUInteger count;
@property(nonatomic, assign, readonly, getter=isEmpty) BOOL empty;

@property(nonatomic, strong, readonly, nullable) ObjectType firstObject;
@property(nonatomic, strong, readonly, nullable) ObjectType lastObject;
- (nullable ObjectType)objectAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

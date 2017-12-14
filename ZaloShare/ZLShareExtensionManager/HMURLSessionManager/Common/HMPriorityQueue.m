//
//  HMPriorityQueue.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/7/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMPriorityQueue.h"
#import <Foundation/Foundation.h>

@interface HMPriorityQueue<ObjectType>()

@property(strong, nonatomic) NSMutableArray<ObjectType> *array;

@end

@implementation HMPriorityQueue

- (instancetype)init {
    if (self = [super init]) {
        _array = [NSMutableArray new];
    }
    return self;
}

- (void)pushObject:(id)object {
    NSAssert(object, @"[HM] HMPriorityQueue - Can't add nil to priority queue");
    NSInteger addIndex = [self binaryFindIndexWithObject:object fromIndex:0 toIndex:_array.count];
    [_array insertObject:object atIndex:addIndex];
}

- (id)popObject {
    if (_array.count == 0) {
        return nil;
    }
    
    id object = [_array objectAtIndex:0];
    [_array removeObjectAtIndex:0];
    return object;
}

- (void)removeObject:(id)object {
    if (!object) {
        return;
    }
    
    [_array removeObject:object];
}

- (BOOL)containsObject:(id)object {
    if (!object) {
        return NO;
    }
    
    return [_array containsObject:object];
}

- (NSArray *)allObjects {
    return [_array copy];
}

#pragma mark - Set attributes

- (NSUInteger)count {
    return _array.count;
}

#pragma mark - Private

//Find a location to insert a new object that does not change the priority of the list with binary search algorithm
- (NSInteger)binaryFindIndexWithObject:(id)object fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSInteger midIndex = (toIndex - fromIndex) / 2 + fromIndex;
    
    if (fromIndex >= toIndex) {
        return toIndex;
    }
    
    if ([_array[midIndex] compare:object] == NSOrderedDescending) {
        return [self binaryFindIndexWithObject:object fromIndex:fromIndex toIndex:midIndex];
        
    } else if ([_array[midIndex] compare:object] == NSOrderedAscending) {
        return [self binaryFindIndexWithObject:object fromIndex:midIndex + 1 toIndex:toIndex];
        
    } else {
        NSInteger tempIndex = midIndex + 1;
        while (tempIndex < _array.count) {
            if ([_array[tempIndex] compare:_array[midIndex]] == NSOrderedDescending) {
                return tempIndex;
            }
            
            tempIndex += 1;
        }
        
        return tempIndex;
    }
}


@end

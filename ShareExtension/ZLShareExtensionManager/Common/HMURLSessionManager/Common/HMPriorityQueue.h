//
//  HMPriorityQueue.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/7/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMPriorityQueue<ObjectType> : NSObject

@property(nonatomic, readonly) NSUInteger count;

- (void)pushObject:(ObjectType)object;
- (ObjectType)popObject;
- (void)removeObject:(ObjectType)object;
- (BOOL)containsObject:(ObjectType)object;
- (NSArray<ObjectType> *)allObjects;

@end

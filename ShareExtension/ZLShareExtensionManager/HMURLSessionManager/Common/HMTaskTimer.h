//
//  HMTaskTimer.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/12/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMTaskTimer : NSObject

+ (instancetype)taskTimerWithTimeInterval:(NSTimeInterval)timeInterval timeoutHandler:(void (^)(void))handler inQueue:(dispatch_queue_t)queue;
- (void)startMonitor;
- (void)stopMonitor;
- (void)setTimeInterval:(NSTimeInterval)timerInterval;
- (void)update;

@end

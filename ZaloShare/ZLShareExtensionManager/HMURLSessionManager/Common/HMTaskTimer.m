//
//  HMTaskTimer.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/12/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMTaskTimer.h"
#import "Constaint.h"

@interface HMTaskTimer()

@property(strong, nonatomic) NSTimer *timer;
@property(strong, nonatomic) NSDate *lastUpdate;
@property(nonatomic) NSTimeInterval timeInterval;
@property(strong, nonatomic) void(^timeoutHandler)(void);
@property(strong, nonatomic) dispatch_queue_t queue;
@property(nonatomic, getter=isMonitoring) BOOL isMonitoring;
@property(nonatomic) BOOL isTimeOut;

@end

@implementation HMTaskTimer

- (instancetype)init {
    if (self = [super init]) {
        _isTimeOut = NO;
        _isMonitoring = NO;
        _lastUpdate = nil;
        _timeInterval = 0;
        _timer = nil;
        _lastUpdate = nil;
        _timeoutHandler = nil;
        _queue = nil;
    }
    
    return self;
}

+ (instancetype)taskTimerWithTimeInterval:(NSTimeInterval)timeInterval timeoutHandler:(void (^)(void))handler inQueue:(dispatch_queue_t)queue{
    NSAssert(timeInterval >= 0, @"Time interval need to >= 0");
    HMTaskTimer *taskTimer  = [[super alloc] init];
    if (taskTimer) {
        taskTimer.timeInterval = timeInterval;
        taskTimer.timeoutHandler = handler;
        taskTimer.queue = queue ? queue : mainQueue;
    }
    
    return taskTimer;
}

- (void)startMonitor {
    @synchronized(self) {
        NSLog(@"[HM] - HMTaskTimer - Checking timeout");
        _isTimeOut = NO;
        [self update];
        
        if ([self isMonitoring]) {
            return;
        }
        
        _isMonitoring = YES;
        dispatch_async(mainQueue, ^{
            _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkTimeOut) userInfo:nil repeats:YES];
        });
    }
}

- (void)stopMonitor {
    @synchronized(self) {
        [_timer invalidate];
        _lastUpdate = nil;
    }
}

- (void)update {
    @synchronized(self) {
        if (![self isMonitoring]) {
            return;
        }
        
        NSLog(@"[HM] - HMTaskTimer - Update timeout");
        _lastUpdate = [NSDate date];
    }
}

- (void)checkTimeOut {
    NSTimeInterval betweenTimeInterval = [[NSDate date] timeIntervalSinceDate:_lastUpdate];
    if (betweenTimeInterval >= _timeInterval ) {
        NSLog(@"[HM] - HMTaskTimer - Timeout");
        _isTimeOut = YES;
        _isMonitoring = NO;
        if (_timeoutHandler) {
            dispatch_async(_queue, ^{
                _timeoutHandler();
            });
        }
        [self stopMonitor];
    }
}

- (BOOL)isMonitoring {
    return [_timer isValid];
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval {
    @synchronized(self) {
        NSAssert(timeInterval >= 0, @"Time interval need to >= 0");
        _timeInterval = timeInterval;
    }
}



@end

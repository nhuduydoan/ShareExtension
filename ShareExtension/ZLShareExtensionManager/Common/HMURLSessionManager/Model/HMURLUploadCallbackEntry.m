//
//  HMURLUploadCallbackEntry.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/8/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMURLUploadCallbackEntry.h"
#import "Constaint.h"

@interface HMURLUploadCallbackEntry()

@end

@implementation HMURLUploadCallbackEntry

- (instancetype)init {
    if (self = [super init]) {
        _unitId = [[NSUUID UUID] UUIDString];
        _queue = mainQueue;
        _callback = nil;
    }
    
    return self;
}

- (instancetype)initWithCallback:(id)callback andQueue:(dispatch_queue_t)queue {
    if (self = [self init]) {
        _queue = [self getValidQueueWithQueue:queue];
        _callback = callback;
    }
    
    return self;
}

- (instancetype _Nonnull)initWithProgressCallback:(HMURLUploadProgressBlock _Nullable)progressBlock
                               completionCallback:(HMURLUploadCompletionBlock _Nullable)completionBlock
                              changeStateCallback:(HMURLUploadChangeStateBlock _Nullable)changeStateBlock
                                         andQueue:(dispatch_queue_t _Nullable)queue {
    if (self = [self init]) {
        _progressCallback = progressBlock;
        _completionCallback = completionBlock;
        _changeStateCallback = changeStateBlock;
        _queue = [self getValidQueueWithQueue:queue];
    }
    
    return self;
}

- (dispatch_queue_t)getValidQueueWithQueue:(dispatch_queue_t)queue {
    return queue ? queue : mainQueue;
}

@end

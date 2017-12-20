//
//  HMURLUploadTask.m
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMURLUploadTask.h"
#import "Constaint.h"

@interface HMURLUploadTask()

@property(strong, nonatomic) NSMutableArray<HMURLUploadCallbackEntry *> *progressCallbacks;
@property(strong, nonatomic) NSMutableArray<HMURLUploadCallbackEntry *> *completionCallbacks;
@property(strong, nonatomic) NSMutableArray<HMURLUploadCallbackEntry *> *changeStateCallbacks;

@property(strong, nonatomic) NSMutableArray<HMURLUploadCallbackEntry *> *cbEntries;

@property(strong, nonatomic) dispatch_queue_t callbackQueue;

@end

@implementation HMURLUploadTask

- (instancetype)init {
    if (self = [super init]) {
        _taskIdentifier = [[[NSUUID UUID] UUIDString] hash];
        _totalBytes = 0;
        _sentBytes = 0;
        _currentState = HMURLUploadStateNotRunning;
        _priority = HMURLUploadTaskPriorityMedium;
        
        _progressCallbacks = [NSMutableArray new];
        _completionCallbacks = [NSMutableArray new];
        _changeStateCallbacks = [NSMutableArray new];
        
        _cbEntries = [NSMutableArray new];
    }
    return self;
}

- (instancetype)initWithTask:(NSURLSessionDataTask *)task {
    if (self = [self init]) {
        _task = task;
    }
    
    return self;
}

- (void)dealloc {
    NSLog(@"[HM] HMURLUploadTask - dealloc");
}

#pragma mark - Public

- (void)resume {
    if (_delegate) {
        [_delegate shouldToResumeHMURLUploadTask:self];
    } else {
        [_task resume];
    }
}

- (void)pause {
    if (_delegate) {
        [_delegate shouldToPauseHMURLUploadTask:self];
    } else {
        [_task suspend];
    }
}

- (void)cancel {
    if (_delegate) {
        [_delegate shouldToCancelHMURLUploadTask:self];
    }
    [_task cancel];
}

- (void)completed {
    if (_totalBytes == 0) {
        _sentBytes = _totalBytes;
    }
    _sentBytes = _totalBytes;
}

- (NSArray<HMURLUploadCallbackEntry *> *)getAllCallbackEntries {
    @synchronized(self) {
        return [_cbEntries copy];
    }
}

- (NSString *)addCallbacksWithProgressCB:(HMURLUploadProgressBlock)progressBlock
                            completionCB:(HMURLUploadCompletionBlock)completionBlock
                           changeStateCB:(HMURLUploadChangeStateBlock)changeStateBlock
                                 inQueue:(dispatch_queue_t)queue {
    
    @synchronized(self) {
        HMURLUploadCallbackEntry *cbEntry = [[HMURLUploadCallbackEntry alloc] initWithProgressCallback:progressBlock
                                                                                    completionCallback:completionBlock
                                                                                   changeStateCallback:changeStateBlock
                                                                                              andQueue:queue];
        if (!cbEntry) {
            return nil;
        }
        
        [_cbEntries addObject:cbEntry];
        return cbEntry.unitId;
    }
}

- (void)removeCallbacksWithId:(NSString *)cbEntryId {
    @synchronized(self) {
        NSUInteger index = [_cbEntries indexOfObjectPassingTest:^BOOL(HMURLUploadCallbackEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.unitId isEqualToString:cbEntryId]) {
                return YES;
            }
            
            return NO;
        }];
        
        if (index != NSNotFound) {
            [_cbEntries removeObjectAtIndex:index];
        }
    }
}

- (void)removeAllCallbackEntries {
    @synchronized(self) {
        [_cbEntries removeAllObjects];
    }
}


- (NSComparisonResult)compare:(HMURLUploadTask *)otherTask {
    if (!otherTask) {
        return NSOrderedAscending;
    }
    
    if (self.priority < otherTask.priority) {
        return NSOrderedAscending;
    } else if (self.priority > otherTask.priority) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

#pragma mark - Set attributes

- (float)uploadProgress {
    if (_totalBytes == 0) {
        return 0;
    }
    return _sentBytes / _totalBytes;
}

@end

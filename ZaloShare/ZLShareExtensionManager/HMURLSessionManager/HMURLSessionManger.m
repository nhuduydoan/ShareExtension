//
//  HMURLSessionManger.m
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMURLSessionManger.h"
#import "HMNetworkManager.h"
#import "Constaint.h"
#import "HMTaskTimer.h"
#import <UIKit/UIKit.h>

#define MaxConnection           100

@interface HMURLSessionManger() <NSURLSessionTaskDelegate, HMURLUploadDelegate>

@property(nonatomic) NSUInteger maxConcurrentUploadTask;

@property(strong, nonatomic) NSURLSession *session;
@property(strong, nonatomic) NSOperationQueue *operationQueue;
@property(strong, nonatomic) NSMutableDictionary *uploadTaskMapping;
@property(strong, nonatomic) HMPriorityQueue<HMURLUploadTask *> *pendingUploadTask;
@property(strong, nonatomic) NSMutableArray<HMURLUploadTask *> *runningUploadTask;
@property(strong, nonatomic) dispatch_queue_t processingQueue;
@property(strong, nonatomic) dispatch_queue_t completionQueue;
@property(strong, nonatomic) HMNetworkManager *networkManager;
@property(strong, nonatomic) HMTaskTimer *taskTimer;

@end

@implementation HMURLSessionManger

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount andConfiguration:(NSURLSessionConfiguration *)configuration {
    if (self = [super init]) {
        if (!configuration) {
            configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.hungmai.HMURLSessionManager.bgConfiguration"];
        }
        NSUInteger maxUploadTaskCount = MIN(maxCount, MaxConnection);
        configuration.HTTPMaximumConnectionsPerHost = maxUploadTaskCount;
        configuration.timeoutIntervalForRequest = 60;

        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 3;
        
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_operationQueue];

        _uploadTaskMapping = [NSMutableDictionary new];
        _pendingUploadTask = [HMPriorityQueue new];
        _runningUploadTask = [NSMutableArray new];
        _maxConcurrentUploadTask = maxUploadTaskCount;
        
        __weak __typeof__(self) weakSelf = self;
        
        _networkManager = [HMNetworkManager shareInstance];
        [_networkManager startMonitoring];
        
        //If network is unreachable, suspend all tasks to save them breaked. Resume them when network becomes to be reachable
        _networkManager.networkStatusChangeBlock = ^(HMNetworkStatus status) {
            __typeof__(self) strongSelf = weakSelf;
            if (strongSelf.networkManager.isReachable) {
                NSLog(@"[HM] HMURLSessionManager - Network available - Resume all running task (Has network)");
                [strongSelf resumeAllCurrentTasks];
            } else {
                NSLog(@"[HM] HMURLSessionManager - Network unavailable - Suspend all running task (No network)");
                [strongSelf suspendAllRunningTask];
            }
        };
        
        _processingQueue = dispatch_queue_create("com.hungmai.HMURLSessionManager.processingQueue", DISPATCH_QUEUE_CONCURRENT);
        _completionQueue = dispatch_queue_create("com.hungmai.HMURLSessionManager.completionQueue", DISPATCH_QUEUE_SERIAL);
        
        _taskTimer = [HMTaskTimer taskTimerWithTimeInterval:60 timeoutHandler:^{
            [weakSelf cancelAllRunningUploadTask];
        } inQueue:_completionQueue];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification * _Nonnull note)
        {
            [_taskTimer stopMonitor]; //Stop checking timeout when app becomes to background    
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification * _Nonnull note)
        {
            [self resumeAllCurrentTasks];
        }];
    }
    
    return self;
}

- (void)dealloc {
    NSLog(@"[HM] HMURLSessionManager - dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL priority:(HMURLUploadTaskPriority)priority error:(NSError **)error {
    if (!request || !fileURL) {
        if (error) {
            *error = [NSError errorWithDomain:HMURLSessionManagerDomain code:HMUploadTaskNilError userInfo:@{@"message": @"Host and file path mustn't be nil"}];
        }
        
        return nil;
    }
    
    if (!_networkManager.isReachable) {
        if (error) {
            *error = [NSError errorWithDomain:HMURLSessionManagerDomain code:HMUploadTaskNilError userInfo:@{@"message": @"Network unavailable"}];
        }
        return nil;
    }
    
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromFile:fileURL];
        if (!uploadTask) {
            return nil;
        }
        
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask];
        if (hmUploadTask) {
            hmUploadTask.priority = priority;
        }
        return hmUploadTask;
    }
}

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)data priority:(HMURLUploadTaskPriority)priority error:(NSError **)error {
    if (!request || !data) {
        if (error) {
            *error = [NSError errorWithDomain:HMURLSessionManagerDomain code:HMUploadTaskNilError userInfo:@{@"message": @"Host and file path mustn't be nil"}];
        }
        return nil;
    }
    
    if (!_networkManager.isReachable) {
        if (error) {
            *error = [NSError errorWithDomain:HMURLSessionManagerDomain code:HMUploadTaskNilError userInfo:@{@"message": @"Network unavailable"}];
        }
        return nil;
    }
    
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromData:data];
        if (!uploadTask) {
            return nil;
        }
        
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask];
        if (hmUploadTask) {
            hmUploadTask.priority = priority;
        }
        return hmUploadTask;
    }
}

- (HMURLUploadTask *)uploadTaskWithStreamRequest:(NSURLRequest *)request priority:(HMURLUploadTaskPriority)priority error:(NSError **)error {
    if (!request) {
        if (error) {
            *error = [NSError errorWithDomain:HMURLSessionManagerDomain code:HMUploadTaskNilError userInfo:@{@"message": @"Host and file path mustn't be nil"}];
        }
        return nil;
    }
    
    if (!_networkManager.isReachable) {
        if (error) {
            *error = [NSError errorWithDomain:HMURLSessionManagerDomain code:HMUploadTaskNilError userInfo:@{@"message": @"Network unavailable"}];
        }
        return nil;
    }
    
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithStreamedRequest:request];
        if (!uploadTask) {
            return nil;
        }
        
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask];
        if (hmUploadTask) {
            hmUploadTask.priority = priority;
        }
        return hmUploadTask;
    }
}

- (NSArray *)getRunningUploadTasks {
    @synchronized(self) {
        return [_runningUploadTask copy];
    }
}

- (HMPriorityQueue *)getPendingUploadTasks {
    @synchronized(self) {
        return _pendingUploadTask;
    }
}

- (void)resumeAllCurrentTasks {
    if (_runningUploadTask.count == 0) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        [weakSelf.taskTimer startMonitor];
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.runningUploadTask enumerateObjectsUsingBlock:^(HMURLUploadTask *  _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask.task resume];
        }];
    });
}

- (void)suspendAllRunningTask {
    if (_runningUploadTask.count == 0) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.runningUploadTask enumerateObjectsUsingBlock:^(HMURLUploadTask *  _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask.task suspend];
        }];
    });
}

- (void)cancelAllPendingUploadTask {
    if (_pendingUploadTask.count == 0) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        for (int i = 0; i < strongSelf.pendingUploadTask.count; i ++) {
            HMURLUploadTask *uploadTask = [strongSelf.pendingUploadTask popObject];
            if (uploadTask) {
                [uploadTask cancel];
            }
        }
    });
}

- (void)cancelAllRunningUploadTask {
    if (_runningUploadTask.count == 0) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.runningUploadTask enumerateObjectsUsingBlock:^(HMURLUploadTask *  _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask cancel];
        }];
        [strongSelf.runningUploadTask removeAllObjects];
    });
}

- (void)invalidateAndCancel {
    [self cancelAllPendingUploadTask];
    [_runningUploadTask removeAllObjects];
    [_session invalidateAndCancel];
}

#pragma mark - Private

- (HMURLUploadTask *)makeUploadTaskWithTask:(NSURLSessionDataTask *)task {
    if (!task) {
        return nil;
    }
    
    HMURLUploadTask *hmUploadTask = [[HMURLUploadTask alloc] initWithTask:task];
    if (hmUploadTask) {
        hmUploadTask.delegate = self;
        [_uploadTaskMapping setObject:hmUploadTask forKey:@(hmUploadTask.task.taskIdentifier)];
    }
    return hmUploadTask;
}

// Move pending task to running task and run it if amount of running tasks is less then the maximum value
- (void)shouldIncreaseCurrentUploadTask {
    if (_pendingUploadTask.count > 0 && (_maxConcurrentUploadTask == -1 || _runningUploadTask.count < _maxConcurrentUploadTask)) {
        HMURLUploadTask *uploadTask = [_pendingUploadTask popObject];
        if (uploadTask) {
            [_runningUploadTask addObject:uploadTask];
            [uploadTask.task resume];
            [self changeUploadState:HMURLUploadStateRunning ofUploadTask:uploadTask];
            [_taskTimer startMonitor]; //Start checking timeout 
            NSLog(@"[HM] Upload Task - Start: %ld", uploadTask.taskIdentifier);
        }
    }
}

- (void)addPendingUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.pendingUploadTask pushObject:uploadTask];
        [strongSelf changeUploadState:HMURLUploadStatePending ofUploadTask:uploadTask];
        [strongSelf shouldIncreaseCurrentUploadTask];
    });
}

- (void)cancelPendingUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.pendingUploadTask removeObject:uploadTask];
        [uploadTask removeAllCallbackEntries];
    });
}

- (BOOL)checkPendingUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return NO;
    }
    
    @synchronized(self) {
        if ([_pendingUploadTask containsObject:uploadTask]) {
            return YES;
        }
        return NO;
    }
}

- (BOOL)checkRunningUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return NO;
    }
    
    @synchronized(self) {
        if ([_runningUploadTask containsObject:uploadTask]) {
            return YES;
        }
        return NO;
    }
}

- (void)changeUploadState:(HMURLUploadState)newState ofUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    @synchronized(self) {
        uploadTask.currentState = newState;
        
        NSArray<HMURLUploadCallbackEntry *> *cbEntries = [uploadTask getAllCallbackEntries];
        if (!cbEntries) {
            return;
        }
        
        __weak __typeof__(uploadTask) weakUploadTask = uploadTask;
        
        //Call all change state calbacks of this task
        [cbEntries enumerateObjectsUsingBlock:^(HMURLUploadCallbackEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.changeStateCallback) {
                dispatch_async(obj.queue, ^{
                    obj.changeStateCallback(weakUploadTask.taskIdentifier, newState);
                });
            }
        }];
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    if (!task || bytesSent < 0 || totalBytesSent < 0 || totalBytesExpectedToSend < 0) {
        return;
    }
    
    [_taskTimer update];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(weakSelf.processingQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        HMURLUploadTask *uploadTask = strongSelf.uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask && [strongSelf.runningUploadTask containsObject:uploadTask]) {
            uploadTask.totalBytes = totalBytesExpectedToSend;
//            if (uploadTask.sentBytes >= totalBytesSent) {
//                return;
//            }
            uploadTask.sentBytes = totalBytesSent;
            
            NSArray<HMURLUploadCallbackEntry *> *cbEntries = [uploadTask getAllCallbackEntries];
            if (!cbEntries) {
                return;
            }
            
            __weak __typeof__(uploadTask) weakUploadTask = uploadTask;
            //Call all progress calbacks of this task
            [cbEntries enumerateObjectsUsingBlock:^(HMURLUploadCallbackEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.progressCallback) {
                    dispatch_async(obj.queue, ^{
                        obj.progressCallback(weakUploadTask.taskIdentifier, weakUploadTask.uploadProgress);
                    });
                }
            }];
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!task) {
        return;
    }
    
    NSLog(@"[HM] HMURLSessionManager - Complete task %tu - Error: %@", task.taskIdentifier, error);
    
    [_taskTimer update];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        HMURLUploadTask *uploadTask = strongSelf.uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask && [strongSelf.runningUploadTask containsObject:uploadTask]) {
            if (uploadTask.currentState != HMURLUploadStateCancel) {
                if (!error) {
                    uploadTask.totalBytes = task.countOfBytesExpectedToSend;
                    uploadTask.sentBytes = task.countOfBytesSent;
                    [uploadTask completed];
                    [strongSelf changeUploadState:HMURLUploadStateCompleted ofUploadTask:uploadTask];
                } else {
                    [strongSelf changeUploadState:HMURLUploadStateFailed ofUploadTask:uploadTask];
                }
            }
            
            NSArray<HMURLUploadCallbackEntry *> *cbEntries = [uploadTask getAllCallbackEntries];
            if (!cbEntries) {
                return;
            }
            
            __weak __typeof__(uploadTask) weakUploadTask = uploadTask;
            //Call all complete calbacks of this task
            [cbEntries enumerateObjectsUsingBlock:^(HMURLUploadCallbackEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.completionCallback) {
                    dispatch_async(obj.queue, ^{
                        obj.completionCallback(weakUploadTask.taskIdentifier, error);
                    });
                }
            }];
            
            [uploadTask removeAllCallbackEntries];
            strongSelf.uploadTaskMapping[@(uploadTask.task.taskIdentifier)] = nil;
            
            [strongSelf.runningUploadTask removeObject:uploadTask];
            [strongSelf shouldIncreaseCurrentUploadTask];
        }
    });
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"[HM] HMURLSessionManager - Finished background task");
    if (_delegate && [_delegate respondsToSelector:@selector(didFinishEventsForBackgroundHmURLSessionManager:)]) {
        [_delegate didFinishEventsForBackgroundHmURLSessionManager:self];
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"[HM] HMURLSessionManager - Invalid error: %@", error);
    [_networkManager stopMonitoring];
    [self cancelAllRunningUploadTask];
    [self cancelAllPendingUploadTask];
    if (_delegate && [_delegate respondsToSelector:@selector(hmURLSessionManager:didBecomeInvalidWithError:)]) {
        [_delegate hmURLSessionManager:self didBecomeInvalidWithError:error];
    }
}

#pragma mark - HMURLUploadDelegate

- (void)shouldToResumeHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    if ([self checkRunningUploadTask:uploadTask]) { //Only resume running tasks
        [uploadTask.task resume];
        [self changeUploadState:HMURLUploadStateRunning ofUploadTask:uploadTask];
    } else if (![self checkPendingUploadTask:uploadTask]){ //Add to pending list if the task is in 'not running' state
        [self addPendingUploadTask:uploadTask];
    }
}

- (void)shouldToPauseHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    if ([self checkRunningUploadTask:uploadTask]) { //Only pause running tasks
        [uploadTask.task suspend];
        [self changeUploadState:HMURLUploadStatePaused ofUploadTask:uploadTask];
    }
}

- (void)shouldToCancelHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    //Only check whether the task is in pending list because the 'cancel' function only effects for tasks running.
    //In 'didCompleteWithError' callback method, the task will be remove from running list so we don't need to remove it from that list here
    //But we need to remove the task from pending list if it is not running
    if ([self checkPendingUploadTask:uploadTask]) {
        [self cancelPendingUploadTask:uploadTask];
    }
    [uploadTask.task cancel];
    [self changeUploadState:HMURLUploadStateCancel ofUploadTask:uploadTask];
}

@end

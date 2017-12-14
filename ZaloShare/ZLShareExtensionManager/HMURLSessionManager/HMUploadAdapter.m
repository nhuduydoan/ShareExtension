//
//  HMUploadAdapter.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMUploadAdapter.h"

#define AllowedMaxConcurrentTask                   1000

@interface HMUploadAdapter() <HMURLSessionManagerDelegate>

@property(strong, nonatomic) NSMutableDictionary *uploadTaskMapping;
@property(strong, nonatomic) NSMutableDictionary *uploadTaskCreationPending;
@property(strong, nonatomic) NSURLSessionConfiguration *configuration;

@property(strong, nonatomic) HMURLSessionManger *sessionManager;
@property(strong, nonatomic) dispatch_queue_t serialQueue;

@property(nonatomic) NSUInteger maxCount;

@end

@implementation HMUploadAdapter

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount configuration:(NSURLSessionConfiguration *)configuration{
    if (self = [super init]) {
        _uploadTaskMapping = [NSMutableDictionary new];
        _uploadTaskCreationPending = [NSMutableDictionary new];
        
        _configuration = configuration;
        _maxCount = maxCount;
        _sessionManager = [[HMURLSessionManger alloc] initWithMaxConcurrentTaskCount:maxCount andConfiguration:configuration];
        _sessionManager.delegate = self;
        
        _serialQueue = dispatch_queue_create("com.hungmai.HMUploadAdater.serialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (instancetype)shareInstance {
    static HMUploadAdapter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initWithMaxConcurrentTaskCount:3 configuration:nil];
    });
    
    return instance;
}

- (instancetype)initWithBackgroundId:(NSString *)backgroundId shareId:(NSString *)shareId {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:backgroundId];
    configuration.sharedContainerIdentifier = shareId;
    self = [self initWithMaxConcurrentTaskCount:3 configuration:configuration];
    return self;
}

- (void)dealloc {
    NSLog(@"[HM] HMUploadAdapter - dealloc");
}

#pragma mark - Public

- (BOOL)setMaxConcurrentTaskCount:(NSUInteger)maxCount {
    @synchronized(self) {
        if (_uploadTaskMapping.count > 0) {
            NSLog(@"[HM] HMUploadAdapter - Can't set max concurrent task count because still having upload tasks running or pending");
            return NO;
        }
        
        _maxCount = MIN(AllowedMaxConcurrentTask, maxCount);
        [_sessionManager invalidateAndCancel]; //Invalidate the session. It will re-init at 'URLsession:didBecomeInvalidWithError:' callback
        return YES;
    }
}

- (NSUInteger)getMaxConcurrentTaskCount {
    return _maxCount;
}

- (NSArray<HMURLUploadTask *> *)getAlreadyTask {
    @synchronized(self) {
        NSArray *array = [_uploadTaskMapping allValues];
        if (!array) {
            return nil;
        }
        
        return array;
    }
}

- (void)uploadTaskWithHost:(NSString *)hostString
                  filePath:(NSString *)filePath
                    header:(NSDictionary *)header
         completionHandler:(HMURLUploadCreationHandler)handler
                   inQueue:(dispatch_queue_t)queue {
    
    [self uploadTaskWithHost:hostString
                    filePath:filePath
                      header:header
           completionHandler:handler
                    priority:HMURLUploadTaskPriorityMedium
                     inQueue:queue];
}

- (void)uploadTaskWithHost:(NSString * _Nonnull)hostString
                  filePath:(NSString * _Nonnull)filePath
                    header:(NSDictionary * _Nullable)header
         completionHandler:(HMURLUploadCreationHandler)handler
                  priority:(HMURLUploadTaskPriority)priority
                   inQueue:(dispatch_queue_t _Nullable)queue {
    
    if (!hostString || [hostString isEqualToString:@""] || !filePath || [filePath isEqualToString:@""]) {
        if (handler) {
            [self dispatchAsyncWithQueue:queue block:^{
                NSError *error = [NSError errorWithDomain:@"" code:HMUploadTaskNilError userInfo:@{@"message": @"Host and file path mustn't be nil"}];
                handler(nil, error);
            }];
        }
        return;
    }
    
    HMURLUploadTaskPriority correctPriority = priority;
    if (priority < HMURLUploadTaskPriorityHigh || priority > HMURLUploadTaskPriorityLow) {
        correctPriority = HMURLUploadTaskPriorityLow;
    }

    @synchronized(self) {
        //Get and check another task has same host & file path and return it if existed for the multiple-request purpose
        HMURLUploadTask *similarTask = [self getSimilarTaskWithHost:hostString filePath:filePath];
        if (similarTask) {
            if (similarTask.currentState == HMURLUploadStateNotRunning && similarTask.priority > priority) {
                similarTask.priority = priority;
            }
            
            if (handler) {
                [self dispatchAsyncWithQueue:queue block:^{
                    handler(similarTask, nil);
                }];
            }
            return;
        }
        
        NSUInteger taskId = [self hashRequestWithHostString:hostString filePath:filePath];
        NSString *pendingTasksString = [NSString stringWithFormat:@"%tu-list", taskId];
        NSString *priorityTaskString = [NSString stringWithFormat:@"%tu-priority", taskId];
        HMURLUploadCompletionEntity *completionEnt = [[HMURLUploadCompletionEntity alloc] initWithHandler:handler inQueue:queue];
        
        NSMutableArray *taskCreationEntities = _uploadTaskCreationPending[pendingTasksString];
        if (!taskCreationEntities) {
            taskCreationEntities = [NSMutableArray new];
            _uploadTaskCreationPending[pendingTasksString] = taskCreationEntities;
        }
        
        if (_uploadTaskCreationPending[priorityTaskString]) {
            HMURLUploadTaskPriority oldPriority = [_uploadTaskCreationPending[priorityTaskString] integerValue];
            if (oldPriority > correctPriority) {
                _uploadTaskCreationPending[priorityTaskString] = @(correctPriority);
            }
        } else {
            _uploadTaskCreationPending[priorityTaskString] = @(correctPriority);
        }
        
        [taskCreationEntities addObject:completionEnt];
        
        if (_uploadTaskCreationPending[@(taskId)]) {
            NSLog(@"Return task");
            return;
        }
        
        dispatch_async(_serialQueue, ^{
            _uploadTaskCreationPending[@(taskId)] = @(1);
            NSURLRequest *request = [self makeRequestWithHost:hostString filePath:filePath header:header];
            if (!request) {
                @synchronized(self) {
                    NSError *error = [NSError errorWithDomain:@"" code:HMUploadTaskNilError userInfo:@{@"message": @"NSURLRequest object is nil"}];
                    [self releaseAllCreationRequestWithTaskId:taskId uploadTask:nil error:error];
                }
                
                return;
            }
            
            NSError *error = nil;
            HMURLUploadTask *uploadTask = [_sessionManager uploadTaskWithStreamRequest:request priority:correctPriority error:&error];
            if (uploadTask) {
                long value = [_uploadTaskCreationPending[priorityTaskString] longValue];
                uploadTask.priority = value;
                uploadTask.host = hostString;
                uploadTask.filePath = filePath;
                
                //Add one more callback for the upload task to remove the task from 'uploadTaskMapping' when this task is completed or canceled
                __weak __typeof__(self) weakSelf = self;
                [uploadTask addCallbacksWithProgressCB:nil
                                          completionCB:^(NSUInteger taskIdentifier, NSError * _Nullable error) {
                                              __typeof__(self) strongSelf = weakSelf;
                                              strongSelf.uploadTaskMapping[@(taskIdentifier)] = nil;
                                              
                                          } changeStateCB:^(NSUInteger taskIdentifier, HMURLUploadState newState) {
                                              __typeof__(self) strongSelf = weakSelf;
                                              if (newState == HMURLUploadStateCancel) {
                                                  strongSelf.uploadTaskMapping[@(taskIdentifier)] = nil;
                                              }
                                          } inQueue:_serialQueue];
                
                uploadTask.taskIdentifier = taskId;
                [_uploadTaskMapping setObject:uploadTask forKey:@(taskId)];
            }
            
            @synchronized(self) {
                [self releaseAllCreationRequestWithTaskId:taskId uploadTask:uploadTask error:error];
            }
        });
    }
}

- (void)resumeAllTask {
    [_sessionManager resumeAllCurrentTasks];
}

- (void)pauseAllTask {
    [_sessionManager suspendAllRunningTask];
}

- (void)cancelAllTask {
    if (_uploadTaskMapping.count == 0) {
        return;
    }
    
    @synchronized(self) {
        [_sessionManager cancelAllRunningUploadTask];
        [_sessionManager cancelAllPendingUploadTask];
        
        [_uploadTaskMapping removeAllObjects];
        [_uploadTaskCreationPending removeAllObjects];
    }
}

#pragma mark - Private

- (NSDictionary *)getDefaultHeader {
    return @{@"content-type": @"multipart/form-data"};
}

- (NSURLRequest *)makeRequestWithHost:(NSString *)hostString filePath:(NSString *)filePath header:(NSDictionary *)header {
    if (!hostString || !filePath) {
        return nil;
    }
    
    NSDictionary *targetHeader = header ? header : [self getDefaultHeader];
    
    NSArray *parameters = @[ @{ @"name": @"file", @"fileName": filePath } ];
    NSString *boundary = @"----WebKitFormBoundary7MA4YWxkTrZu0gW";
    
    NSError *error;
    NSMutableString *body = [NSMutableString string];
    for (NSDictionary *param in parameters) {
        [body appendFormat:@"--%@\r\n", boundary];
        if (param[@"fileName"]) {
            [body appendFormat:@"Content-Disposition:form-data; name=\"%@\"; filename=\"%@\"\r\n", param[@"name"], param[@"fileName"]];
            [body appendFormat:@"Content-Type: %@\r\n\r\n", param[@"contentType"]];
            [body appendFormat:@"%@", [NSString stringWithContentsOfFile:param[@"fileName"] encoding:NSASCIIStringEncoding error:&error]];
            if (error) {
                NSLog(@"%@", error);
            }
        } else {
            [body appendFormat:@"Content-Disposition:form-data; name=\"%@\"\r\n\r\n", param[@"name"]];
            [body appendFormat:@"%@", param[@"value"]];
        }
    }
    [body appendFormat:@"\r\n--%@--\r\n", boundary];
    NSData *postData = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:hostString]];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:targetHeader];
    [request setHTTPBody:postData];
    return request;
}

- (NSUInteger)hashRequestWithHostString:(NSString *)hostString filePath:(NSString *)filePath {
    if (!hostString || !filePath) {
        return NSNotFound;
    }
    
    NSString *requestString = [NSString stringWithFormat:@"%@-%@", hostString, filePath];
    return [requestString hash];
}

//Get and check another task has same host & file path
- (HMURLUploadTask *)getSimilarTaskWithHost:(NSString *)hostString filePath:(NSString *)filePath {
    if (!hostString || !filePath) {
        return nil;
    }
    
    NSUInteger taskId = [self hashRequestWithHostString:hostString filePath:filePath];
    HMURLUploadTask *similarTask = [_uploadTaskMapping objectForKey:@(taskId)];
    return similarTask;
}

- (void)releaseAllCreationRequestWithTaskId:(NSUInteger)taskId uploadTask:(HMURLUploadTask *)uploadTask error:(NSError *)error {
    if (!_uploadTaskCreationPending[@(taskId)]) {
        return;
    }
    
    NSString *pendingTasksString = [NSString stringWithFormat:@"%tu-list", taskId];
    NSString *priorityTaskString = [NSString stringWithFormat:@"%tu-priority", taskId];
    NSMutableArray *taskCreationEntities = _uploadTaskCreationPending[pendingTasksString];
    if (!taskCreationEntities) {
        return;
    }
    
    [taskCreationEntities enumerateObjectsUsingBlock:^(HMURLUploadCompletionEntity *  _Nonnull entity, NSUInteger idx, BOOL * _Nonnull stop) {
        if (entity.handler) {
            [self dispatchAsyncWithQueue:entity.queue block:^{
                entity.handler(uploadTask, error);
            }];
        }
    }];
    
    [taskCreationEntities removeAllObjects];
    _uploadTaskCreationPending[@(taskId)] = nil;
    _uploadTaskCreationPending[pendingTasksString] = nil;
    _uploadTaskCreationPending[priorityTaskString] = nil;
}

- (dispatch_queue_t)getValidQueueWithQueue:(dispatch_queue_t)queue {
    return queue ? queue : dispatch_get_main_queue();
}

- (void)dispatchAsyncWithQueue:queue block:(void(^)(void))block {
    dispatch_queue_t validQueue = [self getValidQueueWithQueue:queue];
    dispatch_async(validQueue, block);
}

- (void)hmURLSessionManager:(HMURLSessionManger *)manager didBecomeInvalidWithError:(NSError *)error {
    __weak __typeof__(self) weakSelf = self;
    [self dispatchAsyncWithQueue:_serialQueue block:^{
        __typeof__(self) strongSelf = weakSelf;
        NSLog(@"[HM] HMUploadAdapter - Re-init session manager");
        
        //Re-init session manager when it is invalid
        strongSelf.sessionManager = [[HMURLSessionManger alloc] initWithMaxConcurrentTaskCount:strongSelf.maxCount andConfiguration:_configuration];
        strongSelf.sessionManager.delegate = strongSelf;
    }];
}

@end

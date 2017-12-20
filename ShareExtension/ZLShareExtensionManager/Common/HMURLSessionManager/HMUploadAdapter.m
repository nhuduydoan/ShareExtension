//
//  HMUploadAdapter.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMUploadAdapter.h"

#define AllowedMaxConcurrentTask                   1000
#define Boundary                                   @"HMBoundary"

@interface HMUploadAdapter() <HMURLSessionManagerDelegate>

@property(strong, nonatomic) NSMutableDictionary *uploadTaskMapping;
@property(strong, nonatomic) NSMutableDictionary *uploadTaskCreationPending;
@property(strong, nonatomic) NSURLSessionConfiguration *configuration;

@property(strong, nonatomic) NSMutableArray<void(^)(void)> *uploadCompletionHandlers;
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

- (void)addUploadCompletionHandler:(void(^)(void))completionHandler {
    if (!completionHandler) {
        return;
    }
    
    [_uploadCompletionHandlers addObject:completionHandler];
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
                                              [strongSelf checkUploadCompletion];
                                              
                                          } changeStateCB:^(NSUInteger taskIdentifier, HMURLUploadState newState) {
                                              __typeof__(self) strongSelf = weakSelf;
                                              if (newState == HMURLUploadStateCancel) {
                                                  strongSelf.uploadTaskMapping[@(taskIdentifier)] = nil;
                                                  [strongSelf checkUploadCompletion];
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

- (void)uploadTaskWithHost:(NSString *)hostString
                  fileName:(NSString *)fileName
                      data:(NSData *)data
                    header:(NSDictionary *)header
         completionHandler:(HMURLUploadCreationHandler)handler
                  priority:(HMURLUploadTaskPriority)priority
                   inQueue:(dispatch_queue_t)queue {
    
    if (!handler) {
        return;
    }
    
    dispatch_async(globalDefaultQueue, ^{
        HMURLUploadTaskPriority correctPriority = priority;
        if (priority < HMURLUploadTaskPriorityHigh || priority > HMURLUploadTaskPriorityLow) {
            correctPriority = HMURLUploadTaskPriorityLow;
        }
        
        NSError *error = nil;
        NSURLRequest *request = [self makeRequestWithHost:hostString fileName:fileName data:data header:header parameters:nil];
        
        HMURLUploadTask *uploadTask = [_sessionManager uploadTaskWithStreamRequest:request priority:correctPriority error:&error];
        if (uploadTask) {
            uploadTask.priority = correctPriority;
            uploadTask.host = hostString;
            uploadTask.filePath = fileName;
        }
        
        dispatch_async(GetValidQueue(queue), ^{
            handler(uploadTask, error);
        });
    });
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
    return @{@"content-type": [NSString stringWithFormat:@"multipart/form-data; boundary=%@", Boundary]};
}

- (NSURLRequest *)makeRequestWithHost:(NSString *)hostString filePath:(NSString *)filePath header:(NSDictionary *)header {
    if (!hostString || !filePath) {
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    return [self makeRequestWithHost:hostString fileName:filePath data:data header:header parameters:nil];
}
- (NSURLRequest *)makeRequestWithHost:(NSString *)hostString fileName:(NSString *)fileName data:(NSData *)data header:(NSDictionary *)header parameters:(NSDictionary *)parameters{
    if (!data) {
        return nil;
    }
    
    NSDictionary *targetHeader = header ? header : [self getDefaultHeader];
    
    NSMutableData *bodyData = [NSMutableData new];
    
    [bodyData appendData:[self makeBodyFilePartDataWithFileName:fileName data:data]];
    
    NSMutableString *partString = [NSMutableString new];
    
    
    if (parameters) {
        for (NSString *keys in [parameters allKeys]) {
            [partString appendFormat:@"--%@\r\n", Boundary];
            [partString appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameters[keys]];
        }
    }
    
    
    //Make end multipart
    [partString appendFormat:@"\r\n--%@--\r\n\r\n", Boundary];
    NSData *parameterPartData = [partString dataUsingEncoding:NSUTF8StringEncoding];
    [bodyData appendData:parameterPartData];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:hostString]];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:targetHeader];
    [request setHTTPBody:bodyData];
    return request;
}

- (NSData *)makeBodyFilePartDataWithFileName:(NSString *)fileName data:(NSData *)fileData {
    NSMutableData *filePartData = [NSMutableData new];
    
    //Make above string
    NSMutableString *aboveString = [NSMutableString new];
    [aboveString appendFormat:@"--%@\r\n", Boundary];
    [aboveString appendFormat:@"Content-Disposition: form-data; name=\"file\"; fileName=\"%@\"\r\n\r\n", fileName];
    NSData *aboveData = [aboveString dataUsingEncoding:NSUTF8StringEncoding];
    
    [filePartData appendData:aboveData];
    [filePartData appendData:fileData];
    
    return filePartData;
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

- (void)checkUploadCompletion {
    @synchronized(self) {
        if ([_uploadTaskMapping allValues].count == 0) {
            [_uploadCompletionHandlers enumerateObjectsUsingBlock:^(void (^ _Nonnull completionHandler)(void), NSUInteger idx, BOOL * _Nonnull stop) {
                completionHandler();
            }];
        }
    }
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

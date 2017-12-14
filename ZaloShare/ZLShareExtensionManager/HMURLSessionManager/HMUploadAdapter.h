//
//  HMUploadAdapter.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMURLSessionManger.h"
#import "HMURLUploadCompletionEntity.h"

@class HMUploadAdapter;

@interface HMUploadAdapter : NSObject


/**
 The class is followed the singleton design pattern

 @return The singleton object
 */
+ (instancetype)shareInstance;

- (instancetype)initWithBackgroundId:(NSString *)backgroundId shareId:(NSString *)shareId;


/**
 Set max concurrent tasks running at the moment. The others tasks will be push to priority queue and will run when a running task is completed.
 The method will return NO and don't change anything if adapter still has some tasks in queue (both running or pending queues).
 When the adapter don't have any tasks, the 'sessionManager' will be invalid and re-init with maxCount value.
 
 @param maxCount Number of conncurrent tasks will run in the same time
 @return YES if the adapter don't have any tasks
 */
- (BOOL)setMaxConcurrentTaskCount:(NSUInteger)maxCount;


/**
 Get the amount of allowed running tasks at the moment.

 @return Number of allowed running tasks
 */
- (NSUInteger)getMaxConcurrentTaskCount;


/**
 Get tasks is running or pending handled by the adapter

 @return Tasks is running or pending handled by the adapter
 */
- (NSArray<HMURLUploadTask *> *)getAlreadyTask;


/**
 Create an upload task with host, file path and optional header.
 The method will use 'uploadTaskWithHost:filePath:header:completionHandler:priority:inQueue' with priority is equal to 'HMURLUploadTaskPriorityMedium'
 The task will be return asynchronously in queue user want.
 

 @param hostString The uploaded host
 @param filePath The uploaded file path
 @param header Optional, adapter will use default header if this field is nil
 @param handler The completion block which will be return an upload task to handle
 @param queue The queue user want to return the upload task
 */
- (void)uploadTaskWithHost:(NSString *)hostString
                  filePath:(NSString *)filePath
                    header:(NSDictionary *)header
         completionHandler:(HMURLUploadCreationHandler)handler
                   inQueue:(dispatch_queue_t)queue;


/**
 Create an upload task with host, file path, optional header and the priority.
 If header field = nil, adapter will use default header 'Content-type: multipart'.
 The task will be return asynchronously in queue user want.

 @param hostString The uploaded host
 @param filePath The uploaded file path
 @param header Optional, adapter will use default header if this field is nil
 @param handler The completion block which will be return an upload task to handle
 @param priority The priority of the upload task user want to return
 @param queue The queue user want to return the upload task
 */
- (void)uploadTaskWithHost:(NSString *)hostString
                  filePath:(NSString *)filePath
                    header:(NSDictionary *)header
         completionHandler:(HMURLUploadCreationHandler)handler
                  priority:(HMURLUploadTaskPriority)priority
                   inQueue:(dispatch_queue_t)queue;


/**
 Resume all running tasks handled by the adapter
 */
- (void)resumeAllTask;

/**
 Pause all running tasks handled by the adapter
 */
- (void)pauseAllTask;


/**
 Cancel all running & pending tasks handled by the adapter
 */
- (void)cancelAllTask;

@end

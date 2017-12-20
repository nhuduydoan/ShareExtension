//
//  HMURLSessionManger.h
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMURLUploadTask.h"
#import "HMPriorityQueue.h"

#define HMURLSessionManagerDomain               @"com.hungmai.Test_Nimbus.HMURLSessionManager"

@class HMURLSessionManger;

typedef NS_ENUM(NSInteger, HMUploadErrorCode) {
    HMUploadTaskNilError,
    HMUploadNoNetworkError
};

/**
 The session manager state protocol
 */
@protocol HMURLSessionManagerDelegate <NSObject>
@optional


/**
 Handle 'didBecomeInvalidWithError' event of NSURLSession when it is invalid

 @param manager The SessionManager called the method
 @param error The error causes the session became invalid
 */
- (void)hmURLSessionManager:(HMURLSessionManger * _Nonnull)manager didBecomeInvalidWithError:(NSError * _Nullable)error;


/**
 Handle 'didFinishEventsForBackgroundHmURLSessionManager' event of NSURLSession when all tasks of it is done in background

 @param manager The SessionManager called the method
 */
- (void)didFinishEventsForBackgroundHmURLSessionManager:(HMURLSessionManger * _Nonnull)manager;

@end


/**
 The class handle all upload tasks. It use an NSURLSession to generate upload tasks and handle running queue, pending queue for supporting multiple upload tasks at the moment.
 It also contains an HMNetworkManager which will be use for checking network to handle many network problems
 It uses an serial queue to work asynchronously
 */
@interface HMURLSessionManger : NSObject


/**
 The delegate which will handle session events
 */
@property(weak, nonatomic) id<HMURLSessionManagerDelegate> _Nullable delegate;


/**
 Initialize an instance which is define how many tasks can be at the running queue and the configuration for 'session' object which is instance of 'NSURLSession'

 @param maxCount The number of tasks can be at the running queue
 @param configuration The configuration for 'NSURLSession' instance
 @return An instance for the class
 */
- (instancetype _Nullable)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount andConfiguration:(NSURLSessionConfiguration * _Nullable)configuration;


/**
 Create an 'HMURLUploadTask' object which wraper an 'NSURLSessionUploadTask' instance with 'NSURLRequest' request and a file path.
 Each 'HMURLUploadTask' object will be definded an specific priority which will use to arrange in the priority pending queue
 
 @param request The request of upload task which will be used to send to upload host
 @param fileURL The file path for the file user want to upload
 @param priority The priority
 @return An instance which can resume, pause, cancel the request
 */
- (HMURLUploadTask * _Nullable)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                                           fromFile:(NSURL * _Nonnull)fileURL
                                           priority:(HMURLUploadTaskPriority)priority error:(NSError * _Nullable * _Nullable)error;


/**
 Create an 'HMURLUploadTask' object which wraper an 'NSURLSessionUploadTask' instance with 'NSURLRequest' request and 'NSData' data.
 Each 'HMURLUploadTask' object will be definded an specific priority which will use to arrange in the priority pending queue

 @param request The request of upload task which will be used to send to upload host
 @param data The data for upload task which will be merge to request
 @param priority The priority
 @return An instance which can resume, pause, cancel the request
 */
- (HMURLUploadTask * _Nullable)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                                           fromData:(NSData * _Nonnull)data
                                           priority:(HMURLUploadTaskPriority)priority error:(NSError * _Nullable * _Nullable)error;


/**
 Create an 'HMURLUploadTask' object which wraper an 'NSURLSessionUploadTask' instance with 'NSURLRequest' stream request.
 Each 'HMURLUploadTask' object will be definded an specific priority which will use to arrange in the priority pending queue
 
 @param request The request of upload task which will be used to send to upload host
 @param priority The priority
 @return An instance which can resume, pause, cancel the request
 */
- (HMURLUploadTask * _Nullable)uploadTaskWithStreamRequest:(NSURLRequest * _Nonnull)request
                                                 priority:(HMURLUploadTaskPriority)priority error:(NSError * _Nullable * _Nullable)error;


/**
 Get the tasks in running queue

 @return The array of tasks
 */
- (NSArray * _Nullable)getRunningUploadTasks;


/**
 Get the tasks in pending queue

 @return The array of tasks
 */
- (HMPriorityQueue * _Nullable)getPendingUploadTasks;


/**
 Resume tasks in running queue
 */
- (void)resumeAllCurrentTasks;


/**
 Cancel all tasks in pending queue
 */
- (void)cancelAllPendingUploadTask;


/**
 Cancel all tasks in running queue
 */
- (void)cancelAllRunningUploadTask;


/**
 Pause tasks in running queue
 */
- (void)suspendAllRunningTask;


/**
 Invalidate the 'session' and remove all tasks.
 The all running tasks will be cancel and 'didCompleteWithError' will be call for each running task
 'URLsession:didBecomeInvalidWithError' will be call after
 */
- (void)invalidateAndCancel;

@end

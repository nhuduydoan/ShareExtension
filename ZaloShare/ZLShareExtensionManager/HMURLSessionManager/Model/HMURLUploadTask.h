//
//  HMURLUploadTask.h
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMURLUploadCallbackEntry.h"

typedef NS_ENUM(NSInteger, HMURLUploadTaskPriority) {
    HMURLUploadTaskPriorityHigh = 0,
    HMURLUploadTaskPriorityMedium,
    HMURLUploadTaskPriorityLow
};

@class HMURLUploadTask;


/**
 The protocol for handling the actions of the task
 */
@protocol HMURLUploadDelegate <NSObject>

- (void)shouldToResumeHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)shouldToPauseHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)shouldToCancelHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;

@end


/**
 The class which will be return for users, users can use it to resume/pause/cancel the upload task.
 The class includes enough information of the upload task
 */
@interface HMURLUploadTask : NSObject

@property(nonatomic) NSUInteger taskIdentifier;
@property(nonatomic) float totalBytes;
@property(nonatomic) float sentBytes;
@property(nonatomic, readonly) float uploadProgress;

@property(weak, nonatomic) NSURLSessionDataTask * _Nullable task;
@property(weak, nonatomic) id<HMURLUploadDelegate> _Nullable delegate;

@property(nonatomic) HMURLUploadState currentState;
@property(nonatomic) HMURLUploadTaskPriority priority;

@property(strong, nonatomic) NSString * _Nonnull host;
@property(strong, nonatomic) NSString * _Nonnull filePath;


/**
 Initialize an object with a 'NSURLSessionDataTask' which is the real task uploading data to the host

 @param task A task uploading data to the host
 @return An instance of the class
 */
- (instancetype _Nullable)initWithTask:(NSURLSessionDataTask * _Nonnull)task;


/**
 The actions users can call to handle the upload task
 */
- (void)resume;
- (void)cancel;
- (void)pause;
- (void)completed;


/**
 The class support multiple callback purpose, so it need to contain an array for the callback entries to hold all callbacks. The method will return this array

 @return The array for the calback entries
 */
- (NSArray<HMURLUploadCallbackEntry *> * _Nonnull)getAllCallbackEntries;


/**
 Because of multiple callback purpose, the class supports an method allowing users can add more callbacks and group them to one entry to handle easily.
 With an entry, users is allow to put an equeue they want to call this callbacks
 See 'HMURLUploadCallbackEntry' to know which types of callback in one entry

 @param progressBlock The callback which will be call multiple times once server received upload data
 @param completionBlock The callback which will be call when the task is complete
 @param changeStateBlock The callback which will
 @param queue The queue which will be used to call asynchronously
 @return The callback entry identifier which is useful if you want to remove this callback entry
 */
- (NSString * _Nullable)addCallbacksWithProgressCB:(HMURLUploadProgressBlock _Nullable)progressBlock
                                      completionCB:(HMURLUploadCompletionBlock _Nullable)completionBlock
                                     changeStateCB:(HMURLUploadChangeStateBlock _Nullable)changeStateBlock
                                           inQueue:(dispatch_queue_t _Nullable)queue;


/**
 Remove an callback entry with entryId

 @param cbEntryId The entryId wanted to remove
 */
- (void)removeCallbacksWithId:(NSString * _Nonnull)cbEntryId;


/**
 Remove all callback entries
 */
- (void)removeAllCallbackEntries;


- (NSComparisonResult)compare:(HMURLUploadTask * _Nonnull)otherTask;

@end

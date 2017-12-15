//
//  HMURLUploadCallbackEntry.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/8/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HMURLUploadState) {
    HMURLUploadStateNotRunning = 0,
    HMURLUploadStateRunning,
    HMURLUploadStatePending,
    HMURLUploadStatePaused,
    HMURLUploadStateCancel,
    HMURLUploadStateCompleted,
    HMURLUploadStateFailed
};

typedef void(^HMURLUploadProgressBlock) (NSUInteger taskIdentifier, float progress);
typedef void(^HMURLUploadCompletionBlock) (NSUInteger taskIdentifier, NSError * _Nullable error);
typedef void(^HMURLUploadChangeStateBlock) (NSUInteger taskIdentifier, HMURLUploadState newState);

@interface HMURLUploadCallbackEntry : NSObject

@property(strong, nonatomic) NSString * _Nonnull unitId;
@property(strong, nonatomic) dispatch_queue_t _Nonnull queue;
@property(strong, nonatomic) id _Nullable callback;
@property(strong, readonly, nonatomic) HMURLUploadProgressBlock _Nullable progressCallback;
@property(strong, readonly, nonatomic) HMURLUploadCompletionBlock _Nullable completionCallback;
@property(strong, readonly, nonatomic) HMURLUploadChangeStateBlock _Nullable changeStateCallback;

- (instancetype _Nonnull)initWithCallback:(id _Nullable)callback andQueue:(dispatch_queue_t _Nullable)queue;

- (instancetype _Nonnull)initWithProgressCallback:(HMURLUploadProgressBlock _Nullable)progressBlock
                               completionCallback:(HMURLUploadCompletionBlock _Nullable)completionBlock
                              changeStateCallback:(HMURLUploadChangeStateBlock _Nullable)changeStateBlock
                                         andQueue:(dispatch_queue_t _Nullable)queue;

@end

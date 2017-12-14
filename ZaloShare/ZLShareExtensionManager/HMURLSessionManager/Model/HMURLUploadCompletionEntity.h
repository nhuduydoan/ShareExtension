//
//  HMURLUploadCompletionEntity.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/11/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMURLUploadTask.h"

typedef void(^HMURLUploadCreationHandler)(HMURLUploadTask * uploadTask, NSError * error);

@interface HMURLUploadCompletionEntity : NSObject

@property(strong, nonatomic) HMURLUploadCreationHandler handler;
@property(strong, nonatomic) dispatch_queue_t queue;

- (instancetype)initWithHandler:(HMURLUploadCreationHandler)handler inQueue:(dispatch_queue_t)queue;

@end

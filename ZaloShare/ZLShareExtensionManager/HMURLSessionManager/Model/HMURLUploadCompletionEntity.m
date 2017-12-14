//
//  HMURLUploadCompletionEntity.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/11/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMURLUploadCompletionEntity.h"

@implementation HMURLUploadCompletionEntity

- (instancetype)initWithHandler:(HMURLUploadCreationHandler)handler inQueue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        _handler = handler;
        _queue = queue;
    }
    
    return self;
}

@end

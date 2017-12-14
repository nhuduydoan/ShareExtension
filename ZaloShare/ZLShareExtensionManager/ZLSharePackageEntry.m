//
//  ZLSharePackageEntries.m
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/14/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ZLSharePackageEntry.h"

@implementation ZLSharePackageEntry

- (instancetype)initWithPackageHandler:(ZLSharePackageHandler)packageHandler
                     completionHandler:(ZLSharePackageCompletionHandler)completionHandler
                               inQueue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        _packageHandler = packageHandler;
        _completionHandler = completionHandler;
        queue = queue;
    }
    
    return self;
}

@end

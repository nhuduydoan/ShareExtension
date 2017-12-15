//
//  ZLSharePackageEntries.m
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/14/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ZLSharePackageEntry.h"

@implementation ZLSharePackageEntry

- (instancetype)init {
    if (self = [super init]) {
        _completionHandler = nil;
        _queue = nil;
    }
    
    return self;
}

@end


@implementation ZLUploadPackageEntry

- (instancetype)init {
    if (self = [super init]) {
        _completionHandler = nil;
        _queue = nil;
    }
    
    return self;
}

@end

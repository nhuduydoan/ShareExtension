//
//  ZLSharePackage.m
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ZLSharePackage.h"

@implementation ZLSharePackage

- (instancetype)init {
    if (self = [super init]) {
        _packageId = [[NSUUID UUID] UUIDString];
        _shareType = ZLShareTypeUnknown;
        _shareData = nil;
    }
    
    return self;
}

- (instancetype)initWithShareObject:(NSData *)shareData shareType:(ZLShareType)shareType {
    if (self = [super init]) {
        _shareData = shareData;
        _shareType = shareType;
    }
    
    return self;
}

@end

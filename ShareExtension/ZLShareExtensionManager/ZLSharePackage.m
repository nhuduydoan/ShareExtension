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
        _packageId = [[[NSUUID UUID] UUIDString] hash];
        _shareType = ZLShareTypeUnknown;
        _shareData = nil;
        _shareName = @"";
    }
    
    return self;
}

@end

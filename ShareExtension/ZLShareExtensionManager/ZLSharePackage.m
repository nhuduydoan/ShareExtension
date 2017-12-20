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
        _shareContent = nil;
        _shareThumbnail = nil;
        _shareInfo = [NSMutableDictionary new];
    }
    
    return self;
}

- (NSString *)description {
    NSMutableString *descriptString = [NSMutableString new];
    [descriptString appendFormat:@"packageId:%tu\t", _packageId];
    [descriptString appendFormat:@"shareType:%@\t", _shareType];
    [descriptString appendFormat:@"shareContent:%@\t", _shareContent];
    [descriptString appendFormat:@"shareThumbnail:%@\t", _shareThumbnail];
    [descriptString appendFormat:@"shareInfo:%@\t", _shareInfo];
    return descriptString;
}

@end



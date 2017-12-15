//
//  ZLSharePackage.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZLShareDefine.h"

@interface ZLSharePackage : NSObject

@property(nonatomic) NSUInteger packageId;
@property(strong, nonatomic) NSString *shareName;
@property(strong, nonatomic) NSData *shareData;
@property(nonatomic) ZLShareType shareType;


@end

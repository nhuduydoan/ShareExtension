//
//  ZLSharePackage.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZLShareDefine.h"

@interface ZLSharePackage : NSObject
@property(nonatomic) NSUInteger packageId;
@property(nonatomic) ZLShareType shareType;
@property(strong, nonatomic) NSString *shareContent;
@property(strong, nonatomic) UIImage *shareThumbnail;
@property(strong, nonatomic) NSMutableDictionary *shareInfo;
@end

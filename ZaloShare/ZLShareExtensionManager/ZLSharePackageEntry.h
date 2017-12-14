//
//  ZLSharePackageEntries.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/14/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZLSharePackage.h"

typedef void(^ZLSharePackageHandler) (ZLSharePackage *package, NSError *error);
typedef void(^ZLSharePackageCompletionHandler) (NSError *error);

@interface ZLSharePackageEntry : NSObject

@property(strong, nonatomic) ZLSharePackageHandler packageHandler;
@property(strong, nonatomic) ZLSharePackageCompletionHandler completionHandler;
@property(strong, nonatomic) dispatch_queue_t queue;

- (instancetype)initWithPackageHandler:(ZLSharePackageHandler)packageHandler
                     completionHandler:(ZLSharePackageCompletionHandler)completionHandler
                               inQueue:(dispatch_queue_t)queue;

@end

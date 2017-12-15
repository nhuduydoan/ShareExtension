//
//  ZLSharePackageEntries.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/14/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZLSharePackage.h"

typedef void(^ZLSharePackageCompletionHandler) (NSArray<ZLSharePackage *> *packages, NSError *error);
typedef void(^ZLUploadCompletionHandler) (NSDictionary *uploadInfo);
typedef void(^ZLUploadProgressHandler) (float progress);

@interface ZLSharePackageEntry: NSObject

@property(strong, nonatomic) ZLSharePackageCompletionHandler completionHandler;
@property(strong, nonatomic) dispatch_queue_t queue;

@end


@interface ZLUploadPackageEntry: NSObject

@property(strong, nonatomic) ZLUploadCompletionHandler completionHandler;
@property(strong, nonatomic) ZLUploadProgressHandler progressHandler;
@property(strong, nonatomic) dispatch_queue_t queue;

@end


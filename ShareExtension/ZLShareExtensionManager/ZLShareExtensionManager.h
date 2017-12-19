//
//  ZLShareExtensionManager.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZLSharePackage.h"
#import "ZLCompressUtils.h"
#import "ZLShareDefine.h"
#import "ZLSharePackageEntry.h"

#define sShareExtensionManager          [ZLShareExtensionManager shareInstance]

@interface ZLSharePackageConfiguration: NSObject
@property(nonatomic) ZLVideoPackageCompressType videoCompress;
@property(nonatomic) ZLImagePackageCompressType imageCompress;
@end

@interface ZLShareExtensionManager : NSObject
@property(strong, nonatomic) NSExtensionContext *extensionContext;

+ (instancetype)shareInstance;

- (instancetype)initWithExtentionContext:(NSExtensionContext *)context shareId:(NSString *)shareId;

- (void)getShareDataWithCompletionHandler:(ZLSharePackageCompletionHandler)completionHandler
                                  inQueue:(dispatch_queue_t)queue;

- (void)uploadAllSharePackagesToURLString:(NSString *)urlString
                           configuration:(ZLSharePackageConfiguration *)configuration
                         progressHandler:(ZLUploadProgressHandler)progressHandler
                       completionHandler:(ZLUploadCompletionHandler)completionHandler
                                 inQueue:(dispatch_queue_t)queue;

- (void)uploadSharePackages:(NSArray<ZLSharePackage *> *)sharePackages
                toURLString:(NSString *)urlString
              configuration:(ZLSharePackageConfiguration *)configuration
            progressHandler:(ZLUploadProgressHandler)progressHandler
          completionHandler:(ZLUploadCompletionHandler)completionHandler
                    inQueue:(dispatch_queue_t)queue;

- (void)uploadSharePackage:(ZLSharePackage *)sharePackage
               toURLString:(NSString *)urlString
             configuration:(ZLSharePackageConfiguration *)configuration
           progressHandler:(ZLUploadPackageProgressHandler)progressHandler
         completionHandler:(ZLUploadCompletionHandler)completionHandler
                   inQueue:(dispatch_queue_t)queue;

- (void)completeExtension;
- (void)cancelExtensionWithError:(NSError *)error;

@end

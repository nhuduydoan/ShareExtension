//
//  ZLShareExtensionManager.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZLSharePackage.h"
#import "ZLCompressManager.h"
#import "ZLShareDefine.h"
#import "ZLSharePackageEntry.h"
#import "ZLCompressConfiguration.h"

#define sShareExtensionManager              [ZLShareExtensionManager shareInstance]

@interface ZLShareExtensionManager : NSObject
@property(strong, nonatomic) NSExtensionContext *extensionContext;


/**
 <#Description#>

 @return <#return value description#>
 */
+ (instancetype)shareInstance;


/**
 <#Description#>

 @param context <#context description#>
 @param shareId <#shareId description#>
 @return <#return value description#>
 */
- (instancetype)initWithExtentionContext:(NSExtensionContext *)context shareId:(NSString *)shareId;


/**
 <#Description#>

 @param completionHandler <#completionHandler description#>
 @param queue <#queue description#>
 */
- (void)getShareDataWithCompletionHandler:(ZLSharePackageCompletionHandler)completionHandler
                                  inQueue:(dispatch_queue_t)queue;


/**
 <#Description#>

 @param urlString <#urlString description#>
 @param configuration <#configuration description#>
 @param progressHandler <#progressHandler description#>
 @param completionHandler <#completionHandler description#>
 @param queue <#queue description#>
 */
- (void)uploadAllSharePackagesToURLString:(NSString *)urlString
                           configuration:(ZLCompressConfiguration *)configuration
                         progressHandler:(ZLUploadProgressHandler)progressHandler
                       completionHandler:(ZLUploadCompletionHandler)completionHandler
                                 inQueue:(dispatch_queue_t)queue;


/**
 <#Description#>

 @param sharePackages <#sharePackages description#>
 @param urlString <#urlString description#>
 @param configuration <#configuration description#>
 @param progressHandler <#progressHandler description#>
 @param completionHandler <#completionHandler description#>
 @param queue <#queue description#>
 */
- (void)uploadSharePackages:(NSArray<ZLSharePackage *> *)sharePackages
                toURLString:(NSString *)urlString
              configuration:(ZLCompressConfiguration *)configuration
            progressHandler:(ZLUploadProgressHandler)progressHandler
          completionHandler:(ZLUploadCompletionHandler)completionHandler
                    inQueue:(dispatch_queue_t)queue;


/**
 <#Description#>

 @param sharePackage <#sharePackage description#>
 @param urlString <#urlString description#>
 @param configuration <#configuration description#>
 @param progressHandler <#progressHandler description#>
 @param completionHandler <#completionHandler description#>
 @param queue <#queue description#>
 */
- (void)uploadSharePackage:(ZLSharePackage *)sharePackage
               toURLString:(NSString *)urlString
             configuration:(ZLCompressConfiguration *)configuration
           progressHandler:(ZLUploadPackageProgressHandler)progressHandler
         completionHandler:(ZLUploadCompletionHandler)completionHandler
                   inQueue:(dispatch_queue_t)queue;


/**
 <#Description#>
 */
- (void)completeExtension;


/**
 <#Description#>

 @param error <#error description#>
 */
- (void)cancelExtensionWithError:(NSError *)error;

@end

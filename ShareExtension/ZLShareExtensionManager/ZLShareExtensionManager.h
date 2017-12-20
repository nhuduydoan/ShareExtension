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
 Singleton instance for the class

 @return The singleton instance
 */
+ (instancetype)shareInstance;


/**
 Instead of using singleton 'shareIntance', the class allow initing a new instance with custom shareId of App Group (The capability for share storage between app extension and container extension).
 The shareId will use for background upload or download. You mush push the 'App Group Id' for shareId, if you push another stirng, the background task will not work.

 @param context The share context
 @param shareId The App Group Id
 @return The instance of the class
 */
- (instancetype)initWithExtentionContext:(NSExtensionContext *)context shareId:(NSString *)shareId;


/**
 Get all share items asynchronously with a queue user want to get the result
 This items will pack to be 'ZLSharePackage' objects, which include all need infomation for the items

 @param completionHandler The callback when finished packing all items to 'ZLSharePackage' objects
 @param queue The queue user want to get the result
 */
- (void)getShareDataWithCompletionHandler:(ZLSharePackageCompletionHandler)completionHandler
                                  inQueue:(dispatch_queue_t)queue;


/**
 Upload all items to destination host asynchronously with a queue user want to get the result.
 @Flow
 First, all share items will be pack with the function 'getShareDataWithCompletionHandler:inQueue:'.
 Second, Browse sequently all packages received from step 1, with once package can upload (image, video, file), the class will use function 'uploadSharePackage:toURLString:configuration:progressHandler:completionHandler:inQueue:' to upload the file the package packing to destination host

 @param urlString The destination host
 @param configuration The compress configuration for the file (image, video) want to upload
 @param progressHandler The callback handling the progress of all upload task
 @param completionHandler The callback handling the result of the function. A dictionary will be return in the callback, it includes the result of the upload task (number of completed upload task, number of failed upload task, error...)
 @param queue The queue user want to return the result
 */
- (void)uploadAllShareItemsToURLString:(NSString *)urlString
                         configuration:(ZLCompressConfiguration *)configuration
                       progressHandler:(ZLUploadProgressHandler)progressHandler
                     completionHandler:(ZLUploadCompletionHandler)completionHandler
                               inQueue:(dispatch_queue_t)queue;


/**
 Similar with 'uploadAllShareItemsToURLString:configuration:progressHandler:completionHandler:inQueue:', this function will upload input packages to destination host without packing items.
 It is useful when you packed all items and holed all package in somewhere, after that you want to upload the packages later

 @param sharePackages The packages want to upload
 @param urlString The destination upload host
 @param configuration The compress configuration for the file (image, video) want to upload
 @param progressHandler The callback handling the progress of all upload task
 @param completionHandler The callback handling the result of the function. A dictionary will be return in the callback, it includes the result of the upload task (number of completed upload task, number of failed upload task, error...)
 @param queue The queue user want to return the result
 */
- (void)uploadSharePackages:(NSArray<ZLSharePackage *> *)sharePackages
                toURLString:(NSString *)urlString
              configuration:(ZLCompressConfiguration *)configuration
            progressHandler:(ZLUploadProgressHandler)progressHandler
          completionHandler:(ZLUploadCompletionHandler)completionHandler
                    inQueue:(dispatch_queue_t)queue;


/**
 Upload a package to destination host.
 The 'HMUploadManager' shareInstance will be use to make upload tasks and handle the tasks

 @param sharePackage The package you want to upload
 @param urlString The destination upload host
 @param configuration The compress configuration for the file (image, video) want to upload
 @param progressHandler The callback handling the progress of the upload task
 @param completionHandler The callback handling the result of the function. A dictionary will be return in the callback, it includes the result of the upload task (number of completed upload task, number of failed upload task, error...)
 @param queue The queue user want to return the result
 */
- (void)uploadSharePackage:(ZLSharePackage *)sharePackage
               toURLString:(NSString *)urlString
             configuration:(ZLCompressConfiguration *)configuration
           progressHandler:(ZLUploadPackageProgressHandler)progressHandler
         completionHandler:(ZLUploadCompletionHandler)completionHandler
                   inQueue:(dispatch_queue_t)queue;


/**
 Complete the extension app.
 After call this function, the extension will be terminated and can't handle anything else, but the background upload or download can still run
 */
- (void)completeExtension;


/**
 Cancel the extension app. You want to push the error to explain the reason of the canclellation
 After call this function, the extension will be terminated and can't handle anything else, but the background upload or download can still run
 @param error <#error description#>
 */
- (void)cancelExtensionWithError:(NSError *)error;

@end

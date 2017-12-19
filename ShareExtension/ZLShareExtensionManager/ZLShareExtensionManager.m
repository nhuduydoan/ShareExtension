//
//  ZLShareExtensionManager.m
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ZLShareExtensionManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "HMUploadAdapter.h"

#define ShareDomain                                 @"com.hungmai.ShareExtension.ZLShareExtensionManager"
#define ShareContainerBackgroundConfiguration       @"group.com.hungmai.zlshare"

@implementation ZLSharePackageConfiguration
- (instancetype)init {
    if (self = [super init]) {
        _videoCompress = ZLVideoPackageCompressTypeLow;
        _imageCompress = ZLImagePackageCompressType640x480;
    }
    
    return self;
}
@end


@interface ZLShareExtensionManager()
@property(strong, nonatomic) ZLSharePackageConfiguration *pkConfiguration;
@property(strong, nonatomic) HMUploadAdapter *uploadAdapter;
@property(strong, nonatomic) dispatch_queue_t serialQueue;

@property(strong, nonatomic) NSMutableArray<ZLSharePackageEntry *> *dataEntries;
@property(strong, nonatomic) NSMutableArray<ZLUploadAllPackageEntry *> *uploadAllPackageEntries;
@property(strong, nonatomic) NSMutableDictionary *uploadSharePackageMapping;

@property(nonatomic) BOOL isGettingData;
@property(nonatomic) BOOL isUploadingData;
@end

@implementation ZLShareExtensionManager

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initPrivateWithShareId:(NSString *)shareId {
    if (self = [super init]) {
        NSString *backgroundId = [NSString stringWithFormat:@"%@-%@", ShareDomain, [[NSUUID UUID] UUIDString]];
        _uploadAdapter = [[HMUploadAdapter alloc] initWithBackgroundId:backgroundId shareId:shareId];
        _dataEntries = [NSMutableArray new];
        _uploadAllPackageEntries = [NSMutableArray new];
        _uploadSharePackageMapping = [NSMutableDictionary new];
        _pkConfiguration = [[ZLSharePackageConfiguration alloc] init];
        _serialQueue = dispatch_queue_create("com.hungmai.ZLShareExtensionManager.SerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (instancetype)initWithExtentionContext:(NSExtensionContext *)context shareId:(NSString *)shareId {
    if (self = [self initPrivateWithShareId:shareId]) {
        _extensionContext = context;
    }
    
    return self;
}

+ (instancetype)shareInstance {
    static ZLShareExtensionManager *shareInstance;
    static dispatch_once_t once_token;
    _dispatch_once(&once_token, ^{
        shareInstance = [[self alloc] initPrivateWithShareId:ShareContainerBackgroundConfiguration];
    });
    
    return shareInstance;
}

- (void)getShareDataWithCompletionHandler:(ZLSharePackageCompletionHandler)completionHandler
                                  inQueue:(dispatch_queue_t)queue {
    @synchronized(self) {
        if (!_extensionContext) {
            if (completionHandler) {
                NSError *error = [NSError errorWithDomain:ShareDomain code:ZLShareNilExtensionContextError userInfo:@{@"message": @"The extionsion context must is not equal to nil"}];
                dispatch_async(GetValidQueue(queue), ^{
                    completionHandler(nil, error);
                });
            }
        }
        
        ZLSharePackageEntry *packageEntry = [[ZLSharePackageEntry alloc] init];
        packageEntry.completionHandler = completionHandler;
        packageEntry.queue = queue;
        [_dataEntries addObject:packageEntry];
        if (_isGettingData) {
            return;
        }
        
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(_serialQueue, ^{
            weakSelf.isGettingData = YES;
            NSMutableArray *packages = [NSMutableArray new];
            NSExtensionItem *item = weakSelf.extensionContext.inputItems.firstObject;
            if (!item) {
                NSError *error = [NSError errorWithDomain:ShareDomain code:ZLShareNilExtensionItemError userInfo:@{@"message": @"The extension item is nil"}];
                [self releaseAllPackageEntriesWithPackages:nil error:error];
                weakSelf.isGettingData = NO;
            }
            
            dispatch_group_t group = dispatch_group_create();
            for (NSItemProvider *provider in item.attachments) {
                dispatch_group_enter(group);
                if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        if (error) {
                            dispatch_group_leave(group);
                            return;
                        }
                        
                        if ([(NSObject *)item isKindOfClass:[NSURL class]]) {
                            NSURL *imageURL = (NSURL *)item;
                            if (![[NSFileManager defaultManager] fileExistsAtPath:[imageURL path]]) {
                                dispatch_group_leave(group);
                                return;
                            }
                            
                            ZLSharePackage *package = [[ZLSharePackage alloc] init];
                            package.shareContent = [imageURL path];
                            package.shareType = ZLShareTypeImage;
                            [packages addObject:package];
                        }
                        
                        dispatch_group_leave(group);
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        if (error) {
                            dispatch_group_leave(group);
                            return;
                        }
                        
                        if ([(NSObject *)item isKindOfClass:[NSURL class]]) {
                            NSURL *videoURL = (NSURL *)item;
                            if (![[NSFileManager defaultManager] fileExistsAtPath:[videoURL path]]) {
                                dispatch_group_leave(group);
                                return;
                            }
                            
                            ZLSharePackage *package = [[ZLSharePackage alloc] init];
                            package.shareContent = [videoURL path];
                            package.shareType = ZLShareTypeVideo;
                            [packages addObject:package];
                        }
                        
                        dispatch_group_leave(group);
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        if (error) {
                            dispatch_group_leave(group);
                            return;
                        }
                        
                        if ([(NSObject *)item isKindOfClass:[NSURL class]]) {
                            NSURL *fileURL = (NSURL *)item;
                            if (![[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
                                dispatch_group_leave(group);
                                return;
                            }
                            
                            ZLSharePackage *package = [[ZLSharePackage alloc] init];
                            package.shareContent = [fileURL path];
                            package.shareType = ZLShareTypeFile;
                            [packages addObject:package];
                        }
                        
                        dispatch_group_leave(group);
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        if (error) {
                            dispatch_group_leave(group);
                            return;
                        }
                        
                        if ([(NSObject *)item isKindOfClass:[NSURL class]]) {
                            NSURL *webURL = (NSURL *)item;
                            if (webURL) {
                                ZLSharePackage *package = [[ZLSharePackage alloc] init];
                                package.shareContent = [webURL path];
                                package.shareType = ZLShareTypeWebURL;
                                [packages addObject:package];
                            }
                        }
                        
                        dispatch_group_leave(group);
                    }];
                }else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePlainText]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypePlainText options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        if (error) {
                            dispatch_group_leave(group);
                            return;
                        }
                        
                        if ([(NSObject *)item isKindOfClass:[NSString class]]) {
                            NSString *text = (NSString *)item;
                            if (text) {
                                ZLSharePackage *package = [[ZLSharePackage alloc] init];
                                package.shareContent = text;
                                package.shareType = ZLShareTypeText;
                                [packages addObject:package];
                            }
                        }
                        
                        dispatch_group_leave(group);
                    }];
                }
            }
            
            dispatch_group_notify(group, _serialQueue, ^{
                @synchronized(self) {
                    [self releaseAllPackageEntriesWithPackages:packages error:nil];
                    _isGettingData = NO;
                }
            });
        });
    }
}

- (void)uploadAllSharePackagesToURLString:(NSString *)urlString
                            configuration:(ZLSharePackageConfiguration *)configuration
                          progressHandler:(ZLUploadProgressHandler)progressHandler
                        completionHandler:(ZLUploadCompletionHandler)completionHandler
                                  inQueue:(dispatch_queue_t)queue {
    @synchronized(self) {
        ZLUploadAllPackageEntry *uploadEntry = [[ZLUploadAllPackageEntry alloc] init];
        uploadEntry.progressHandler = progressHandler;
        uploadEntry.completionHandler = completionHandler;
        uploadEntry.queue = queue;
        [_uploadAllPackageEntries addObject:uploadEntry];
        
        if (_isUploadingData) {
            return;
        }
        
        _isUploadingData = YES;
        
        ZLSharePackageConfiguration *targetConfiguration = configuration ? configuration : self.pkConfiguration;
        
        __weak __typeof__(self)weakSelf = self;
        [self getShareDataWithCompletionHandler:^(NSArray<ZLSharePackage *> *packages, NSError *error) {
            if (error) {
                [weakSelf releaseUploadAllEntriesWithError:@{kZLUploadSharePackageError: error}];
                return;
            }
            
            [weakSelf privateUploadSharePackages:packages
                                     toURLString:urlString
                                   configuration:targetConfiguration
                                 progressHandler:progressHandler
                               completionHandler:completionHandler
                                         inQueue:queue];
            
        } inQueue:mainQueue];
    }
}

- (void)uploadSharePackages:(NSArray<ZLSharePackage *> *)sharePackages
                toURLString:(NSString *)urlString
              configuration:(ZLSharePackageConfiguration *)configuration
            progressHandler:(ZLUploadProgressHandler)progressHandler
          completionHandler:(ZLUploadCompletionHandler)completionHandler
                    inQueue:(dispatch_queue_t)queue {
    
    @synchronized(self) {
        ZLUploadAllPackageEntry *uploadEntry = [[ZLUploadAllPackageEntry alloc] init];
        uploadEntry.progressHandler = progressHandler;
        uploadEntry.completionHandler = completionHandler;
        uploadEntry.queue = queue;
        [_uploadAllPackageEntries addObject:uploadEntry];
        
        if (_isUploadingData) {
            return;
        }
        
        _isUploadingData = YES;
        ZLSharePackageConfiguration *targetConfiguration = configuration ? configuration : self.pkConfiguration;
        [self privateUploadSharePackages:sharePackages
                             toURLString:urlString
                           configuration:targetConfiguration
                         progressHandler:progressHandler
                       completionHandler:completionHandler
                                 inQueue:queue];
    }
}

- (void)uploadSharePackage:(ZLSharePackage *)sharePackage
               toURLString:(NSString *)urlString
             configuration:(ZLSharePackageConfiguration *)configuration
           progressHandler:(ZLUploadPackageProgressHandler)progressHandler
         completionHandler:(ZLUploadCompletionHandler)completionHandler inQueue:(dispatch_queue_t)queue {
    
    NSError *inputError = nil;
    if (!sharePackage) {
        inputError = [NSError errorWithDomain:ShareDomain code:ZLInvalidInputError userInfo:@{@"message": @"Can't upload a nil package"}];
    } else if (![sharePackage.shareType isEqualToString:ZLShareTypeImage] &&
        ![sharePackage.shareType isEqualToString:ZLShareTypeVideo] &&
        ![sharePackage.shareType isEqualToString:ZLShareTypeFile]) {
        inputError = [NSError errorWithDomain:ShareDomain code:ZLInvalidTypeError userInfo:@{@"message": @"The package is invalid to upload"}];
    }
    
    if (inputError && completionHandler) {
        dispatch_async(GetValidQueue(queue), ^{
            completionHandler(@{kZLUploadSharePackageError: inputError});
        });
        return;
    }
    
    @synchronized(self) {
        BOOL allowRunUpload = NO;
        NSMutableArray *uploadPackageEntries = _uploadSharePackageMapping[@(sharePackage.packageId)];
        if (!uploadPackageEntries) {
            uploadPackageEntries = [NSMutableArray new];
            _uploadSharePackageMapping[@(sharePackage.packageId)] = uploadPackageEntries;
            allowRunUpload = YES;
        }
        
        ZLUploadPackageEntry *packageEntry = [[ZLUploadPackageEntry alloc] init];
        packageEntry.progressHandler = progressHandler;
        packageEntry.completionHandler = completionHandler;
        packageEntry.queue = queue;
        [uploadPackageEntries addObject:packageEntry];
        
        if (!allowRunUpload) {
            return;
        }
        
        __weak __typeof__(self) weakSelf = self;
        [self compressPackage:sharePackage withConfiguration:configuration completionHandler:^(NSURL *compressURL, NSError *error) {
            if (error) {
                [weakSelf releaseUploadEntriesOfPackage:sharePackage.packageId error:error];
                return;
            }
            
            [weakSelf.uploadAdapter uploadTaskWithHost:urlString
                                      filePath:[compressURL path]
                                        header:nil
                             completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
                                 if (error) {
                                     [weakSelf releaseUploadEntriesOfPackage:sharePackage.packageId error:error];
                                     return;
                                 }
                                 
                                 [uploadTask addCallbacksWithProgressCB:^(NSUInteger taskIdentifier, float progress) {
                                     [weakSelf notifyUploadProgressForUploadPackageEntries:uploadPackageEntries
                                                                                 packageId:sharePackage.packageId
                                                                                  progress:progress];
                                 } completionCB:^(NSUInteger taskIdentifier, NSError * _Nullable error) {
                                     [weakSelf releaseUploadEntriesOfPackage:sharePackage.packageId error:error];
                                 } changeStateCB:nil inQueue:globalDefaultQueue];
                                 
                                 [uploadTask resume];
                             }
                                      priority:HMURLUploadTaskPriorityHigh
                                       inQueue:globalDefaultQueue];
        }];
    }
}

- (void)completeExtension {
    if (_extensionContext) {
        [_extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }
}

- (void)cancelExtensionWithError:(NSError *)error {
    if (_extensionContext) {
        [_extensionContext cancelRequestWithError:error];
    }
}

#pragma mark - Private

- (void)privateUploadSharePackages:(NSArray<ZLSharePackage *> *)sharePackages
                       toURLString:(NSString *)urlString
                     configuration:(ZLSharePackageConfiguration *)configuration
                   progressHandler:(ZLUploadProgressHandler)progressHandler
                 completionHandler:(ZLUploadCompletionHandler)completionHandler
                           inQueue:(dispatch_queue_t)queue {
    
    //Implement code
    NSMutableDictionary *errorInfo = [NSMutableDictionary new];
    __block int uploadFailedCount = 0;
    __block int uploadCompletedCount = 0;
    
    NSMutableArray *allProgressDict = [NSMutableArray new];
    
    dispatch_group_t group = dispatch_group_create();
    [sharePackages enumerateObjectsUsingBlock:^(ZLSharePackage * _Nonnull package, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_group_enter(group);
        if (![package.shareType isEqualToString:ZLShareTypeImage] &&
            ![package.shareType isEqualToString:ZLShareTypeVideo] &&
            ![package.shareType isEqualToString:ZLShareTypeFile]) {
            dispatch_group_leave(group);
            return;
        }
        
        NSMutableDictionary *progressDict = [@{@"progress": @(0)} mutableCopy];
        [allProgressDict addObject:progressDict];
        
        __weak __typeof__(self) weakSelf = self;
        [self uploadSharePackage:package
                     toURLString:urlString
                   configuration:configuration
                 progressHandler:^(NSUInteger packageId, float progress) {
            progressDict[@"progress"] = @(progress);
            __block float allProgressValue = 0;
            [allProgressDict enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull progressDict, NSUInteger idx, BOOL * _Nonnull stop) {
                allProgressValue += [((NSNumber *)progressDict[@"progress"]) floatValue] / allProgressDict.count;
            }];
            
            [weakSelf notifyUploadProgressForUploadAllEntries:weakSelf.uploadAllPackageEntries progress:allProgressValue];
        }
               completionHandler:^(NSDictionary *uploadInfo) {
            NSError *error = uploadInfo[kZLUploadSharePackageError];
            if (error) {
                uploadFailedCount += 1;
            } else {
                uploadCompletedCount += 1;
            }
            dispatch_group_leave(group);
        } inQueue:weakSelf.serialQueue];
    }];
    
    dispatch_group_notify(group, _serialQueue, ^{
        @synchronized(self) {
            errorInfo[kZLUploadSharePackageCompletedCount] = @(uploadCompletedCount);
            errorInfo[kZLUploadSharePackageFailedCount] = @(uploadFailedCount);
            
            [self releaseUploadAllEntriesWithError:errorInfo];
        }
    });
}

- (void)compressPackage:(ZLSharePackage *)package withConfiguration:(ZLSharePackageConfiguration *)configuration completionHandler:(void(^)(NSURL *, NSError *))completionHandler {
    if (!completionHandler) {
        return;
    }
    
    ZLSharePackageConfiguration *targetConfiguration = configuration ? configuration : self.pkConfiguration;
    if (package.shareType == ZLShareTypeImage) {
        if (package.shareContent && [[NSFileManager defaultManager] fileExistsAtPath:package.shareContent]) {
            [ZLCompressUtils compressImageURL:[NSURL fileURLWithPath:package.shareContent] withScaleType:targetConfiguration.imageCompress completion:^(NSURL *compressURL, NSError *error) {
                completionHandler(compressURL, error);
            }];
        } else {
            NSError *error = [NSError errorWithDomain:ShareDomain code:ZLInvalidInputError userInfo:@{@"message": @"The image url want to compress is invalid (nil or file is not existed)"}];
            completionHandler(nil, error);
        }
        
        return;
    }
    
    if (package.shareType == ZLShareTypeVideo) {
        if (package.shareContent && [[NSFileManager defaultManager] fileExistsAtPath:package.shareContent]) {
            [ZLCompressUtils compressVideoURL:[NSURL fileURLWithPath:package.shareContent] compressType:targetConfiguration.videoCompress completion:^(NSURL *compressURL, NSError *error) {
                completionHandler(compressURL, error);
            }];
        } else {
            NSError *error = [NSError errorWithDomain:ShareDomain code:ZLInvalidInputError userInfo:@{@"message": @"The video url want to compress is invalid (nil or file is not existed)"}];
            completionHandler(nil, error);
        }
        
        return;
    }
    
    if (package.shareType == ZLShareTypeFile) {
        if (package.shareContent && [[NSFileManager defaultManager] fileExistsAtPath:package.shareContent]) {
            completionHandler([NSURL URLWithString:package.shareContent], nil);
        } else {
            NSError *error = [NSError errorWithDomain:ShareDomain code:ZLInvalidInputError userInfo:@{@"message": @"The file url is invalid (nil or file is not existed)"}];
            completionHandler(nil, error);
        }
        
        return;
    }
    
    NSError *error = [NSError errorWithDomain:ShareDomain code:ZLInvalidInputError userInfo:@{@"message": @"The input is not a file url"}];
    completionHandler(nil, error);
}

- (void)releaseAllPackageEntriesWithPackages:(NSArray *)packages error:(NSError *)error {
    @synchronized(self) {
        [_dataEntries enumerateObjectsUsingBlock:^(ZLSharePackageEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
            if (entry.completionHandler) {
                dispatch_async(GetValidQueue(entry.queue), ^{
                    entry.completionHandler(packages, error);
                });
            }
        }];
        
        [_dataEntries removeAllObjects];
    }
}

- (void)releaseUploadAllEntriesWithError:(NSDictionary *)uploadInfo {
    @synchronized(self) {
        [_uploadAllPackageEntries enumerateObjectsUsingBlock:^(ZLUploadAllPackageEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
            if (entry.completionHandler) {
                dispatch_async(GetValidQueue(entry.queue), ^{
                    entry.completionHandler(uploadInfo);
                });
            }
        }];
        
        [_uploadAllPackageEntries removeAllObjects];
        _isUploadingData = NO;
    }
}

- (void)releaseUploadEntriesOfPackage:(NSUInteger)packageId error:(NSError *)error {
    @synchronized(self) {
        NSMutableArray<ZLUploadPackageEntry *> *uploadPackageEntries = _uploadSharePackageMapping[@(packageId)];
        if (!uploadPackageEntries) {
            return;
        }
        
        [uploadPackageEntries enumerateObjectsUsingBlock:^(ZLUploadPackageEntry *  _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
            if (entry.completionHandler) {
                dispatch_async(GetValidQueue(entry.queue), ^{
                    if (error) {
                        entry.completionHandler(@{kZLUploadSharePackageError: error});
                    } else {
                        entry.completionHandler(@{});
                    }
                });
            }
        }];
        
        [uploadPackageEntries removeAllObjects];
        _uploadSharePackageMapping[@(packageId)] = nil;
    }
}

- (void)notifyUploadProgressForUploadAllEntries:(NSArray<ZLUploadAllPackageEntry *> *)uploadEntries progress:(float)progress {
    [uploadEntries enumerateObjectsUsingBlock:^(ZLUploadAllPackageEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        if (entry.progressHandler) {
            dispatch_async(GetValidQueue(entry.queue), ^{
                entry.progressHandler(progress);
            });
        }
    }];
}

- (void)notifyUploadProgressForUploadPackageEntries:(NSArray<ZLUploadPackageEntry *> *)uploadEntries packageId:(NSUInteger)packageId progress:(float)progress {
    [uploadEntries enumerateObjectsUsingBlock:^(ZLUploadPackageEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        if (entry.progressHandler) {
            dispatch_async(GetValidQueue(entry.queue), ^{
                entry.progressHandler(packageId, progress);
            });
        }
    }];
}

@end

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

#define ShareDomain                 @"com.hungmai.ShareExtension.ZLShareExtensionManager"

@implementation ZLSharePackageConfiguration
- (instancetype)init {
    if (self = [super init]) {
        _videoCompress = ZLVideoPackageCompressTypeOrigin;
        _imageCompress = ZLImagePackageCompressTypeOrigin;
        _textEncode = NSUTF8StringEncoding;
    }
    
    return self;
}
@end


@interface ZLShareExtensionManager()
@property(strong, nonatomic) ZLSharePackageConfiguration *pkConfiguration;
@property(strong, nonatomic) HMUploadAdapter *uploadAdapter;
@property(strong, nonatomic) dispatch_queue_t serialQueue;

@property(strong, nonatomic) NSMutableArray<ZLSharePackageEntry *> *dataEntries;
@property(strong, nonatomic) NSMutableArray<ZLUploadPackageEntry *> *uploadAllPackageEntries;
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
        shareInstance = [[self alloc] initPrivateWithShareId:@"group.com.nhuduydoan.shareextension"];
    });
    
    return shareInstance;
}

- (void)getShareDataWithConfiguration:(ZLSharePackageConfiguration *)configuration
                    completionHandler:(ZLSharePackageCompletionHandler)completionHandler
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
        
        ZLSharePackageConfiguration *targetConfiguration = configuration ? configuration : self.pkConfiguration;
        
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
                        NSLog(@"Image: %@", item);
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
                            
                            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
                            if (!imageData) {
                                dispatch_group_leave(group);
                                return;
                            }
                            
                            [ZLCompressUtils compressImageURL:imageURL withScaleType:targetConfiguration.imageCompress completion:^(NSData *imageData, NSError *error) {
                                if (!error) {
                                    ZLSharePackage *package = [[ZLSharePackage alloc] init];
                                    package.shareName = [imageURL lastPathComponent];
                                    package.shareData = imageData;
                                    package.shareType = ZLShareTypeImage;
                                    [packages addObject:package];
                                }
                                
                                dispatch_group_leave(group);
                            }];
                        } else {
                            dispatch_group_leave(group);
                        }
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"Movie: %@", item);
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
                            
                            [ZLCompressUtils compressVideoURL:videoURL compressType:targetConfiguration.videoCompress completion:^(NSData *videoData, NSError *error) {
                                if (!error) {
                                    ZLSharePackage *package = [[ZLSharePackage alloc] init];
                                    package.shareName = [videoURL lastPathComponent];
                                    package.shareData = videoData;
                                    package.shareType = ZLShareTypeVideo;
                                    [packages addObject:package];
                                }
                                
                                dispatch_group_leave(group);
                            }];
                        } else {
                            dispatch_group_leave(group);
                        }
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"File: %@", item);
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
                            
                            NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
                            if (fileData) {
                                ZLSharePackage *package = [[ZLSharePackage alloc] init];
                                package.shareName = [fileURL lastPathComponent];
                                package.shareData = fileData;
                                package.shareType = ZLShareTypeFile;
                                [packages addObject:package];
                            }
                            
                            dispatch_group_leave(group);
                        } else {
                            dispatch_group_leave(group);
                        }
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"WebURL: %@", item);
                        if (error) {
                            dispatch_group_leave(group);
                            return;
                        }
                        
                        if ([(NSObject *)item isKindOfClass:[NSURL class]]) {
                            NSURL *webURL = (NSURL *)item;
                            if (webURL) {
                                NSData *data = [[webURL path] dataUsingEncoding:targetConfiguration.textEncode];
                                if (data) {
                                    ZLSharePackage *package = [[ZLSharePackage alloc] init];
                                    package.shareName = @"WebURL";
                                    package.shareData = data;
                                    package.shareType = ZLShareTypeWebURL;
                                    [packages addObject:package];
                                }
                            }
                        }
                        
                        dispatch_group_leave(group);
                    }];
                }else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePlainText]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypePlainText options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"Text: %@", item);
                        if (error) {
                            dispatch_group_leave(group);
                            return;
                        }
                        
                        if ([(NSObject *)item isKindOfClass:[NSString class]]) {
                            NSString *text = (NSString *)item;
                            if (text) {
                                NSData *data = [text dataUsingEncoding:targetConfiguration.textEncode];
                                if (data) {
                                    ZLSharePackage *package = [[ZLSharePackage alloc] init];
                                    package.shareName = @"Text";
                                    package.shareData = data;
                                    package.shareType = ZLShareTypeText;
                                    [packages addObject:package];
                                }
                            }
                        }
                        
                        dispatch_group_leave(group);
                    }];
                }
            }
            
            dispatch_group_notify(group, weakSelf.serialQueue, ^{
                @synchronized(weakSelf) {
                    [weakSelf releaseAllPackageEntriesWithPackages:packages error:nil];
                    weakSelf.isGettingData = NO;
                }
            });
        });
    }
}

- (void)uploadAllSharePackageToURLString:(NSString *)urlString
                    withConfiguration:(ZLSharePackageConfiguration *)configuration
                      progressHandler:(ZLUploadProgressHandler)progressHandler
                    completionHandler:(ZLUploadCompletionHandler)completionHandler
                              inQueue:(dispatch_queue_t)queue {
    @synchronized(self) {
        ZLUploadPackageEntry *uploadEntry = [[ZLUploadPackageEntry alloc] init];
        uploadEntry.progressHandler = progressHandler;
        uploadEntry.completionHandler = completionHandler;
        uploadEntry.queue = queue;
        [_uploadAllPackageEntries addObject:uploadEntry];

        if (_isUploadingData) {
            return;
        }
        
        _isUploadingData = YES;
        
        __weak __typeof__(self)weakSelf = self;
        [self getShareDataWithConfiguration:configuration completionHandler:^(NSArray<ZLSharePackage *> *packages, NSError *error) {
            if (error) {
                [weakSelf releaseAllUploadEntriesWithError:@{kZLUploadSharePackageError: error}];
                return;
            }

            //Implement code
            NSMutableDictionary *errorInfo = [NSMutableDictionary new];
            __block int uploadFailedCount = 0;
            __block int uploadCompletedCount = 0;
            
            NSMutableArray *progressArr = [NSMutableArray new];
            
            dispatch_group_t group = dispatch_group_create();
            [packages enumerateObjectsUsingBlock:^(ZLSharePackage * _Nonnull package, NSUInteger idx, BOOL * _Nonnull stop) {
                dispatch_group_enter(group);
                NSMutableDictionary *taskprogress = [NSMutableDictionary new];
                [progressArr addObject:taskprogress];
                [weakSelf uploadSharePackage:package toURLString:urlString progressHandler:^(float progress) {
                    [taskprogress setValue:@(progress) forKey:@"progress"];
                    CGFloat allprogress = 0.0;
                    for (NSDictionary *num in progressArr) {
                        allprogress += [[num valueForKey:@"progress"] floatValue];
                    }
                    allprogress = allprogress/packages.count;
                    [weakSelf notifyUploadProgressForAllUploadEntries:weakSelf.uploadAllPackageEntries progress:allprogress];
                } completionHandler:^(NSDictionary *uploadInfo) {
                    if (error) {
                        uploadFailedCount += 1;
                    } else {
                        uploadCompletedCount += 1;
                    }
                    dispatch_group_leave(group);
                } inQueue:weakSelf.serialQueue];
            }];
            
            dispatch_group_notify(group, weakSelf.serialQueue, ^{
                @synchronized(weakSelf) {
                    errorInfo[kZLUploadSharePackageCompletedCount] = @(uploadCompletedCount);
                    errorInfo[kZLUploadSharePackageFailedCount] = @(uploadFailedCount);
                    
                    [weakSelf releaseAllUploadEntriesWithError:errorInfo];
                }
            });

        } inQueue:mainQueue];
    }
}

- (void)uploadSharePackage:(ZLSharePackage *)sharePackage
               toURLString:(NSString *)urlString progressHandler:(ZLUploadProgressHandler)progressHandler
         completionHandler:(ZLUploadCompletionHandler)completionHandler inQueue:(dispatch_queue_t)queue {
    
    if (!sharePackage) {
        if (completionHandler) {
            dispatch_async(queue, ^{
                NSError *error = [NSError errorWithDomain:ShareDomain code:ZLDataNilError userInfo:@{@"message": @"Can't upload a nil package"}];
                completionHandler(@{kZLUploadSharePackageError: error});
            });
        }
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
        [_uploadAdapter uploadTaskWithHost:urlString
                                  fileName:sharePackage.shareName
                                      data:sharePackage.shareData
                                    header:nil
                         completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
            if (error) {
                [weakSelf releaseAllUploadEntriesOfPackage:sharePackage.packageId error:error];
                return;
            }
            
            [uploadTask addCallbacksWithProgressCB:^(NSUInteger taskIdentifier, float progress) {
                [weakSelf notifyUploadProgressForAllUploadEntries:uploadPackageEntries progress:progress];
            } completionCB:^(NSUInteger taskIdentifier, NSError * _Nullable error) {
                [weakSelf releaseAllUploadEntriesOfPackage:sharePackage.packageId error:error];
            } changeStateCB:nil inQueue:globalDefaultQueue];
                             
            [uploadTask resume];
        }
                                  priority:HMURLUploadTaskPriorityHigh
                                   inQueue:globalDefaultQueue];

    }
}

- (void)completeExtension {
    if (_extensionContext) {
        [_extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }
}

- (void)cancelExtensionWithError:(NSError *)error {
    NSAssert(error, @"Error must be non null");
    if (_extensionContext) {
        [_extensionContext cancelRequestWithError:error];
    }
}

- (BOOL)setPackageConfiguration:(ZLSharePackageConfiguration *)configuration {
    if (_isGettingData || !configuration) {
        return NO;
    }
    
    _pkConfiguration = configuration;
    return YES;
}

#pragma mark - Private

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

- (void)releaseAllUploadEntriesWithError:(NSDictionary *)uploadInfo {
    @synchronized(self) {
        [_uploadAllPackageEntries enumerateObjectsUsingBlock:^(ZLUploadPackageEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
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

- (void)releaseAllUploadEntriesOfPackage:(NSUInteger)packageId error:(NSError *)error {
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

- (void)notifyUploadProgressForAllUploadEntries:(NSArray<ZLUploadPackageEntry *> *)uploadEntries progress:(float)progress {
    [uploadEntries enumerateObjectsUsingBlock:^(ZLUploadPackageEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        if (entry.progressHandler) {
            dispatch_async(GetValidQueue(entry.queue), ^{
                entry.progressHandler(progress);
            });
        }
    }];
}

@end

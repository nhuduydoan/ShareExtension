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
#define ShareContainerBackgroundConfiguration       @"group.com.zalo.shareextension"

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
@property(strong, nonatomic) ZLCompressConfiguration *defaultConfiguration;
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
        _defaultConfiguration = [ZLCompressConfiguration mediumConfiguration];
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
            
            NSArray *validTypeIdentifies = @[(NSString *)kUTTypeImage,
                                             (NSString *)kUTTypeMovie,
                                             (NSString *)kUTTypeFileURL,
                                             (NSString *)kUTTypeURL,
                                             (NSString *)kUTTypePlainText];
            
            for (NSItemProvider *provider in item.attachments) {
                dispatch_group_enter(group);
                for (NSString *typeIdentify in validTypeIdentifies) {
                    if (![provider hasItemConformingToTypeIdentifier:typeIdentify]) {
                        continue;
                    }
                    
                    [provider loadItemForTypeIdentifier:typeIdentify options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        ZLSharePackage *package = [self makePackageWithItem:item typeIdentify:typeIdentify error:error];
                        if (package) {
                            [provider loadPreviewImageWithOptions:nil completionHandler:^(UIImage *image, NSError *error) {
                                if (image) {
                                    package.shareThumbnail = image;
                                }
                                dispatch_group_leave(group);
                            }];
                            
                            [packages addObject:package];
                        }
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
                            configuration:(ZLCompressConfiguration *)configuration
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
        
        __weak __typeof__(self)weakSelf = self;
        [self getShareDataWithCompletionHandler:^(NSArray<ZLSharePackage *> *packages, NSError *error) {
            if (error) {
                [weakSelf releaseUploadAllEntriesWithError:@{kZLUploadSharePackageError: error}];
                return;
            }
            
            [weakSelf privateUploadSharePackages:packages
                                     toURLString:urlString
                                   configuration:configuration
                                 progressHandler:progressHandler
                               completionHandler:completionHandler
                                         inQueue:queue];
            
        } inQueue:mainQueue];
    }
}

- (void)uploadSharePackages:(NSArray<ZLSharePackage *> *)sharePackages
                toURLString:(NSString *)urlString
              configuration:(ZLCompressConfiguration *)configuration
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
        [self privateUploadSharePackages:sharePackages
                             toURLString:urlString
                           configuration:configuration
                         progressHandler:progressHandler
                       completionHandler:completionHandler
                                 inQueue:queue];
    }
}

- (void)uploadSharePackage:(ZLSharePackage *)sharePackage
               toURLString:(NSString *)urlString
             configuration:(ZLCompressConfiguration *)configuration
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
                     configuration:(ZLCompressConfiguration *)configuration
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

- (void)compressPackage:(ZLSharePackage *)package withConfiguration:(ZLCompressConfiguration *)configuration completionHandler:(void(^)(NSURL *, NSError *))completionHandler {
    if (!completionHandler) {
        return;
    }
    
    ZLCompressConfiguration *targetConfiguration = configuration ? configuration : _defaultConfiguration;
    if (package.shareType == ZLShareTypeImage) {
        if (package.shareContent && [[NSFileManager defaultManager] fileExistsAtPath:package.shareContent]) {
            [sCompressManager compressImageURL:[NSURL fileURLWithPath:package.shareContent] withScaleType:targetConfiguration.imageCompress completion:^(NSURL *compressURL, NSError *error) {
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
            [sCompressManager compressVideoURL:[NSURL fileURLWithPath:package.shareContent] compressSetting:targetConfiguration.videoSetting completion:^(NSURL *compressURL, NSError *error) {
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

- (ZLSharePackage *)makePackageWithItem:(id)item typeIdentify:(NSString *)typeIdentity error:(NSError *)error {
    if (error) {
        return nil;
    }
    
    ZLSharePackage *package = [[ZLSharePackage alloc] init];
    
    if ([typeIdentity isEqualToString:(NSString *)kUTTypeImage] ||
        [typeIdentity isEqualToString:(NSString *)kUTTypeMovie] ||
        [typeIdentity isEqualToString:(NSString *)kUTTypeFileURL] ||
        [typeIdentity isEqualToString:(NSString *)kUTTypeURL]) {
        NSURL *url = (NSURL *)item;
        if (!url) {
            return nil;
        }
        
        if ([typeIdentity isEqualToString:(NSString *)kUTTypeImage] ||
            [typeIdentity isEqualToString:(NSString *)kUTTypeMovie] ||
            [typeIdentity isEqualToString:(NSString *)kUTTypeFileURL]) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
                return nil;
            }
        }

        package.shareContent = [url path];
    
        if ([typeIdentity isEqualToString:(NSString *)kUTTypeImage]) {
            package.shareType = ZLShareTypeImage;
        } else if ([typeIdentity isEqualToString:(NSString *)kUTTypeMovie]) {
            package.shareType = ZLShareTypeVideo;
            package.shareInfo[kZLShareInfoVideoDuration] = [self getDurationOfVideo:url];
        } else if ([typeIdentity isEqualToString:(NSString *)kUTTypeFileURL]) {
            package.shareType = ZLShareTypeFile;
        } else if ([typeIdentity isEqualToString:(NSString *)kUTTypeURL]) {
            package.shareType = ZLShareTypeWebURL;
        }
    } else if ([typeIdentity isEqualToString:(NSString *)kUTTypeText]) {
        NSString *text = (NSString *)item;
        if (!text) {
            return nil;
        }
        
        package.shareContent = text;
    }
    
    
    
    return package;
}

- (NSString *)getDurationOfVideo:(NSURL *)videoURL {
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    CMTime duration = sourceAsset.duration;
    NSString *videoDuration = [self transformedTime:duration];
    return videoDuration;
}

- (NSString *)transformedTime:(CMTime)tỉme {
    float duration = (float)tỉme.value/(float)tỉme.timescale;
    int seconds = floor(duration + 0.6);
    NSString *hoursStr = @"";
    NSString *munitesStr = @"00";
    NSString *secondsStr = @"";
    if (seconds >= 3600) {
        int hours = seconds/3600;
        seconds = seconds - hours*3600;
        hoursStr = [NSString stringWithFormat:@"%d:", hours];
    }
    if (seconds > 60) {
        int munites = seconds/60;
        seconds = seconds - munites *60;
        if (munites >= 10) {
            munitesStr = [NSString stringWithFormat:@"%d:", munites];
        } else {
            munitesStr = [NSString stringWithFormat:@"0%d:", munites];
        }
    }
    if (seconds >= 10) {
        secondsStr = [NSString stringWithFormat:@"%d:", seconds];
    } else {
        secondsStr = [NSString stringWithFormat:@"0%d", seconds];
    }
    NSString *timeString = [NSString stringWithFormat:@"%@%@:%@", hoursStr, munitesStr, secondsStr];
    return timeString;
}

@end

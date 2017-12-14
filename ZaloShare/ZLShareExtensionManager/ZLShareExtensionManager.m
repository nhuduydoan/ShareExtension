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

@property(nonatomic) BOOL isGettingData;
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
        shareInstance = [[self alloc] initPrivateWithShareId:@""];
    });
    
    return shareInstance;
}

- (void)getShareDataWithPackageHandler:(ZLSharePackageHandler)packageHandler
                     completionHandler:(ZLSharePackageCompletionHandler)completionHandler
                               inQueue:(dispatch_queue_t)queue {
    @synchronized(self) {
        if (!_extensionContext) {
            if (completionHandler) {
                NSError *error = [NSError errorWithDomain:ShareDomain code:ZLShareNilExtensionContextError userInfo:@{@"message": @"The extionsion context must is not equal to nil"}];
                dispatch_async(GetValidQueue(queue), ^{
                    completionHandler(error);
                });
            }
        }
        
        ZLSharePackageEntry *packageEntry = [[ZLSharePackageEntry alloc] initWithPackageHandler:packageHandler completionHandler:completionHandler inQueue:queue];
        [_dataEntries addObject:packageEntry];
        if (_isGettingData) {
            return;
        }
        
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(weakSelf.serialQueue, ^{
            weakSelf.isGettingData = YES;
            NSExtensionItem *item = weakSelf.extensionContext.inputItems.firstObject;
            if (!item) {
                NSError *error = [NSError errorWithDomain:ShareDomain code:ZLShareNilExtensionItemError userInfo:@{@"message": @"The extension item is nil"}];
                [self releaseAllEntriesWithError:error];
                weakSelf.isGettingData = NO;
            }
            
            dispatch_group_t group = dispatch_group_create();
            for (NSItemProvider *provider in item.attachments) {
                dispatch_group_enter(group);
                if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"Image: %@", item);
                        if (error) {
                            [weakSelf notifyForAllEntriesAboutPackage:nil error:error];
                            return;
                        }
                        
                        NSURL *imageURL = (NSURL *)item;
                        if ([(NSObject *)item isKindOfClass:[NSURL class]]) {
                            if (![[NSFileManager defaultManager] fileExistsAtPath:[imageURL path]]) {
                                NSError *error = [NSError errorWithDomain:@"" code:1 userInfo:@{@"message": @"File isn't exist"}];
                                [weakSelf notifyForAllEntriesAboutPackage:nil error:error];
                                return;
                            }
                            
                            if (weakSelf.pkConfiguration.imageCompress == ZLImagePackageCompressTypeOrigin) {
                                NSData *originData = [NSData dataWithContentsOfURL:imageURL];
                                ZLSharePackage *package = [[ZLSharePackage alloc] initWithShareObject:originData shareType:ZLShareTypeImage];
                                [weakSelf notifyForAllEntriesAboutPackage:package error:nil];
                            } else {
                                CGSize scaleSize = [weakSelf getImageSizeForImageCompressType:weakSelf.pkConfiguration.imageCompress];
                                [ZLCompressUtils compressImageURL:(NSURL *)item withScaleSize:scaleSize completion:^(NSData *imageData, NSError *error) {
                                    if (error) {
                                        [weakSelf notifyForAllEntriesAboutPackage:nil error:error];
                                    } else {
                                        ZLSharePackage *package = [[ZLSharePackage alloc] initWithShareObject:imageData shareType:ZLShareTypeImage];
                                        [weakSelf notifyForAllEntriesAboutPackage:package error:error];
                                    }
                                }];
                            }
                        }
                        
                        dispatch_group_leave(group);
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"Movie: %@", item);
                        if (error) {
                            [weakSelf notifyForAllEntriesAboutPackage:nil error:error];
                            return;
                        }
                        
                        
                        
//                        NSURL *imageURL = (NSURL *)item;
                        
                        dispatch_group_leave(group);
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"File: %@", item);
                        if (error) {
                            [weakSelf notifyForAllEntriesAboutPackage:nil error:error];
                            return;
                        }
                        
                        dispatch_group_leave(group);
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"WebURL: %@", item);
                        if (error) {
                            [weakSelf notifyForAllEntriesAboutPackage:nil error:error];
                            return;
                        }
                        
                        dispatch_group_leave(group);
                    }];
                }else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePlainText]) {
                    [provider loadItemForTypeIdentifier:(NSString *)kUTTypePlainText options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"Text: %@", item);
                        if (error) {
                            [weakSelf notifyForAllEntriesAboutPackage:nil error:error];
                            return;
                        }
                        
                        dispatch_group_leave(group);
                    }];
                }
            }
            
            dispatch_group_notify(group, _serialQueue, ^{
                @synchronized(self) {
                    [self releaseAllEntriesWithError:nil];
                    _isGettingData = NO;
                }
            });
        });
    }
}

- (void)uploadAllShareDataWithConfiguration:(ZLSharePackageConfiguration *)configuration completionHandler:(void (^)(NSError *))completionHandler {
    //Implement code
}

- (BOOL)setPackageConfiguration:(ZLSharePackageConfiguration *)configuration {
    if (_isGettingData || !configuration) {
        return NO;
    }
    
    _pkConfiguration = configuration;
    return YES;
}

- (void)setShareId:(NSString *)shareId {
    
}

#pragma mark - Private

- (void)releaseAllEntriesWithError:(NSError *)error {
    @synchronized(self) {
        [_dataEntries enumerateObjectsUsingBlock:^(ZLSharePackageEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
            if (entry.completionHandler) {
                dispatch_async(GetValidQueue(entry.queue), ^{
                    entry.completionHandler(error);
                });
            }
        }];
        
        [_dataEntries removeAllObjects];
    }
}

- (void)notifyForAllEntriesAboutPackage:(ZLSharePackage *)package error:(NSError *)error {
    @synchronized(self) {
        [_dataEntries enumerateObjectsUsingBlock:^(ZLSharePackageEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
            if (entry.packageHandler) {
                dispatch_async(GetValidQueue(entry.queue), ^{
                    entry.packageHandler(package, error);
                });
            }
        }];
    }
}

- (NSString *)getPresetNameWithCompressType:(ZLVideoPackageCompressType)compressType {
    switch (compressType) {
        case ZLVideoPackageCompressTypeLow:
            return AVCaptureSessionPresetLow;
        case ZLVideoPackageCompressTypeMedium:
            return AVCaptureSessionPresetMedium;
        case ZLVideoPackageCompressTypeHigh:
            return AVCaptureSessionPresetHigh;
        case ZLVideoPackageCompressType640x480:
            return AVCaptureSessionPreset640x480;
        case ZLVideoPackageCompressType1280x720:
            return AVCaptureSessionPreset1280x720;
        case ZLVideoPackageCompressType1920x1080:
            return AVCaptureSessionPreset1920x1080;
        default:
            break;
    }
    return @"";
}

- (CGSize)getImageSizeForImageCompressType:(ZLImagePackageCompressType)compressType {
    switch (compressType) {
        case ZLImagePackageCompressType640x480:
            return CGSizeMake(640, 480);
        case ZLImagePackageCompressType1280x720:
            return CGSizeMake(640, 480);
        case ZLImagePackageCompressType1920x1080:
            return CGSizeMake(640, 480);
            
        default:
            return CGSizeZero;
    }
}

@end

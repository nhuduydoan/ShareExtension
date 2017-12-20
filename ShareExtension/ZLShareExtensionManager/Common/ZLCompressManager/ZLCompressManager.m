//
//  ZLVideoCompressUtils.m
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ZLCompressManager.h"
#import "ZLShareDefine.h"
#import "ZLAssetExportSession.h"

#define  ZLCompressManagerDomain                @"com.hungmai.ZLCompressUtils"

@interface ZLCompressManager()
@property(strong, nonatomic) NSMutableDictionary *runningExportSession;
@end


@implementation ZLCompressManager

- (instancetype)init {
    if (self = [super init]) {
        _runningExportSession = [NSMutableDictionary new];
    }
    return self;
}

+ (instancetype)shareInstance {
    static ZLCompressManager *shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    
    return shareInstance;
}

- (void)compressVideoURL:(NSURL *)videoURL
            compressType:(ZLVideoPackageCompressType)compressType
              completion:(void (^)(NSURL *, NSError *))completionBlock {
    
    if (!completionBlock) {
        return;
    }
    
    __block NSError *error;
    
    if (compressType < ZLVideoPackageCompressTypeOrigin || compressType > ZLVideoPackageCompressType1920x1080) {
        error = [NSError errorWithDomain:ZLCompressManagerDomain code:ZLCompressTypeUnknowError userInfo:@{@"message": @"The video compress type unknown"}];
        completionBlock(nil, error);
        return;
    }
    
    if (compressType == ZLVideoPackageCompressTypeOrigin) {
        completionBlock(videoURL, nil);
        return;
    }
    
    dispatch_async(globalDefaultQueue, ^{
        NSURL *tempCompressURL = [self getCompressFileURLWithInputFileURL:videoURL];
        
        if (!tempCompressURL) {
            error = [NSError errorWithDomain:ZLCompressManagerDomain code:ZLCompressVideoError userInfo:@{@"message": @"The compress url is unknown"}];
            completionBlock(nil, error);
            return;
        }
        
        NSString *exportPreset = [self getPresetNameWithCompressType:compressType];
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
        if (asset) {
            AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:exportPreset];
            if (!session) {
                NSError *error = [NSError errorWithDomain:ZLCompressManagerDomain code:ZLCompressVideoError userInfo:@{@"message": @"Can't create export session of video"}];
                completionBlock(nil, error);
                return;
            }
            
            session.outputURL = tempCompressURL;
            session.outputFileType = AVFileTypeQuickTimeMovie;
            [session exportAsynchronouslyWithCompletionHandler:^{
                switch (session.status) {
                    case AVAssetExportSessionStatusCompleted: {
                        completionBlock(tempCompressURL, nil);
                        break;
                    }
                    case AVAssetExportSessionStatusFailed:
                    case AVAssetExportSessionStatusCancelled:
                        if (completionBlock) {
                            completionBlock(nil, session.error);
                        }
                        break;
                        
                    default:
                        break;
                }
                
            }];
        } else {
            NSError *error = [NSError errorWithDomain:ZLCompressManagerDomain code:ZLCompressVideoError userInfo:@{@"message": @"Can't get asset of video url"}];
            completionBlock(nil, error);
        }
    });
}

- (void)compressVideoURL:(NSURL *)videoURL
         compressSetting:(ZLVideoCompressSetting *)videoSetting
              completion:(void (^)(NSURL *, NSError *))completionBlock {
    
    if (!completionBlock) {
        return;
    }
    
    dispatch_async(globalDefaultQueue, ^{
        NSError *error = nil;
        NSURL *tempCompressURL = [self getCompressFileURLWithInputFileURL:videoURL];
        
        if (!tempCompressURL) {
            error = [NSError errorWithDomain:ZLCompressManagerDomain code:ZLCompressVideoError userInfo:@{@"message": @"The compress url is unknown"}];
            completionBlock(nil, error);
            return;
        }
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
        if (!asset) {
            error = [NSError errorWithDomain:ZLCompressManagerDomain code:ZLCompressVideoError userInfo:@{@"message": @"Can't get asset of video url"}];
            completionBlock(nil, error);
            return;
        }
        
        ZLAssetExportSession *exportSession = [[ZLAssetExportSession alloc] initWithAsset:asset];
        exportSession.outputURL = tempCompressURL;
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.videoSettings = @{AVVideoCodecKey: videoSetting.videoCodec,
                                        AVVideoWidthKey: @(videoSetting.videoResolution.width),
                                        AVVideoHeightKey: @(videoSetting.videoResolution.height),
                                        AVVideoCompressionPropertiesKey: @{
                                                AVVideoAverageBitRateKey: @(videoSetting.videoBitrate),
                                                AVVideoAverageNonDroppableFrameRateKey: @(videoSetting.videoFrameRate),
                                                AVVideoProfileLevelKey: videoSetting.videoProfileLevel,
                                                }
                                        };
        
        exportSession.audioSettings = @{AVFormatIDKey: @(videoSetting.audioFormat),
                                        AVNumberOfChannelsKey: @(videoSetting.numberOfChannels),
                                        AVSampleRateKey: @(videoSetting.audioSampleRate),
                                        AVEncoderBitRateKey: @(videoSetting.audioBitRate)
                                        };
        
        [_runningExportSession setObject:exportSession forKey:exportSession.sessionId];
        
        [exportSession exportAsynchronouslyWithProgressCallback:nil completionHandler:^(NSError *error) {
            if (error) {
                completionBlock(nil, error);
            } else {
                completionBlock(tempCompressURL, nil);
                _runningExportSession[exportSession.sessionId] = nil;
            }
        } inQueue:globalDefaultQueue];
    });
}

- (void)compressImageURL:(NSURL *)imageURL
           withScaleType:(ZLImagePackageCompressType)compressType
              completion:(void (^)(NSURL *, NSError *))completionBlock {
    
    if (!completionBlock) {
        return;
    }
    
    __block NSError *error;
    
    if (compressType < ZLImagePackageCompressTypeOrigin || compressType > ZLImagePackageCompressType1920x1080) {
        error = [NSError errorWithDomain:ZLCompressManagerDomain code:ZLCompressTypeUnknowError userInfo:@{@"message": @"The image compress type unknown"}];
        completionBlock(nil, error);
        return;
    }
    
    if (compressType == ZLImagePackageCompressTypeOrigin) {
        completionBlock(imageURL, nil);
        return;
    }
    
    dispatch_async(globalDefaultQueue, ^{
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        if (!imageData) {
            error = [NSError errorWithDomain:@"com.hungmai.ZLCompressUtils" code:ZLInvalidInputError userInfo:@{@"message": @"Data of image is nil"}];
            completionBlock(nil, error);
            return;
        }

        UIImage *image = [UIImage imageWithData:imageData];
        if (!image) {
            error = [NSError errorWithDomain:@"com.hungmai.ZLCompressUtils" code:ZLCompressImageError userInfo:@{@"message": @"The url is not an image"}];
            completionBlock(nil, error);
            return;
        }
        
        CGSize size = [self getImageSizeForImageCompressType:compressType];
        
        CGFloat scale = 1;
        
        if (image.size.width > image.size.height) {
            scale = size.width / image.size.width;
        } else {
            scale = size.width / image.size.height;
        }
        
        float newHeight = image.size.height * scale;
        float newWidth = image.size.width * scale;
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
        [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSData *imageCompressData = UIImageJPEGRepresentation(scaledImage, 1);
        if (!imageCompressData) {
            error = [NSError errorWithDomain:@"com.hungmai.ZLCompressUtils" code:ZLCompressImageError userInfo:@{@"message": @"The scaled image can't be convert to data"}];
            completionBlock(nil, error);
            return;
        }
        
        NSURL *tempCompressURL = [self getCompressFileURLWithInputFileURL:imageURL];
        if (!tempCompressURL) {
            error = [NSError errorWithDomain:ZLCompressManagerDomain code:ZLCompressVideoError userInfo:@{@"message": @"The compress url is unknown"}];
            completionBlock(nil, error);
        }
        
        [imageCompressData writeToURL:tempCompressURL atomically:NO];
        completionBlock(tempCompressURL, nil);
    });
}


#pragma mark - Private Static

- (NSString *)getPresetNameWithCompressType:(ZLVideoPackageCompressType)compressType {
    switch (compressType) {
        case ZLVideoPackageCompressTypeLow:
            return AVAssetExportPresetLowQuality;
        case ZLVideoPackageCompressTypeMedium:
            return AVAssetExportPresetMediumQuality;
        case ZLVideoPackageCompressTypeHigh:
            return AVAssetExportPresetHighestQuality;
        case ZLVideoPackageCompressType640x480:
            return AVAssetExportPreset640x480;
        case ZLVideoPackageCompressType1280x720:
            return AVAssetExportPreset1280x720;
        case ZLVideoPackageCompressType1920x1080:
            return AVAssetExportPreset1920x1080;
        default:
            break;
    }
    return @"";
}

- (CGSize)getImageSizeForImageCompressType:(ZLImagePackageCompressType)compressType {
    switch (compressType) {
        case ZLImagePackageCompressType480x320:
            return CGSizeMake(480, 320);
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

- (NSURL *)getCompressFileURLWithInputFileURL:(NSURL *)inputFileURL {
    NSString *fileName = [inputFileURL lastPathComponent];
    NSArray<NSString *> *fileNameComponent = [fileName componentsSeparatedByString:@"."];
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    NSString *tempFileName = @"";
    if (fileNameComponent.count >= 2) {
        for (int i = 0; i < fileNameComponent.count - 1; i++) {
            tempFileName = [NSString stringWithFormat:@"%@.%@", tempFileName, fileNameComponent[i]];
        }
        
        tempFileName = [NSString stringWithFormat:@"%@_compress_%i.%@", tempFileName, (int)timestamp, fileNameComponent[fileNameComponent.count - 1]];
    }
    
    NSURL *tempCompressURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName]];
    return tempCompressURL;
}

@end

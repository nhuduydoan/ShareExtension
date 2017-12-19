//
//  ZLVideoCompressUtils.m
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ZLCompressUtils.h"
#import "ZLShareDefine.h"

#define  ZLCompressUtilsDomain                @"com.hungmai.ZLCompressUtils"

@implementation ZLCompressUtils

+ (void)compressVideoURL:(NSURL *)videoURL
            compressType:(ZLVideoPackageCompressType)compressType
              completion:(void (^)(NSURL *, NSError *))completionBlock {
    
    if (!completionBlock) {
        return;
    }
    
    __block NSError *error;
    
    if (compressType < ZLVideoPackageCompressTypeOrigin || compressType > ZLVideoPackageCompressType1920x1080) {
        error = [NSError errorWithDomain:ZLCompressUtilsDomain code:ZLCompressTypeUnknowError userInfo:@{@"message": @"The video compress type unknown"}];
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
            error = [NSError errorWithDomain:ZLCompressUtilsDomain code:ZLCompressVideoError userInfo:@{@"message": @"The compress url is unknown"}];
            completionBlock(nil, error);
        }
        
        NSString *exportPreset = [self getPresetNameWithCompressType:compressType];
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
        if (asset) {
            AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:exportPreset];
            if (!session) {
                NSError *error = [NSError errorWithDomain:ZLCompressUtilsDomain code:ZLCompressVideoError userInfo:@{@"message": @"Can't create export session of video"}];
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
            NSError *error = [NSError errorWithDomain:ZLCompressUtilsDomain code:ZLCompressVideoError userInfo:@{@"message": @"Can't get asset of video url"}];
            completionBlock(nil, error);
        }
    });
}

+ (void)compressImageURL:(NSURL *)imageURL withScaleType:(ZLImagePackageCompressType)compressType completion:(void (^)(NSURL *, NSError *))completionBlock {
    if (!completionBlock) {
        return;
    }
    
    __block NSError *error;
    
    if (compressType < ZLImagePackageCompressTypeOrigin || compressType > ZLImagePackageCompressType1920x1080) {
        error = [NSError errorWithDomain:ZLCompressUtilsDomain code:ZLCompressTypeUnknowError userInfo:@{@"message": @"The image compress type unknown"}];
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
            error = [NSError errorWithDomain:ZLCompressUtilsDomain code:ZLCompressVideoError userInfo:@{@"message": @"The compress url is unknown"}];
            completionBlock(nil, error);
        }
        
        [imageCompressData writeToURL:tempCompressURL atomically:NO];
        completionBlock(tempCompressURL, nil);
    });
}


#pragma mark - Private Static

+ (NSString *)getPresetNameWithCompressType:(ZLVideoPackageCompressType)compressType {
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

+ (CGSize)getImageSizeForImageCompressType:(ZLImagePackageCompressType)compressType {
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

+ (NSURL *)getCompressFileURLWithInputFileURL:(NSURL *)inputFileURL {
    NSString *fileName = [inputFileURL lastPathComponent];
    NSArray<NSString *> *fileNameComponent = [fileName componentsSeparatedByString:@"."];
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    NSString *tempFileName = nil;
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

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
              completion:(void (^)(NSData *videoData, NSError *))completionBlock {
    
    if (!completionBlock) {
        return;
    }
    
    __block NSError *error;
    
    if (compressType < ZLVideoPackageCompressTypeOrigin || compressType > ZLVideoPackageCompressType1920x1080) {
        error = [NSError errorWithDomain:ZLCompressUtilsDomain code:ZLCompressTypeUnknowError userInfo:@{@"message": @"The video compress type unknown"}];
        completionBlock(nil, error);
        return;
    }
    
    NSString *fileName = [videoURL lastPathComponent];
    NSURL *tempCompressURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    NSString *exportPreset = [self getPresetNameWithCompressType:compressType];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    if (asset) {
        AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:exportPreset];
        session.outputFileType = AVFileTypeQuickTimeMovie;
        session.outputURL = tempCompressURL;
        session.shouldOptimizeForNetworkUse = YES;
        [session exportAsynchronouslyWithCompletionHandler:^{
            NSData *compressData;
            switch (session.status) {
                case AVAssetExportSessionStatusCompleted: {
                    if ([[NSFileManager defaultManager] fileExistsAtPath:[tempCompressURL path]]) {
                        compressData = [NSData dataWithContentsOfURL:tempCompressURL];
                        [[NSFileManager defaultManager] removeItemAtURL:tempCompressURL error:nil];
                    }
                }
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusCancelled:
                    if (completionBlock) {
                        completionBlock(compressData, session.error);
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
}

+ (void)compressImageURL:(NSURL *)imageURL withScaleType:(ZLImagePackageCompressType)compressType completion:(void (^)(NSData *imageData, NSError *error))completionBlock {
    if (!completionBlock) {
        return;
    }
    
    __block NSError *error;
    
    if (compressType < ZLImagePackageCompressTypeOrigin || compressType > ZLImagePackageCompressType1920x1080) {
        error = [NSError errorWithDomain:ZLCompressUtilsDomain code:ZLCompressTypeUnknowError userInfo:@{@"message": @"The image compress type unknown"}];
        completionBlock(nil, error);
        return;
    }
    
    dispatch_async(globalDefaultQueue, ^{
        
        
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        if (!imageData) {
            error = [NSError errorWithDomain:@"com.hungmai.ZLCompressUtils" code:ZLDataNilError userInfo:@{@"message": @"Data of image is nil"}];
            completionBlock(nil, error);
            return;
        }
        
        if (compressType == ZLImagePackageCompressTypeOrigin) {
            completionBlock(imageData, nil);
            return;
        }
        
        CGSize size = [self getImageSizeForImageCompressType:compressType];
        CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                               (id) kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                               (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                               (id) kCGImageSourceThumbnailMaxPixelSize : @(size)
                                                               };
        
        CGImageRef scaledImageRef = CGImageSourceCreateThumbnailAtIndex(src, 0, options);
        UIImage *scaled = [UIImage imageWithCGImage:scaledImageRef];
        CGImageRelease(scaledImageRef);
        NSData *compressData = UIImageJPEGRepresentation(scaled, 1);
        if (!compressData) {
            error = [NSError errorWithDomain:@"com.hungmai.ZLCompressUtils" code:ZLCompressImageError userInfo:@{@"message": [NSString stringWithFormat:@"Can't compress image with size (%f, %f)", size.width, size.height]}];
        }
        
        completionBlock(compressData, error);
    });
}


#pragma mark - Private Static

+ (NSString *)getPresetNameWithCompressType:(ZLVideoPackageCompressType)compressType {
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

@end

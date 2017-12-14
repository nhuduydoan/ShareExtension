//
//  ZLVideoCompressUtils.m
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ZLCompressUtils.h"
#import "ZLShareDefine.h"

@implementation ZLCompressUtils

+ (void)compressVideoURL:(NSURL *)videoURL
            compressType:(AVCaptureSessionPreset)compressType
              completion:(void (^)(NSData *videoData, NSError *))completionBlock {
    NSString *fileName = [videoURL lastPathComponent];
    NSURL *tempCompressURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    if (asset) {
        AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:compressType];
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
    }
}

+ (void)compressImageURL:(NSURL *)imageURL withScaleSize:(CGSize)size completion:(void (^)(NSData *imageData, NSError *error))completionBlock {
    dispatch_async(globalDefaultQueue, ^{

        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
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
        NSError *error;
        if (!compressData) {
            error = [NSError errorWithDomain:@"com.hungmai.ZLCompressUtils" code:ZLCompressImageError userInfo:@{@"message": [NSString stringWithFormat:@"Can't compress image with size (%f, %f)", size.width, size.height]}];
        }
        
        if (completionBlock) {
            completionBlock(compressData, error);
        }
    });
}

@end

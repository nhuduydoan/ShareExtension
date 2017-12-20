//
//  ZLVideoCompressUtils.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZLCompressConfiguration.h"
#import <AVKit/AVKit.h>

#define sCompressManager            [ZLCompressManager shareInstance]

@interface ZLCompressManager : NSObject

+ (instancetype)shareInstance;


/**
 Compress a video with 'ZLVideoPackageCompressType'. The method will use some default compression of AVAsset to compress the video

 @param videoURL The url of video
 @param compressType The type user want to compress (Low, Medium, High, 620x480,...)
 @param completionBlock The callback for handling the completion of the compression
 */
- (void)compressVideoURL:(NSURL *)videoURL
            compressType:(ZLVideoPackageCompressType)compressType
              completion:(void (^)(NSURL *compressURL, NSError *error))completionBlock;


/**
 Compress a video with 'ZLVideoCompressSetting' object to set output of compressed video

 @param videoURL The url of video
 @param videoSetting The setting user want to compress (resolution, framerate, bitrate,...)
 @param completionBlock The callback for handling the completion of the compression
 */
- (void)compressVideoURL:(NSURL *)videoURL
            compressSetting:(ZLVideoCompressSetting *)videoSetting
              completion:(void (^)(NSURL *compressURL, NSError *error))completionBlock;


/**
 Compress an image with 'ZLImagePackageCompressType'.

 @param imageURL The url of image
 @param compressType The type user want to compress image (680x420, 1280x720, 1920x1080,...)
 @param completionBlock The callback for handling the completion of the compression
 */
- (void)compressImageURL:(NSURL *)imageURL
           withScaleType:(ZLImagePackageCompressType)compressType
              completion:(void (^)(NSURL *compressURL, NSError *error))completionBlock;

@end

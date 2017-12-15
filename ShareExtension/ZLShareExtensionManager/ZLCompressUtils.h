//
//  ZLVideoCompressUtils.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZLShareDefine.h"
#import <AVKit/AVKit.h>

@interface ZLCompressUtils : NSObject

+ (void)compressVideoURL:(NSURL *)videoURL
            compressType:(ZLVideoPackageCompressType)compressType
              completion:(void (^)(NSData *videoData, NSError *error))completionBlock;

+ (void)compressImageURL:(NSURL *)imageURL
           withScaleType:(ZLImagePackageCompressType)compressType
              completion:(void (^)(NSData *imageData, NSError *error))completionBlock;

@end

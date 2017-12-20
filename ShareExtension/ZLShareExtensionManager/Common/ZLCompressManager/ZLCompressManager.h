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
 <#Description#>

 @param videoURL <#videoURL description#>
 @param compressType <#compressType description#>
 @param completionBlock <#completionBlock description#>
 */
- (void)compressVideoURL:(NSURL *)videoURL
            compressType:(ZLVideoPackageCompressType)compressType
              completion:(void (^)(NSURL *compressURL, NSError *error))completionBlock;


/**
 <#Description#>

 @param videoURL <#videoURL description#>
 @param videoSetting <#videoSetting description#>
 @param completionBlock <#completionBlock description#>
 */
- (void)compressVideoURL:(NSURL *)videoURL
            compressSetting:(ZLVideoCompressSetting *)videoSetting
              completion:(void (^)(NSURL *compressURL, NSError *error))completionBlock;


/**
 <#Description#>

 @param imageURL <#imageURL description#>
 @param compressType <#compressType description#>
 @param completionBlock <#completionBlock description#>
 */
- (void)compressImageURL:(NSURL *)imageURL
           withScaleType:(ZLImagePackageCompressType)compressType
              completion:(void (^)(NSURL *compressURL, NSError *error))completionBlock;

@end

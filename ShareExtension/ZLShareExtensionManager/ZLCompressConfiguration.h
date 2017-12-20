//
//  ZLShareConfiguration.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/19/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import "ZLShareDefine.h"

@interface ZLVideoCompressSetting: NSObject

@property(nonatomic) CGSize videoResolution;
@property(nonatomic) float videoFrameRate;
@property(nonatomic) float videoBitrate;
@property(nonatomic) AVVideoCodecType videoCodec;
@property(nonatomic) NSString *videoProfileLevel;
@property(nonatomic) AudioFormatID audioFormat;
@property(nonatomic) NSUInteger numberOfChannels;
@property(nonatomic) NSInteger audioSampleRate;
@property(nonatomic) NSInteger audioBitRate;

+ (instancetype)lowSetting;
+ (instancetype)mediumSetting;
+ (instancetype)highSetting;

@end





@interface ZLCompressConfiguration : NSObject
@property(strong, nonatomic) ZLVideoCompressSetting *videoSetting;
@property(nonatomic) ZLImagePackageCompressType imageCompress;

+ (instancetype)lowConfiguration;
+ (instancetype)mediumConfiguration;
+ (instancetype)highConfiguration;

@end



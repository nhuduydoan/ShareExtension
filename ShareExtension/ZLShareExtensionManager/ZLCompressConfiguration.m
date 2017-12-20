//
//  ZLShareConfiguration.m
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/19/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ZLCompressConfiguration.h"

@implementation ZLVideoCompressSetting

- (instancetype)init {
    if (self = [super init]) {
        _videoResolution = CGSizeZero;
        _videoFrameRate = 24;
        _videoBitrate = 600000;
        if (@available(iOS 11, *)) {
            _videoCodec = AVVideoCodecTypeH264;
        } else {
            _videoCodec = AVVideoCodecH264;
        }
        _videoProfileLevel = AVVideoProfileLevelH264Main30;
        
        _audioFormat = kAudioFormatMPEG4AAC;
        _numberOfChannels = 2;
        _audioSampleRate = 44100;
        _audioBitRate = 640000;
    }
    
    return self;
}

+ (instancetype)lowSetting {
    ZLVideoCompressSetting *instance = [[self alloc] init];
    if (instance) {
        instance.videoResolution = CGSizeMake(480, 320);
        instance.videoFrameRate = 15;
        instance.videoBitrate = 200000;

        instance.numberOfChannels = 1;
        instance.audioSampleRate = 22050;
        instance.audioBitRate = 32000;
    }
    
    return instance;
}

+ (instancetype)mediumSetting {
    ZLVideoCompressSetting *instance = [[self alloc] init];
    if (instance) {
        instance.videoResolution = CGSizeMake(620, 480);
        instance.videoFrameRate = 20;
        instance.videoBitrate = 400000;
        
        instance.numberOfChannels = 1;
        instance.audioSampleRate = 44100;
        instance.audioBitRate = 64000;
    }
    
    return instance;
}

+ (instancetype)highSetting {
    ZLVideoCompressSetting *instance = [[self alloc] init];
    if (instance) {
        instance.videoResolution = CGSizeMake(1280, 720);
        instance.videoFrameRate = 24;
        instance.videoBitrate = 600000;
        
        instance.numberOfChannels = 2;
        instance.audioSampleRate = 44100;
        instance.audioBitRate = 64000;
    }
    
    return instance;
}

@end

@implementation ZLCompressConfiguration

- (instancetype)init {
    if (self = [super init]) {
        _videoSetting = [ZLVideoCompressSetting new];
        _imageCompress = ZLImagePackageCompressTypeOrigin;
    }
    
    return self;
}

+ (instancetype)lowConfiguration {
    ZLCompressConfiguration *configuration = [[self alloc] init];
    if (configuration) {
        configuration.videoSetting = [ZLVideoCompressSetting lowSetting];
        configuration.imageCompress = ZLImagePackageCompressType480x320;
    }
    
    return configuration;
}

+ (instancetype)mediumConfiguration {
    ZLCompressConfiguration *configuration = [[self alloc] init];
    if (configuration) {
        configuration.videoSetting = [ZLVideoCompressSetting mediumSetting];
        configuration.imageCompress = ZLImagePackageCompressType640x480;
    }
    
    return configuration;
}

+ (instancetype)highConfiguration {
    ZLCompressConfiguration *configuration = [[self alloc] init];
    if (configuration) {
        configuration.videoSetting = [ZLVideoCompressSetting highSetting];
        configuration.imageCompress = ZLImagePackageCompressType1280x720;
    }
    
    return configuration;
}

@end

//
//  ZLAssetExportSession.m
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/19/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ZLAssetExportSession.h"

#define DefaultFrameRate                30
#define GetValidQueue(queue)            queue ? queue : dispatch_get_main_queue()

@interface ZLAssetExportSession()

@property(strong, nonatomic) AVAssetReader *reader;
@property(strong, nonatomic) AVAssetReaderVideoCompositionOutput *videoOutput;
@property(strong, nonatomic) AVAssetReaderAudioMixOutput *audioOutput;
@property(strong, nonatomic) AVAssetWriter *writer;
@property(strong, nonatomic) AVAssetWriterInput *videoInput;
@property(strong, nonatomic) AVAssetWriterInput *audioInput;
@property(strong, nonatomic) dispatch_queue_t inputQueue;
@property(strong, nonatomic) void(^progressCallback)(float progress);
@property(strong, nonatomic) void(^completionCallback)(NSError *error);
@property(strong, nonatomic) dispatch_queue_t callbackQueue;

@property(nonatomic)NSTimeInterval duration;

@end

@implementation ZLAssetExportSession

- (instancetype)init {
    if (self = [super init]) {
        _sessionId = [[NSUUID UUID] UUIDString];
    }
    
    return self;
}

- (id)initWithAsset:(AVAsset *)asset {
    if ((self = [self init]))
    {
        _asset = asset;
        _timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
    }
    
    return self;
}

- (void)exportAsynchronouslyWithProgressCallback:(void (^)(float))progressCallback
                               completionHandler:(void (^)(NSError *))handler
                                         inQueue:queue {
    if (!handler) {
        return;
    }
    
    _progressCallback = progressCallback;
    _completionCallback = handler;
    _callbackQueue = queue;
    
    [self cancelExport];
    
    if (!_outputURL)
    {
        NSError *error = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorExportFailed userInfo:@{@"message": @"Output URL not set"
                  }];
        handler(error);
        return;
    }
    
    NSError *readerError;
    _reader = [AVAssetReader.alloc initWithAsset:_asset error:&readerError];
    if (readerError)
    {
        handler(readerError);
        return;
    }
    
    NSError *writerError;
    _writer = [AVAssetWriter assetWriterWithURL:_outputURL fileType:_outputFileType error:&writerError];
    if (writerError)
    {
        handler(writerError);
        return;
    }
    
    _reader.timeRange = _timeRange;
    _writer.shouldOptimizeForNetworkUse = _shouldOptimizeForNetworkUse;
    _writer.metadata = _metadata;
    
    NSArray *videoTracks = [_asset tracksWithMediaType:AVMediaTypeVideo];
    
    
    if (CMTIME_IS_VALID(_timeRange.duration) && !CMTIME_IS_POSITIVE_INFINITY(_timeRange.duration))
    {
        _duration = CMTimeGetSeconds(_timeRange.duration);
    }
    else
    {
        _duration = CMTimeGetSeconds(_asset.duration);
    }
    //
    // Video output
    //
    if (videoTracks.count > 0) {
        _videoOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:videoTracks videoSettings:_videoInputSettings];
        _videoOutput.alwaysCopiesSampleData = NO;
        if (_videoComposition)
        {
            _videoOutput.videoComposition = _videoComposition;
        }
        else
        {
            _videoOutput.videoComposition = [self buildDefaultVideoComposition];
        }
        if ([_reader canAddOutput:_videoOutput])
        {
            [_reader addOutput:_videoOutput];
        }
        
        //
        // Video input
        //
        _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:_videoSettings];
        _videoInput.expectsMediaDataInRealTime = NO;
        if ([_writer canAddInput:_videoInput])
        {
            [_writer addInput:_videoInput];
        }
    }
    
    //
    //Audio output
    //
    NSArray *audioTracks = [_asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count > 0) {
        _audioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:nil];
        _audioOutput.alwaysCopiesSampleData = NO;
        _audioOutput.audioMix = _audioMix;
        if ([_reader canAddOutput:_audioOutput])
        {
            [_reader addOutput:_audioOutput];
        }
    } else {
        // Just in case this gets reused
        _audioOutput = nil;
    }
    
    //
    // Audio input
    //
    if (_audioOutput) {
        _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:_audioSettings];
        _audioInput.expectsMediaDataInRealTime = NO;
        if ([_writer canAddInput:_audioInput])
        {
            [_writer addInput:_audioInput];
        }
    }
    
    NSLog(@"[HM] ZLAssetExportSession - Start writer & reader");
    [_writer startWriting];
    [_reader startReading];
    [_writer startSessionAtSourceTime:_timeRange.start];
    
    __block BOOL videoCompleted = NO;
    __block BOOL audioCompleted = NO;
    __weak __typeof(self) weakSelf = self;
    _inputQueue = dispatch_queue_create("VideoEncoderInputQueue", DISPATCH_QUEUE_SERIAL);
    if (videoTracks.count > 0) {
        NSLog(@"[HM] ZLAssetExportSession - Start encode video");
        [_videoInput requestMediaDataWhenReadyOnQueue:_inputQueue usingBlock:^
         {
             
             if (![weakSelf encodeReadySamplesFromOutput:weakSelf.videoOutput toInput:weakSelf.videoInput])
             {
                 @synchronized(weakSelf)
                 {
                     NSLog(@"[HM] ZLAssetExportSession - Complete encode video");
                     videoCompleted = YES;
                     if (audioCompleted)
                     {
                         NSLog(@"[HM] ZLAssetExportSession - Complete encode");
                         [weakSelf finish];
                     }
                 }
             }
         }];
    }
    else {
        videoCompleted = YES;
    }
    
    if (!_audioOutput) {
        audioCompleted = YES;
    } else {
        NSLog(@"[HM] ZLAssetExportSession - Start encode audio");
        [_audioInput requestMediaDataWhenReadyOnQueue:_inputQueue usingBlock:^
         {
             if (![weakSelf encodeReadySamplesFromOutput:weakSelf.audioOutput toInput:weakSelf.audioInput])
             {
                 @synchronized(weakSelf)
                 {
                     NSLog(@"[HM] ZLAssetExportSession - Complete encode audio");
                     audioCompleted = YES;
                     if (videoCompleted)
                     {
                         NSLog(@"[HM] ZLAssetExportSession - Complete encode");
                         [weakSelf finish];
                     }
                 }
             }
         }];
    }
}

- (BOOL)encodeReadySamplesFromOutput:(AVAssetReaderOutput *)output toInput:(AVAssetWriterInput *)input {
    while (input.isReadyForMoreMediaData)
    {
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
        if (sampleBuffer)
        {
            BOOL error = NO;
            
            if (_reader.status != AVAssetReaderStatusReading || _writer.status != AVAssetWriterStatusWriting)
            {
                error = YES;
            }
            
            if (_videoOutput == output)
            {
                //Update video progress
                CMTime lastSamplePresentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                lastSamplePresentationTime = CMTimeSubtract(lastSamplePresentationTime, _timeRange.start);
                _progress = _duration == 0 ? 1 : CMTimeGetSeconds(lastSamplePresentationTime) / _duration;
                if (_progressCallback) {
                    dispatch_async(GetValidQueue(_callbackQueue), ^{
                        _progressCallback(_progress);
                    });
                }
            }
            if (![input appendSampleBuffer:sampleBuffer])
            {
                error = YES;
            }
            CFRelease(sampleBuffer);
            
            if (error)
            {
                return NO;
            }
        }
        else
        {
            [input markAsFinished];
            return NO;
        }
    }
    
    return YES;
}

- (AVMutableVideoComposition *)buildDefaultVideoComposition {
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    AVAssetTrack *videoTrack = [[_asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    //Get the frame rate from videoSettings, if not set then try to get it from the video track,
    //If not set (mainly when asset is AVComposition) then use the default frame rate of 30
    float trackFrameRate = 0;
    if (_videoSettings)
    {
        NSDictionary *videoCompressionProperties = [_videoSettings objectForKey:AVVideoCompressionPropertiesKey];
        if (videoCompressionProperties)
        {
            NSNumber *frameRate = [videoCompressionProperties objectForKey:AVVideoAverageNonDroppableFrameRateKey];
            if (frameRate)
            {
                trackFrameRate = frameRate.floatValue;
            }
        }
    }
    else
    {
        trackFrameRate = [videoTrack nominalFrameRate];
    }
    
    if (trackFrameRate == 0)
    {
        trackFrameRate = DefaultFrameRate;
    }
    
    videoComposition.frameDuration = CMTimeMake(1, trackFrameRate);
    CGSize targetSize = CGSizeMake([_videoSettings[AVVideoWidthKey] floatValue], [_videoSettings[AVVideoHeightKey] floatValue]);
    CGSize naturalSize = [videoTrack naturalSize];
    CGAffineTransform transform = videoTrack.preferredTransform;
    if (transform.ty == -560) {
        transform.ty = 0;
    }
    
    if (transform.tx == -560) {
        transform.tx = 0;
    }
    
    CGFloat videoAngleInDegree  = atan2(transform.b, transform.a) * 180 / M_PI;
    if (videoAngleInDegree == 90 || videoAngleInDegree == -90) {
        CGFloat width = naturalSize.width;
        naturalSize.width = naturalSize.height;
        naturalSize.height = width;
    }
    videoComposition.renderSize = naturalSize;
    //Center inside
    {
        float ratio;
        float xratio = targetSize.width / naturalSize.width;
        float yratio = targetSize.height / naturalSize.height;
        ratio = MIN(xratio, yratio);
        
        float postWidth = naturalSize.width * ratio;
        float postHeight = naturalSize.height * ratio;
        float transx = (targetSize.width - postWidth) / 2;
        float transy = (targetSize.height - postHeight) / 2;
        
        CGAffineTransform matrix = CGAffineTransformMakeTranslation(transx / xratio, transy / yratio);
        matrix = CGAffineTransformScale(matrix, ratio / xratio, ratio / yratio);
        transform = CGAffineTransformConcat(transform, matrix);
    }
    
    //Make a "pass through video track" video composition.
    AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, _asset.duration);
    
    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    [passThroughLayer setTransform:transform atTime:kCMTimeZero];
    
    passThroughInstruction.layerInstructions = @[passThroughLayer];
    videoComposition.instructions = @[passThroughInstruction];
    
    return videoComposition;
}

- (void)finish {
    // Synchronized block to ensure we never cancel the writer before calling finishWritingWithCompletionHandler
    if (_reader.status == AVAssetReaderStatusCancelled || _writer.status == AVAssetWriterStatusCancelled)
    {
        NSLog(@"[HM] ZLAssetExportSession - Reader or Writer cancelled");
        return;
    }
    
    if (_writer.status == AVAssetWriterStatusFailed)
    {
        NSLog(@"[HM] ZLAssetExportSession - Error: Writer failed");
        [self complete];
    }
    else if (_reader.status == AVAssetReaderStatusFailed) {
        NSLog(@"[HM] ZLAssetExportSession - Error: Reader failed");
        [_writer cancelWriting];
        [self complete];
    }
    else
    {
        [_writer finishWritingWithCompletionHandler:^
         {
             NSLog(@"[HM] ZLAssetExportSession - Handler completion");
             [self complete];
         }];
    }
}

- (void)complete {
    if (_writer.status == AVAssetWriterStatusFailed || _writer.status == AVAssetWriterStatusCancelled)
    {
        [NSFileManager.defaultManager removeItemAtURL:_outputURL error:nil];
    }
    
    if (_completionCallback)
    {
        dispatch_async(GetValidQueue(_callbackQueue), ^{
            _completionCallback([self error]);
        });
    }
}

- (NSError *)error {
    return _writer.error ? : _reader.error;
}

- (AVAssetExportSessionStatus)status
{
    switch (_writer.status)
    {
        default:
        case AVAssetWriterStatusUnknown:
            return AVAssetExportSessionStatusUnknown;
        case AVAssetWriterStatusWriting:
            return AVAssetExportSessionStatusExporting;
        case AVAssetWriterStatusFailed:
            return AVAssetExportSessionStatusFailed;
        case AVAssetWriterStatusCompleted:
            return AVAssetExportSessionStatusCompleted;
        case AVAssetWriterStatusCancelled:
            return AVAssetExportSessionStatusCancelled;
    }
}


- (void)cancelExport {
    if (_inputQueue)
    {
        dispatch_async(_inputQueue, ^ {
            [_writer cancelWriting];
            [_reader cancelReading];
            [self complete];
            [self reset];
        });
    }
}

- (void)reset {
    _progress = 0;
    _reader = nil;
    _videoOutput = nil;
    _audioOutput = nil;
    _writer = nil;
    _videoInput = nil;
    _audioInput = nil;
    _inputQueue = nil;
    _completionCallback = nil;
    _progressCallback = nil;
    _callbackQueue = nil;
}

@end

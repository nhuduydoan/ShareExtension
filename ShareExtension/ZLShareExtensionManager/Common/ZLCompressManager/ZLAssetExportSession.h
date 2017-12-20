//
//  ZLAssetExportSession.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/19/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

@class ZLAssetExportSession;

@interface ZLAssetExportSession : NSObject
@property(strong, nonatomic, readonly) NSString *sessionId;
@property(nonatomic, strong, readonly) AVAsset *asset;
@property(nonatomic, copy) AVVideoComposition *videoComposition;
@property(nonatomic, copy) AVAudioMix *audioMix;
@property(nonatomic, copy) NSString *outputFileType;
@property(nonatomic, copy) NSURL *outputURL;
@property(nonatomic, copy) NSDictionary *videoInputSettings;
@property(nonatomic, copy) NSDictionary *videoSettings;
@property(nonatomic, copy) NSDictionary *audioSettings;
@property(nonatomic) CMTimeRange timeRange;
@property(nonatomic) BOOL shouldOptimizeForNetworkUse;
@property(nonatomic, copy) NSArray *metadata;
@property(strong, nonatomic, readonly) NSError *error;
@property(nonatomic, readonly) float progress;
@property(nonatomic, readonly) AVAssetExportSessionStatus status;


/**
 Initialize an instance with asset. The asset will be use for getting some components which are useful for compressing the video

 @param asset Need to get some components which are useful for compressing the video
 @return The instance of this class
 */
- (id)initWithAsset:(AVAsset *)asset;


/**
 Export a compressed video asynchronously in a queue user want to get result

 @param progressCallback The callback for handling the progress of compression
 @param handler The callback for handling the completion of compression
 @param queue The queue user want to get result
 */
- (void)exportAsynchronouslyWithProgressCallback:(void(^)(float progress))progressCallback
                               completionHandler:(void (^)(NSError *error))handler
                                         inQueue:(dispatch_queue_t)queue;


/**
 Cancel the current export task
 */
- (void)cancelExport;

@end

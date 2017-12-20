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
@property(nonatomic, strong, readonly) NSError *error;
@property(nonatomic, readonly) float progress;
@property(nonatomic, readonly) AVAssetExportSessionStatus status;


/**
 <#Description#>

 @param asset <#asset description#>
 @return <#return value description#>
 */
- (id)initWithAsset:(AVAsset *)asset;


/**
 <#Description#>

 @param progressCallback <#progressCallback description#>
 @param handler <#handler description#>
 @param queue <#queue description#>
 */
- (void)exportAsynchronouslyWithProgressCallback:(void(^)(float progress))progressCallback
                               completionHandler:(void (^)(NSError *error))handler
                                         inQueue:(dispatch_queue_t)queue;


/**
 <#Description#>
 */
- (void)cancelExport;

@end

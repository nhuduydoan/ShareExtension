//
//  ZLShareExtensionManager_Image.m
//  ShareExtension
//
//  Created by Nhữ Duy Đoàn on 12/19/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "ZLShareExtensionManager_Image.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "DXImageManager.h"

@implementation ZLShareExtensionManager (Image)

- (void)getShareThumbnailWithCompletionHandler:(void (^)(UIImage *image))completionHandler {
    [self getExtensionThumbnailsWithCompletedBlock:completionHandler];
}

#pragma mark - Private

- (void)getExtensionThumbnailsWithCompletedBlock:(void (^)(UIImage *image))completedBlock {
    __block NSString *videoString;
    NSMutableArray *thumbnailsArr = [NSMutableArray new];
    dispatch_group_t group = dispatch_group_create();
    
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            for (NSString *identifier in [itemProvider registeredTypeIdentifiers]) {
                //kUTTypeVCard, kUTTypeURL, kUTTypeImage, kUTTypeQuickTimeMovie
                if (![itemProvider hasItemConformingToTypeIdentifier:identifier]) {
                    continue;
                }
                
                dispatch_group_enter(group);
                [itemProvider loadPreviewImageWithOptions:nil completionHandler:^(UIImage *image, NSError *error) {
                    if (image) {
                        [thumbnailsArr addObject:image];
                    }
                    dispatch_group_leave(group);
                }];
                
                if (videoString || ![identifier isEqualToString:(__bridge NSString *)kUTTypeMovie]) {
                    continue;
                }
                videoString = @"";
                dispatch_group_enter(group);
                __weak typeof(self) selfWeak = self;
                [itemProvider loadItemForTypeIdentifier:identifier options:nil completionHandler:^(NSURL *url, NSError *error) {
                    if (url) {
                        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                        CMTime duration = sourceAsset.duration;
                        videoString = [selfWeak transformedTime:duration];
                    }
                    dispatch_group_leave(group);
                }];
                
                continue;
            }
        }
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [sImageManager drawThumbnailFromImages:thumbnailsArr videoString:videoString];
        if (completedBlock) {
            completedBlock(image);
        }
    });
}

- (NSString *)transformedTime:(CMTime)tỉme {
    float duration = (float)tỉme.value/(float)tỉme.timescale;
    int seconds = floor(duration + 0.6);
    NSString *hoursStr = @"";
    NSString *munitesStr = @"00";
    NSString *secondsStr = @"";
    if (seconds >= 3600) {
        int hours = seconds/3600;
        seconds = seconds - hours*3600;
        hoursStr = [NSString stringWithFormat:@"%d:", hours];
    }
    if (seconds > 60) {
        int munites = seconds/60;
        seconds = seconds - munites *60;
        if (munites >= 10) {
            munitesStr = [NSString stringWithFormat:@"%d:", munites];
        } else {
            munitesStr = [NSString stringWithFormat:@"0%d:", munites];
        }
    }
    if (seconds >= 10) {
        secondsStr = [NSString stringWithFormat:@"%d:", seconds];
    } else {
        secondsStr = [NSString stringWithFormat:@"0%d", seconds];
    }
    NSString *timeString = [NSString stringWithFormat:@"%@%@:%@", hoursStr, munitesStr, secondsStr];
    return timeString;
}


@end

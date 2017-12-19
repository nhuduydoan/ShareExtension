//
//  ShareRootViewController.m
//  ShareExtension
//
//  Created by Nhữ Duy Đoàn on 12/14/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "ShareRootViewController.h"
#import "ZLPickConversationViewController.h"
#import "ZLShareExtensionManager.h"
#import "ZLUpLoadingViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "DXImageManager.h"

@interface ShareRootViewController ()

@property (strong, nonatomic) NSMutableArray *uploadInfoArray;
@property (strong, nonatomic) ZLPickConversationViewController *conversationController;

@end

@implementation ShareRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sShareExtensionManager.extensionContext = self.extensionContext;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self) selfWeak = self;
    ZLPickConversationViewController *controller = [[ZLPickConversationViewController alloc] initWithCompletionHandler:^(UIViewController *viewController, NSArray<NSString *> *shareURLs, NSString *comment) {
        if (shareURLs.count > 0) {
            [selfWeak runOnMainThread:^{
                [selfWeak shareToURLs:shareURLs onViewController:viewController];
            }];
        } else {
            [sShareExtensionManager completeExtension];
        }
    }];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:nil];
    self.conversationController = controller;
    [self getExtensionThumbnails];
}

- (void)getExtensionThumbnails {
    
    __block NSString *videoString;
    NSMutableArray *thumbnailsArr = [NSMutableArray new];
    dispatch_group_t group = dispatch_group_create();
    __weak typeof(self) selfWeak = self;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            //kUTTypeVCard, kUTTypeURL, kUTTypeImage, kUTTypeQuickTimeMovie
            NSArray *identifiers = [itemProvider registeredTypeIdentifiers];
            for (NSString *identifier in identifiers) {
                if ([itemProvider hasItemConformingToTypeIdentifier:identifier]) {
                    if (videoString == nil) {
                        videoString = @"";
                        if ([identifier isEqualToString:(__bridge NSString *)kUTTypeQuickTimeMovie]) {
                            dispatch_group_enter(group);
                            [itemProvider loadItemForTypeIdentifier:identifier options:nil completionHandler:^(NSURL *url, NSError *error) {
                                if (url) {
                                    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                                    CMTime duration = sourceAsset.duration;
                                    videoString = [selfWeak transformedTime:duration];
                                }
                                dispatch_group_leave(group);
                            }];
                        }
                    }
                    
                    dispatch_group_enter(group);
                    [itemProvider loadPreviewImageWithOptions:nil completionHandler:^(UIImage *image, NSError *error) {
                        if (image) {
                            [thumbnailsArr addObject:image];
                        }
                        dispatch_group_leave(group);
                    }];
                    continue;
                }
            }
        }
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self updateThumbnailFromThumbnailsArray:thumbnailsArr videoString:videoString];
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

- (void)updateThumbnailFromThumbnailsArray:(NSArray *)thumbnailArr videoString:(NSString *)videoString {
    UIImage *image = [sImageManager drawThumbnailFromImages:thumbnailArr videoString:videoString];
    [self.conversationController updateExtensionThumbnail:image];
}

- (void)shareToURLs:(NSArray *)shareURLs onViewController:(UIViewController *)viewController {
    ZLUpLoadingViewController *loadingVC = [ZLUpLoadingViewController new];
    [self displayLoadingViewController:loadingVC onViewController:viewController];
    
    dispatch_group_t completionGroup = dispatch_group_create();
    self.uploadInfoArray = [NSMutableArray new];
    __weak typeof(loadingVC) weakLoadingVC = loadingVC;
    __weak typeof(self) selfWeak = self;
    
    NSString *uploadURL = @"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung";
    shareURLs = @[uploadURL];
    for (NSString *url in shareURLs) {
        dispatch_group_enter(completionGroup);
        [sShareExtensionManager uploadAllSharePackagesToURLString:url configuration:nil progressHandler:^(float progress) {
            CGFloat allPropress = progress/shareURLs.count;
            [weakLoadingVC updateProgress:allPropress];
            NSLog(@"Loading: %f : %f", progress, allPropress);
        } completionHandler:^(NSDictionary *uploadInfo) {
            [selfWeak addUploadInfo:uploadInfo];
            dispatch_group_leave(completionGroup);
        } inQueue:nil];
    }
    
    dispatch_group_notify(completionGroup, dispatch_get_main_queue(), ^{
        NSLog(@"Up load file xong roi!");
        [sShareExtensionManager completeExtension];
    });
}

- (void)displayLoadingViewController:(UIViewController *)loadingViewController onViewController:(UIViewController *)viewController {
    [viewController addChildViewController:loadingViewController];
    [loadingViewController didMoveToParentViewController:viewController];
    loadingViewController.view.frame = viewController.view.bounds;
    loadingViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [viewController.view addSubview:loadingViewController.view];
}

- (void)runOnMainThread:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

- (void)addUploadInfo:(NSDictionary *)uploadInfo {
    @synchronized(self) {
        [self.uploadInfoArray addObject:uploadInfo];
    }
}

@end

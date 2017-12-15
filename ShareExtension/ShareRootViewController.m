//
//  ShareRootViewController.m
//  ShareExtension
//
//  Created by Nhữ Duy Đoàn on 12/14/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "ShareRootViewController.h"
#import "ZLPickConversationViewController.h"
#import "DXShareNavigationController.h"
#import "ZLShareExtensionManager.h"
#import "ZLUpLoadingViewController.h"

@interface ShareRootViewController ()

@property (strong, nonatomic) NSMutableArray *uploadInfoArray;

@end

@implementation ShareRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sShareExtensionManager.extensionContext = self.extensionContext;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self) selfWeak = self;
    ZLPickConversationViewController *controller = [[ZLPickConversationViewController alloc] initWithCompletionHandler:^(UIViewController *viewController, NSArray<NSString *> *shareURLs) {
        if (shareURLs.count > 0) {
            [selfWeak runOnMainThread:^{
                [selfWeak shareToURLs:shareURLs onViewController:viewController];
            }];
        } else {
            [sShareExtensionManager completeExtension];
        }
    }];
    //NSArray<NSString *> *selectedURLs
    DXShareNavigationController *navController = [[DXShareNavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:nil];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
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
        [sShareExtensionManager uploadAllSharePackageToURLString:url withConfiguration:nil progressHandler:^(float progress) {
            CGFloat allPropress = progress/shareURLs.count;
            [weakLoadingVC updateProgress:allPropress];
            NSLog(@"Loading: %f : %f", progress, allPropress);
        } completionHandler:^(NSDictionary *uploadInfo) {
            [selfWeak addUploadInfo:uploadInfo];
            dispatch_group_leave(completionGroup);
        } inQueue:dispatch_get_main_queue()];
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

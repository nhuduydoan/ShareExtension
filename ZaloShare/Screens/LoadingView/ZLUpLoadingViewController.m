//
//  ZLUpLoadingViewController.m
//  ZaloShare
//
//  Created by Nhữ Duy Đoàn on 12/15/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "ZLUpLoadingViewController.h"

@interface ZLUpLoadingViewController ()

@property (strong, nonatomic) UIProgressView *progressView;

@end

@implementation ZLUpLoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupNavigationItems];
    [self setupViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupViews {
    
    CGRect bounds = self.view.bounds;
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(bounds.size.width/4, bounds.size.height/3, bounds.size.width/2, 3)];
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.progressView.progress = 0.0;
    [self.view addSubview:self.progressView];
    self.progressView.tintColor = [UIColor colorWithRed:32/255.f green:148/255.f blue:241/255.f alpha:1];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
}

- (void)setupNavigationItems {
    self.title = @"Chia sẻ";
    UIBarButtonItem *closeBarItem = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Huỷ"
                                     style:UIBarButtonItemStylePlain
                                     target:self action:@selector(touchUpCloseBarButtonItem)];
    self.navigationItem.leftBarButtonItem = closeBarItem;
    self.navigationController.navigationBar.translucent = NO;
}

- (void)touchUpCloseBarButtonItem {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.parentViewController) {
        [self removeFromParentViewController];
        [self didMoveToParentViewController:nil];
        [self.view removeFromSuperview];
    }
}

#pragma mark - Public

- (void)updateProgress:(CGFloat)progress {
    if (progress < 0 || progress > 1) {
        return;
    }
    if ([NSThread isMainThread]) {
        self.progressView.progress = progress;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
        });
    }
}

@end

//
//  DXShareNavigationController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXShareNavigationController.h"

@interface DXShareNavigationController ()

@end

@implementation DXShareNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupViews {
    UIColor *barBackgroundColor = [UIColor colorWithRed:0/255.f green:144/255.f blue:243/255.f alpha:1];
    UIColor *tintColor = [UIColor whiteColor];
    UIImage *barBackgroundImage = [self imageWithColor:barBackgroundColor];
    [self.navigationBar setBackgroundImage:barBackgroundImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    self.view.backgroundColor = barBackgroundColor;
    self.navigationBar.barTintColor = barBackgroundColor;
    self.navigationBar.tintColor = tintColor;
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)setupViews {
    UIColor *barBackgroundColor = [UIColor colorWithRed:242/255.f green:242/255.f blue:242/255.f alpha:1];
    UIColor *tintColor = [UIColor colorWithRed:54/255.f green:59/255.f blue:66/255.f alpha:1];
    UIColor *titleColor = [UIColor blackColor];
    UIImage *barBackgroundImage = [self imageWithColor:barBackgroundColor];
    [self.navigationBar setBackgroundImage:barBackgroundImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    self.view.backgroundColor = barBackgroundColor;
    self.navigationBar.barTintColor = barBackgroundColor;
    self.navigationBar.tintColor = tintColor;
    NSDictionary *titleAttribute = @{NSFontAttributeName:[UIFont systemFontOfSize:17 weight:UIFontWeightRegular],
                                      NSForegroundColorAttributeName:titleColor};
    [self.navigationBar setTitleTextAttributes:titleAttribute];
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

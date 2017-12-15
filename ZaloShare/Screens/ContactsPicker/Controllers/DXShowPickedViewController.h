//
//  DXShowPickedViewController.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/23/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DXShowPickedViewController;

@protocol DXShowPickedViewControllerDelegate <NSObject>

@optional
- (void)showPickedViewController:(DXShowPickedViewController *)controller didSelectModel:(id)model;

@end

@interface DXShowPickedViewController : UIViewController

@property (weak, nonatomic) id<DXShowPickedViewControllerDelegate> delegate;

- (NSArray *)pickedModels;

- (BOOL)isPickedModel:(id)model;

- (void)addPickedModel:(id)model;

- (void)removePickedModel:(id)model;

@end

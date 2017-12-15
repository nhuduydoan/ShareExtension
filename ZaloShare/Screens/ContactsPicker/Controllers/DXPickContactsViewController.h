//
//  DXPickContactsViewController.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/22/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DXPickContactsViewControllerDelegate <NSObject>

@required
- (BOOL)pickContactsViewController:(UIViewController *)controller isSelectedModel:(id)model;
- (BOOL)pickContactsViewController:(UIViewController *)controller didSelectModel:(id)model;
- (void)pickContactsViewController:(UIViewController *)controller didDeSelectModel:(id)model;

@optional
- (void)didTapOnPickContactsViewController:(UIViewController *)controller;

@end

@interface DXPickContactsViewController : UITableViewController

@property (weak, nonatomic) id<DXPickContactsViewControllerDelegate> delegate;

- (void)reloadWithData:(NSArray *)data;

- (void)didSelectModel:(id)model;

- (void)deSelectModel:(id)model;

- (void)scrollToContactModel:(id)model;

@end

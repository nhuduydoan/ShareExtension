//
//  DXResultSearchViewController.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/24/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DXPickContactsViewController.h"

@interface DXResultSearchViewController : UITableViewController

@property (weak, nonatomic) id<DXPickContactsViewControllerDelegate> delegate;

- (void)reloadWithData:(NSArray *)data;

- (void)didSelectModel:(id)model;

- (void)deSelectModel:(id)model;

- (void)scrollToContactModel:(id)model;

@end

//
//  DXShareSearchResultViewController.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DXShareSearchResultViewController, DXConversationModel;

@protocol DXShareSearchResultViewControllerDelegate <NSObject>

@optional
- (void)shareSearchResultViewController:(UIViewController *)viewController didSelectModel:(id)model;
- (void)shareSearchResultViewControllerWillBeginDragging:(UIViewController *)viewController;

@end

@interface DXShareSearchResultViewController : UITableViewController

@property (weak, nonatomic) id<DXShareSearchResultViewControllerDelegate> delegate;

- (void)reloadWithData:(NSArray<DXConversationModel *> *)data;

@end

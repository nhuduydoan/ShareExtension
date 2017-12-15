//
//  DXConversationSearchResultViewController.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DXConversationSearchResultViewController, DXConversationModel;

@protocol DXConversationSearchResultViewControllerDelegate <NSObject>

@optional
- (void)shareSearchResultViewController:(UIViewController *)viewController didSelectModel:(id)model;
- (void)shareSearchResultViewControllerWillBeginDragging:(UIViewController *)viewController;

@end

@interface DXConversationSearchResultViewController : UITableViewController

@property (weak, nonatomic) id<DXConversationSearchResultViewControllerDelegate> delegate;

- (void)reloadWithData:(NSArray<DXConversationModel *> *)data;

@end

//
//  EditPostViewController.h
//  ZaloShare
//
//  Created by Nhữ Duy Đoàn on 12/18/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EditPostViewController;

@protocol EditPostViewControllerDelegate <NSObject>

@optional
- (void)editPostViewController:(UIViewController *)viewController changeEditing:(BOOL)isEditing;
@end

@interface EditPostViewController : UIViewController

@property (weak, nonatomic) id<EditPostViewControllerDelegate> delegate;

- (void)updateExtensionThumbnails:(NSArray *)thumbnailArrs;
- (void)hideKeyBoard;
- (NSString *)postComment;
- (BOOL)isEditingText;

@end

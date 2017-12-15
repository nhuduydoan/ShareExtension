//
//  DXConversationTableViewCell.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DXConversationModel;

@interface DXConversationTableViewCell : UITableViewCell

- (void)displayConversation:(DXConversationModel *)model;
- (void)displayString:(NSString *)string image:(UIImage *)image;

@end

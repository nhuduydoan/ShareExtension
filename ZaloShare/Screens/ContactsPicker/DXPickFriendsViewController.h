//
//  DXPickFriendsViewController.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/23/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DXPickFriendsViewController : UIViewController

@property (nonatomic, copy) void (^completionHandler)(UIViewController *viewController, NSArray<NSString *> *shareURLs);

- (id)initWithContactsArray:(NSArray *)contactsArray;

@end

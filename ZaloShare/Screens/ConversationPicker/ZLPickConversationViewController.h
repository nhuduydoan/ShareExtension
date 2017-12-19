//
//  ZLPickConversationViewController.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZLPickConversationViewController : UIViewController

@property (nonatomic, copy) void (^completionHandler)(UIViewController *viewController, NSArray<NSString *> *selectedURLs, NSString *comment);

/**
 Init with NON NULL completion handler block

 @param completionHandler : NON NULL block
 @return : null able instance of this class
 */
- (instancetype)initWithCompletionHandler:(void (^)(UIViewController *viewController, NSArray<NSString *> *shareURLs, NSString *comment))completionHandler shareText:(NSString *)shareText;

// Use function -initWithCompletionHandler: instead this function
- (instancetype)init NS_UNAVAILABLE;

// use function +alloc with -initWithCompletionHandler: instead this function
+ (instancetype)new NS_UNAVAILABLE;

- (void)updateExtensionThumbnail:(UIImage *)thumbnail;

@end

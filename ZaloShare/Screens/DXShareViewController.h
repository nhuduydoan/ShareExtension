//
//  DXShareViewController.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DXShareViewController : UIViewController

@property (nonatomic, copy) void (^completionHandler)(void);

/**
 Init with NON NULL completion handler block

 @param completionHandler : NON NULL block
 @return : null able instance of this class
 */
- (instancetype)initWithCompletionHandler:(void (^)(void))completionHandler;

// Use function -initWithCompletionHandler: instead this function
- (instancetype)init NS_UNAVAILABLE;

// use function +alloc with -initWithCompletionHandler: instead this function
+ (instancetype)new NS_UNAVAILABLE;

@end

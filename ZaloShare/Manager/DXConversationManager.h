//
//  DXConversationManager.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXConversationModel;

@interface DXConversationManager : NSObject

/**
 Alloc and init and manager Object for using
 Please use this function to create new object
 
 @return : nil able
 */
+ (instancetype)shareInstance;

/**
 This function is unavaiable
 Please use +shareInstance instead
 
 @return : alway nil
 */
- (id)init NS_UNAVAILABLE;

- (void)getAllConversationsWithCompletionHandler:(void (^)(NSArray<DXConversationModel *> *result, NSError *error))completionHandler;

- (NSArray *)getContactsArray;

@end

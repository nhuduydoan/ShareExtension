//
//  DXConversationModel.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DXContactModel.h"

typedef NS_ENUM(NSUInteger, DXConversationType) {
    DXConversationTypeGroup,
    DXConversationTypeFriend
};

@interface DXConversationModel : NSObject

@property (strong, nonatomic, readonly) NSString *conversationId;
@property (strong, nonatomic, readonly) NSString *displayName;
@property (strong, nonatomic, readonly) NSArray<UIImage *> *avatars;
@property (nonatomic, readonly) DXConversationType type;
@property (strong, nonatomic, readonly) NSArray *members;
@property (strong, nonatomic, readonly) DXContactModel *contact;

- (id)initWithId:(NSString *)conversationId name:(NSString *)name members:(NSArray *)members avatar:(UIImage *)avatar;
- (id)initWithFriend:(DXContactModel *)contact;
- (void)updateAvatars:(NSArray *)images;

@end

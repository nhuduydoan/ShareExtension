//
//  DXConversationModel.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXConversationModel.h"

@interface DXConversationModel ()

@property (strong, nonatomic, readwrite) NSString *conversationId;
@property (strong, nonatomic, readwrite) NSString *displayName;
@property (strong, nonatomic, readwrite) NSArray<UIImage *> *avatars;
@property (nonatomic, readwrite) DXConversationType type;
@property (strong, nonatomic, readwrite) NSArray *members;
@property (strong, nonatomic, readwrite) DXContactModel *contact;

@end

@implementation DXConversationModel

- (id)initWithId:(NSString *)conversationId name:(NSString *)name members:(NSArray *)members avatar:(UIImage *)avatar {
    self = [super init];
    if (self) {
        _type = DXConversationTypeGroup;
        _conversationId = conversationId.copy;
        _displayName = name.copy;
        _members = members.copy;
    }
    return self;
}

- (id)initWithFriend:(DXContactModel *)contact {
    self = [super init];
    if (self) {
        _type = DXConversationTypeFriend;
        _conversationId = contact.identifier.copy;
        _displayName = contact.fullName.copy;
        _contact = contact;
    }
    return self;
}

- (void)updateAvatars:(NSArray *)images {
    _avatars = images.copy;
}

@end

//
//  DXConversationManager.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXConversationManager.h"
#import "DXConversationModel.h"

@interface DXConversationManager ()

@property (strong, nonatomic) NSArray *conversations;
@property (strong, nonatomic) NSArray *contactsArray;

@end

@implementation DXConversationManager

+ (instancetype)shareInstance {
    static id _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] initSharedInstance];
    });
    return _instance;
}

- (instancetype) init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

- (id)initSharedInstance {
    self = [super init];
    if (self) {
        _conversations = [self exampleConversations];
    }
    return self;
}

- (NSArray *)exampleFriendsArray {
    NSArray *names = @[@"Anh Mạnh", @"Bác Lăng", @"Bé Duyên", @"Bé Trâm", @"Cô Bắc", @"Dũng mập", @"Duy", @"Hu go", @"Long HD", @"VNG Anh Hoàng", @"VNG Anh Thêm", @"VNG Hưng", @"VNG Tú"];
    NSMutableArray *friendsArr = [NSMutableArray new];
    for (NSInteger i = 0; i < names.count; i++) {
        NSString *friendId = [NSString stringWithFormat:@"friendid_00%zd", i];
        NSString *friendName = names[i];
        DXContactModel *model = [[DXContactModel alloc] initWithIdentifier:friendId fullName:friendName birthDay:nil phones:nil emails:nil addressArray:nil avatar:nil];
        [friendsArr addObject:model];
    }
    return friendsArr;
}

- (NSArray *)exampleConversations {
    self.contactsArray = [self exampleFriendsArray];
    NSArray *friendsArr = [self exampleFriendsArray];
    NSArray *names = @[@"Group Ăn chơi", @"Ngắm gái Zalo", @"Probaby", @"Group tạo bug IOS", @"Zalo Product FC", @"Ăn nhậu cuối tuần", @"Cafe đèn sáng", @"Yêu đi đừng sợ", @"Code dạo mua sữa"];
    NSMutableArray *convaersationsArr = [NSMutableArray new];
    
    for (NSInteger i = 0; i < names.count; i++) {
        NSString *groupId = [NSString stringWithFormat:@"groupid_00%zd", i];
        NSString *groupName = names[i];
        NSArray *memebers = [self randomMemeberFromFriends:friendsArr];
        DXConversationModel *model = [[DXConversationModel alloc] initWithId:groupId name:groupName members:memebers avatar:nil];
        [convaersationsArr addObject:model];
    }
    
    for (DXContactModel *friend in friendsArr) {
        DXConversationModel *model = [[DXConversationModel alloc] initWithFriend:friend];
        [convaersationsArr addObject:model];
    }
    
    return convaersationsArr;
}

-(NSArray *)randomMemeberFromFriends:(NSArray *)friends {
    int count =  rand()%4;
    count += 3;
    if (friends.count <= count) {
        return friends.copy;
    }
    
    NSMutableArray *memebers = [NSMutableArray new];
    for (NSInteger i = 0; i < count; i ++) {
        int pos = rand() % count;
        [memebers addObject:friends[pos]];
    }
    return memebers;
        
}

#pragma mark - Public

- (void)getAllConversationsWithCompletionHandler:(void (^)(NSArray<DXConversationModel *> *result, NSError *error))completionHandler {
    if (completionHandler) {
        completionHandler(self.conversations.copy, nil);
    }
}

- (NSArray *)getContactsArray {
    return self.contactsArray.copy;
}

@end

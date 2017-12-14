//
//  DXContactModel.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/21/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXContactModel.h"

@interface DXContactModel ()

@property (strong, nonatomic, readwrite) NSString *identifier;
@property (strong, nonatomic, readwrite) NSString *fullName;
@property (strong, nonatomic, readwrite) NSString *birthDay;
@property (strong, nonatomic, readwrite) NSArray *phones;
@property (strong, nonatomic, readwrite) NSArray *emails;
@property (strong, nonatomic, readwrite) NSArray *addressArray;
@property (strong, nonatomic, readwrite) UIImage *avatar;

@end

@implementation DXContactModel

- (instancetype)initWithIdentifier:(NSString *)identifier fullName:(NSString *)fullName birthDay:(NSString *)birthDay phones:(NSArray *)phones emails:(NSArray *)emails addressArray:(NSArray *)addressArray avatar:(UIImage *)image {
    self = [super init];
    if (self) {
        _identifier = identifier.copy;
        _fullName = fullName.copy;
        _birthDay = birthDay.copy;
        _phones = phones.copy;
        _emails = emails.copy;
        _addressArray = addressArray.copy;
        _avatar = image.copy;
    }
    return self;
}

- (void)updateAvatar:(UIImage *)avatar {
    _avatar = avatar;
}

@end

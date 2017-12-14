//
//  DXContactModel.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/21/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class CNContact;

@interface DXContactModel : NSObject

@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic, readonly) NSString *fullName;
@property (strong, nonatomic, readonly) NSString *birthDay;
@property (strong, nonatomic, readonly) NSArray *phones;
@property (strong, nonatomic, readonly) NSArray *emails;
@property (strong, nonatomic, readonly) NSArray *addressArray;
@property (strong, nonatomic, readonly) UIImage *avatar;
@property (strong, nonatomic, readonly) UIImage *thumbnail;

- (instancetype)initWithIdentifier:(NSString *)identifier fullName:(NSString *)fullName birthDay:(NSString *)birthDay phones:(NSArray *)phones emails:(NSArray *)emails addressArray:(NSArray *)addressArray avatar:(UIImage *)image;
- (void)updateAvatar:(UIImage *)avatar;

@end

//
//  DXShowPickedCollectionViewCell.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/23/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXShowPickedCollectionViewCell.h"
#import "DXContactModel.h"
#import "DXImageManager.h"

@interface DXShowPickedCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIView *imageCoverView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImgView;

@end

@implementation DXShowPickedCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self setupView];
}

#pragma mark - SetUp View

- (void)setupView {
    self.imageCoverView.layer.cornerRadius = self.imageCoverView.bounds.size.width / 2;
}

#pragma mark - Private

- (void)clearOldData {
    self.avatarImgView.image = nil;
}

#pragma mark - Public

- (void)displayContactModel:(DXContactModel *)contactModel {
    
    [self clearOldData];
    
    if (contactModel.avatar == nil || contactModel.avatar.size.width > 200) {
        __weak typeof(self) selfWeak = self;
        [sImageManager avatarForContact:contactModel withCompletionHandler:^(UIImage *image) {
            [contactModel updateAvatar:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                selfWeak.avatarImgView.image = contactModel.avatar;
            });
        }];
    } else {
        self.avatarImgView.image = contactModel.avatar;
    }
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    
    DXContactModel *contactModel = [object userInfo];
    [self displayContactModel:contactModel];
    return YES;
}

@end

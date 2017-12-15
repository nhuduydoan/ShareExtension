//
//  DXPickContactTableViewCell.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/20/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXPickContactTableViewCell.h"
#import "DXContactModel.h"
#import "DXImageManager.h"

@interface DXPickContactTableViewCell ()

@property (strong, nonatomic) UIView *avatarLayerView;
@property (strong, nonatomic) UIImageView *avatarImgView;
@property (strong, nonatomic) UILabel *titleLabel;

@end

@implementation DXPickContactTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - SetUp View

- (void)setUpView {
    [self setupAvatarView];
    [self setupChildLabels];
    
    UIView *selectedBackgroundView = [UIView new];
    selectedBackgroundView.backgroundColor = [UIColor clearColor];
    self.selectedBackgroundView = selectedBackgroundView;
}

- (void)setupAvatarView {
    self.avatarLayerView = [[UIView alloc] initWithFrame:CGRectMake(9, 9, 46, 46)];
    self.avatarLayerView.clipsToBounds = YES;
    self.avatarLayerView.layer.cornerRadius = self.avatarLayerView.bounds.size.width / 2;
    self.avatarImgView = [[UIImageView alloc] initWithFrame:self.avatarLayerView.bounds];
    [self.avatarLayerView addSubview:self.avatarImgView];
    [self.contentView addSubview:self.avatarLayerView];
}

- (void)setupChildLabels {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(61, (self.bounds.size.height - 32)/2, self.bounds.size.width - (16 + 61), 32)];
    self.titleLabel.clipsToBounds = YES;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:self.titleLabel];
}

#pragma mark - Private

- (void)clearOldData {
    self.avatarImgView.image = nil;
    self.titleLabel.text = @"";
}

#pragma mark - Public

- (void)displayContactModel:(DXContactModel *)contactModel {
    [self clearOldData];
    
    self.titleLabel.text = contactModel.fullName;
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

@end

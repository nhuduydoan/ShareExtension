//
//  DXConversationTableViewCell.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXConversationTableViewCell.h"
#import "DXConversationModel.h"
#import "DXImageManager.h"

@interface DXConversationTableViewCell ()

@property (strong, nonatomic) UIView *groupAvatarView;
@property (strong, nonatomic) UIView *avatarLayerView;
@property (strong, nonatomic) UIImageView *avatarImgView;
@property (strong, nonatomic) UILabel *titleLabel;

@end

@implementation DXConversationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
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

- (void)setupViews {
    [self setupAvatarView];
    [self setupChildLabels];
}

- (void)setupAvatarView {
    
    self.avatarLayerView = [[UIView alloc] initWithFrame:CGRectMake(10, 13, 46, 46)];
    self.avatarLayerView.clipsToBounds = YES;
    self.avatarLayerView.layer.cornerRadius = self.avatarLayerView.bounds.size.width / 2;
    self.avatarImgView = [[UIImageView alloc] initWithFrame:self.avatarLayerView.bounds];
    [self.avatarLayerView addSubview:self.avatarImgView];
    [self.contentView addSubview:self.avatarLayerView];
    
    self.groupAvatarView = [[UIView alloc] initWithFrame:CGRectMake(10, 13, 46, 46)];
    self.groupAvatarView.clipsToBounds = YES;
    [self.contentView addSubview:self.groupAvatarView];
}

- (void)setupChildLabels {
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(66, (self.bounds.size.height - 30)/2, self.bounds.size.width - (16 + 66), 30)];
    self.titleLabel.clipsToBounds = YES;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:self.titleLabel];
}

#pragma mark - Public

- (void)displayConversation:(DXConversationModel *)model {
    [self clearOldData];
    self.titleLabel.text = model.displayName;
    
    if (model.type == DXConversationTypeFriend) {
        self.avatarLayerView.alpha = 1;
        if (model.contact.avatar == nil || model.contact.avatar.size.width > 200) {
            __weak typeof(self) selfWeak = self;
            [sImageManager avatarForContact:model.contact withCompletionHandler:^(UIImage *image) {
                [model.contact updateAvatar:image];
                dispatch_async(dispatch_get_main_queue(), ^{
                    selfWeak.avatarImgView.image = model.contact.avatar;
                });
            }];
        } else {
            self.avatarImgView.image = model.contact.avatar;
        }
        
    } else {
        self.groupAvatarView.alpha = 1;
        if (model.avatars.count) {
            [self displayImagesArray:model.avatars];
        }
        __weak typeof(self) selfWeak = self;
        [sImageManager avatarForContactsArray:model.members withCompletionHandler:^(NSArray *images) {
            [model updateAvatars:images];
            dispatch_async(dispatch_get_main_queue(), ^{
                [selfWeak displayImagesArray:images];
            });
        }];
    }
}

- (void)displayString:(NSString *)string image:(UIImage *)image {
    [self clearOldData];
    self.titleLabel.text = string;
    self.avatarImgView.image = image;
    self.avatarLayerView.alpha = 1;
}

#pragma mark - Private

- (void)clearOldData {
    self.titleLabel.text = @"";
    self.groupAvatarView.alpha = 0;
    self.avatarLayerView.alpha = 0;
    self.avatarImgView.image = nil;
    for (UIView *view in self.groupAvatarView.subviews) {
        [view removeFromSuperview];
    }
}

- (void)displayImagesArray:(NSArray *)images {
    NSAssert(images.count, @"Images array can not be null");
    
    if (images.count == 3) {
        [self displayThreeImages:images];
        return;
    }
    
    UIView *view = self.groupAvatarView;
    CGFloat imgWidth =  self.groupAvatarView.bounds.size.width / 2;
    for (NSInteger i = 0 ; i < images.count && i < 4; i++) {
        CGFloat x = (i == 0 || i == 2) ? 0 : imgWidth;
        CGFloat y = (i == 1 || i == 2) ? 0 : imgWidth;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, imgWidth, imgWidth)];
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = imgWidth/2;
        UIImage *image = [images objectAtIndex:i];
        imageView.image = image;
        [view addSubview:imageView];
    }
}

- (void)displayThreeImages:(NSArray *)images {
    NSAssert(images.count == 3, @"Number of images must equal 3");
    
    // Create a triangle is centered in the groupAvatarView which contains 3 avatar imageviews
    UIView *view = self.groupAvatarView;
    CGFloat imgWidth =  self.groupAvatarView.bounds.size.width / 2;

    // Create top imageview and add into groupAvatarView
    CGFloat x = imgWidth/2;
    CGFloat y = (2 - sqrt(3.0))/4 * imgWidth;
    UIImageView *imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, imgWidth, imgWidth)];
    imageView1.clipsToBounds = YES;
    imageView1.layer.cornerRadius = imgWidth/2;
    UIImage *image1 = [images objectAtIndex:0];
    imageView1.image = image1;
    [view addSubview:imageView1];
    
    // Create 2 bottom imageviews and add into groupAvatarView
    for (NSInteger i = 1; i < 3; i++) {
        CGFloat x2 = (i-1) * imgWidth;
        CGFloat y2 = (2 + sqrt(3.0))/4 * imgWidth;
        UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(x2, y2, imgWidth, imgWidth)];
        imageView2.clipsToBounds = YES;
        imageView2.layer.cornerRadius = imgWidth/2;
        UIImage *image2 = [images objectAtIndex:i];
        imageView2.image = image2;
        [view addSubview:imageView2];
    }
}

@end

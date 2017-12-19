//
//  DXImageManager.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/3/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class DXContactModel, DXConversationModel;

#define sImageManager [DXImageManager sharedInstance]

@interface DXImageManager : NSObject

+ (id)sharedInstance;

- (instancetype)init NS_UNAVAILABLE;

- (UIImage *)imageWithColor:(UIColor *)color;

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

/**
 Get avatar image from cache for contact model
 If no image in cache, draw new image from original avatar or draw an image from contact's full name

 @param contact : non null contact model
 @param completionHander : block which will be execute when get/create avatar image finished
 */
- (void)avatarForContact:(DXContactModel *)contact withCompletionHandler:(void (^)(UIImage *image))completionHander;

- (void)avatarForContactsArray:(NSArray<DXContactModel *> *)contacts withCompletionHandler:(void (^)(NSArray *images))completionHander;

/**
 Draw an image with clear background color and size 100x100, text is given string

 @param string : string for drawing
 @return : nullable image
 */
- (UIImage *)titleImageFromString:(NSString *)string color:(UIColor *)color;
- (UIImage *)avatarImageFromOriginalImage:(UIImage *)image;

- (UIImage *)drawThumbnailFromImages:(NSArray *)images videoString:(NSString *)videoString;

@end

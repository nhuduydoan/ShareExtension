//
//  DXImageManager.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/3/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXImageManager.h"
#import "DXContactModel.h"
#import "DXConversationModel.h"

#define kMakeColor(r,g,b,a) [UIColor colorWithRed:r/255.f green:g/255.f blue:b/255.f alpha:a]

typedef NS_ENUM(NSUInteger, DXAvatarImageSize) {
    DXAvatarImageSizeSmall,
    DXAvatarImageSizeMedium
};

@interface DXImageManager ()

@property (strong, nonatomic) NSArray *avatarBGColors;
//@property (strong, nonatomic) NIImageMemoryCache *imagesCache;
@property (strong, nonatomic) dispatch_queue_t avatartQueue;

@end

@implementation DXImageManager

+ (id)sharedInstance {
    static id _instace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_instace) {
            _instace = [[self.class alloc] initSharedInstance];
        }
    });
    return _instace;
}

- (instancetype)initSharedInstance
{
    self = [super init];
    if (self) {
        [self setUpAvatarBGColors];
//        _imagesCache = [[NIImageMemoryCache alloc] initWithCapacity:1000];
        _avatartQueue = dispatch_queue_create("DXAvatarQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (instancetype) init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

- (void)setUpAvatarBGColors {
    
    NSMutableArray *colorsArr = [NSMutableArray new];
    UIColor *color1 = kMakeColor(152, 193, 213, 1);
    UIColor *color2 = kMakeColor(140, 205, 188, 1);
    UIColor *color3 = kMakeColor(122, 196, 216, 1);
    UIColor *color4 = kMakeColor(238, 179, 148, 1);
    UIColor *color5 = kMakeColor(239, 155, 155, 1);
    UIColor *color6 = kMakeColor(197, 165, 150, 1);
    UIColor *color7 = kMakeColor(173, 175, 231, 1);
    UIColor *color8 = kMakeColor(171, 176, 193, 1);
    [colorsArr addObject:color1];
    [colorsArr addObject:color2];
    [colorsArr addObject:color3];
    [colorsArr addObject:color4];
    [colorsArr addObject:color5];
    [colorsArr addObject:color6];
    [colorsArr addObject:color7];
    [colorsArr addObject:color8];
    self.avatarBGColors = colorsArr.copy;
}

#pragma mark - Public

- (UIImage *)imageWithColor:(UIColor *)color {
    return [self imageWithColor:color size:CGSizeMake(1, 1)];
}

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)avatarForContact:(DXContactModel *)contact withCompletionHandler:(void (^)(UIImage *image))completionHander {
    __weak typeof(self) selfWeak = self;
    dispatch_async(self.avatartQueue, ^{
        UIImage *image = [selfWeak avatarForContact:contact];
//        [selfWeak.imagesCache storeObject:image withName:contact.identifier expiresAfter:[NSDate dateWithTimeIntervalSinceNow:300]];
        if (completionHander) {
            completionHander(image);
        }
    });
}

- (void)avatarForContactsArray:(NSArray<DXContactModel *> *)contacts withCompletionHandler:(void (^)(NSArray *images))completionHander {
    NSAssert(contacts.count, @"Array of contacts must be non null");
    
    __weak typeof(self) selfWeak = self;
    dispatch_async(self.avatartQueue, ^{
        NSMutableArray *images = [NSMutableArray new];
        for (NSInteger i = 0; i < 3 && i < contacts.count; i ++) {
            DXContactModel *contact = contacts[i];
            UIImage *image = [selfWeak avatarForContact:contact];
            [images addObject:image];
        }
        if (contacts.count > 4) {
            UIImage *image = [selfWeak avatarImageFromString:[NSString stringWithFormat:@"%zd", contacts.count] backgroundColor:kMakeColor(194, 206, 225, 1) stringSize:DXAvatarImageSizeMedium];
            [images addObject:image];
        } else if (contacts.count == 4) {
            DXContactModel *contact = contacts[3];
            UIImage *image = [selfWeak avatarForContact:contact];
            [images addObject:image];
        }
        if (completionHander) {
            completionHander(images);
        }
    });
}

- (UIImage *)titleImageFromString:(NSString *)string color:(UIColor *)color {
    
    NSDictionary *textAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:17], NSForegroundColorAttributeName:color};
    CGSize size = [string sizeWithAttributes:textAttributes];
    UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    [string drawAtPoint:CGPointMake(0, 0) withAttributes:textAttributes];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)avatarImageFromOriginalImage:(UIImage *)image {
    
    CGFloat width, height;
    if (image.size.width > image.size.height) {
        height = 100;
        width = image.size.width/image.size.height * 100;
    } else {
        width = 100;
        height = image.size.width/image.size.height * 100;
    }
    
    if (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight) {
        CGFloat x = width;
        width = height;
        height = x;
    }
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    UIGraphicsPopContext();
    UIImage *avartar = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return avartar;
}

#pragma mark - Private

- (UIImage *)avatarForContact:(DXContactModel *)contact {
    NSAssert(contact, @"Contact can not be null");
    
    if (contact.avatar && contact.avatar.size.width <= 200) {
        return contact.avatar;
    }
//    UIImage *img = [self.imagesCache objectWithName:contact.identifier];
    UIImage *img;
    if (img == nil) {
        if (contact.avatar == nil) {
            NSString *avatarString = [self avatarStringFromFullName:contact.fullName];
            img = [self avatarImageFromString:avatarString backgroundColor:nil stringSize:DXAvatarImageSizeSmall];
        } else {
            img = [self avatarImageFromOriginalImage:contact.avatar];
        }
    }
//    [self.imagesCache storeObject:img withName:contact.identifier expiresAfter:[NSDate dateWithTimeIntervalSinceNow:300]];
    return img;
}

-(UIImage *)avatarImageFromString:(NSString *)avatarString backgroundColor:(UIColor *)color stringSize:(DXAvatarImageSize)stringSize {
    
    UIFont *font = [UIFont systemFontOfSize:44 weight:UIFontWeightRegular];
    if (stringSize == DXAvatarImageSizeMedium) {
        font = [UIFont systemFontOfSize:66 weight:UIFontWeightRegular];
    }
    NSDictionary *textAttributes = @{NSFontAttributeName:font,
                                     NSForegroundColorAttributeName:[UIColor whiteColor]};
    CGSize size = [avatarString sizeWithAttributes:textAttributes];
    int randColor = rand() % 8;
    UIColor *backgroundColor = color ? color : self.avatarBGColors[randColor];
    CGRect rect = CGRectMake(0, 0, 100, 100);
    UIBezierPath* textPath = [UIBezierPath bezierPathWithRect:rect];
    
    UIGraphicsBeginImageContextWithOptions(rect.size,NO,0.0);
    //Fill background color
    [backgroundColor setFill];
    [textPath fill];
    //Draw Srting
    [avatarString drawAtPoint:CGPointMake(rect.size.width/2 - size.width/2, rect.size.height/2 - size.height/2) withAttributes:textAttributes];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (NSString *)avatarStringFromFullName:(NSString *)fullName {
    
    NSString *avatarStr = @"";
    if (fullName.length == 0) {
        return avatarStr;
    }
    
    BOOL isFirstKey = YES;
    NSCharacterSet *characterSet = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *spaceSet = [NSCharacterSet whitespaceCharacterSet];
    
    for (NSInteger i = 0; i < fullName.length; i++) {
        unichar character = [fullName characterAtIndex:i];
        if (isFirstKey && [characterSet characterIsMember:character]) {
            NSString *addKey = [fullName substringFromIndex:i];
            addKey = [addKey substringToIndex:1];
            avatarStr = [avatarStr stringByAppendingString:addKey.uppercaseString];
            if (avatarStr.length >= 2) {
                break;
            }
            isFirstKey = NO;
        } else if ([spaceSet characterIsMember:character]) {
            isFirstKey = YES;
        }
    }
    
    if (avatarStr.length == 0) {
        for (NSInteger i = 0; i < fullName.length; i++) {
            unichar character = [fullName characterAtIndex:i];
            if (![spaceSet characterIsMember:character]) {
                NSString *addKey = [fullName substringFromIndex:i];
                addKey = [addKey substringToIndex:1];
                avatarStr = [avatarStr stringByAppendingString:addKey];
                if (avatarStr.length >= 2) {
                    break;
                }
                isFirstKey = NO;
            } else {
                isFirstKey = YES;
            }
        }
    }
    
    return avatarStr;
}

@end

//
//  ZLShareDefine.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ZLShareType) {
    ZLShareTypeUnknown = 0,
    ZLShareTypeImage,
    ZLShareTypeMovie,
    ZLShareTypeFile,
    ZLShareTypeWebURL,
    ZLShareTypeWebPage,
    ZLShareTypeText
};

typedef NS_ENUM(NSInteger, ZLVideoPackageCompressType) {
    ZLVideoPackageCompressTypeOrigin = 0,
    ZLVideoPackageCompressTypeLow,
    ZLVideoPackageCompressTypeMedium,
    ZLVideoPackageCompressTypeHigh,
    ZLVideoPackageCompressType640x480,
    ZLVideoPackageCompressType1280x720,
    ZLVideoPackageCompressType1920x1080
};

typedef NS_ENUM(NSInteger, ZLImagePackageCompressType) {
    ZLImagePackageCompressTypeOrigin = 0,
    ZLImagePackageCompressType640x480,
    ZLImagePackageCompressType1280x720,
    ZLImagePackageCompressType1920x1080
};

typedef NS_ENUM(NSInteger, ZLShareError) {
    ZLShareNilExtensionContextError = 100,
    ZLShareNilExtensionItemError
};

typedef NS_ENUM(NSInteger, ZLCompressError) {
    ZLCompressImageError = 100,
    ZLCompressVideoError
};



//DEFINE
#pragma mark - Define

//Queue constaint
#define globalDefaultQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define globalBackgroundQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
#define globalHighQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
#define mainQueue dispatch_get_main_queue()

#define GetValidQueue(queue)                queue ? queue : mainQueue

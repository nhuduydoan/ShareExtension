//
//  ZLShareDefine.h
//  ZProbation-ShareExtension
//
//  Created by CPU12068 on 12/13/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString* ZLShareType;
static ZLShareType const ZLShareTypeUnknown        = @"ZLShareTypeUnknown";
static ZLShareType const ZLShareTypeImage          = @"ZLShareTypeImage";
static ZLShareType const ZLShareTypeVideo          = @"ZLShareTypeVideo";
static ZLShareType const ZLShareTypeFile           = @"ZLShareTypeFile";
static ZLShareType const ZLShareTypeWebURL         = @"ZLShareTypeWebURL";
static ZLShareType const ZLShareTypeWebPage        = @"ZLShareTypeWebPage";
static ZLShareType const ZLShareTypeText           = @"ZLShareTypeText";

//typedef NS_ENUM(NSInteger, ZLShareType) {
//    ZLShareTypeUnknown = 0,
//    ZLShareTypeImage,
//    ZLShareTypeVideo,
//    ZLShareTypeFile,
//    ZLShareTypeWebURL,
//    ZLShareTypeWebPage,
//    ZLShareTypeText
//};

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
    ZLShareNilExtensionItemError,
    ZLInvalidInputError,
    ZLCompressImageError,
    ZLCompressVideoError,
    ZLCompressTypeUnknowError,
    ZLFileNotExistError,
    ZLInvalidTypeError
};



//DEFINE
#pragma mark - Define

//Queue constaint
#define globalDefaultQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define globalBackgroundQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
#define globalHighQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
#define mainQueue dispatch_get_main_queue()

#define GetValidQueue(queue)                queue ? queue : mainQueue



//Dictionary Key
#define kZLUploadSharePackageError                  @"kZLUploadSharePackageError"
#define kZLUploadSharePackageFailedCount            @"kZLUploadSharePackageFailedCount"
#define kZLUploadSharePackageCompletedCount         @"kZLUploadSharePackageCompletedCount"

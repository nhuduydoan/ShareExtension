//
//  ZLShareExtensionManager_Image.h
//  ShareExtension
//
//  Created by Nhữ Duy Đoàn on 12/19/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "ZLShareExtensionManager.h"

@interface ZLShareExtensionManager (Image)

- (void)getShareThumbnailWithCompletionHandler:(void (^)(UIImage *image))completionHandler;

@end

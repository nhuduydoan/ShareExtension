//
//  HMNetworkManager.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

typedef NS_ENUM(NSInteger, HMNetworkStatus) {
    HMNetworkStatusUnknown              = -1,
    HMNetworkStatusNotReachable         = 0,
    HMNetworkStatusReachableViaWWAN     = 1,
    HMNetworkStatusReachableViaWifi     = 2
};

typedef void (^HMNetworkChangeBlock)(HMNetworkStatus status);

@interface HMNetworkManager : NSObject

@property(readonly, nonatomic, getter=isReachable) BOOL reachable;
@property(readonly, nonatomic, getter=isReachableViaWWAN) BOOL reachableViaWWAN;
@property(readonly, nonatomic, getter=isReachableViaWifi) BOOL reachableViaWifi;

@property(strong, nonatomic) HMNetworkChangeBlock networkStatusChangeBlock;

+ (instancetype)shareInstance;

- (void)startMonitoring;
- (void)stopMonitoring;

@end

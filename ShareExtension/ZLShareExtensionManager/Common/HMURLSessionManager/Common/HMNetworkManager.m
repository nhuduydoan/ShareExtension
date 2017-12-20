//
//  HMNetworkManager.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMNetworkManager.h"
#import "Constaint.h"

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

static const void * HMNetworkRetainCallback(const void *info) {
    return Block_copy(info);
}

static void HMNetworkReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

static HMNetworkStatus HMNetworkStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
    
    HMNetworkStatus status = HMNetworkStatusUnknown;
    if (isNetworkReachable == NO) {
        status = HMNetworkStatusNotReachable;
    }
#if    TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = HMNetworkStatusReachableViaWWAN;
    }
#endif
    else {
        status = HMNetworkStatusReachableViaWifi;
    }
    
    return status;
}

static void HMPostStatusChange(SCNetworkReachabilityFlags flags, HMNetworkChangeBlock block) {
    HMNetworkStatus status = HMNetworkStatusForFlags(flags);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block(status);
        }
    });
}

static void HMNetworkCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    HMPostStatusChange(flags, (__bridge HMNetworkChangeBlock)info);
}




@interface HMNetworkManager()

@property(nonatomic) SCNetworkReachabilityRef networkReachability;
@property(nonatomic) HMNetworkStatus networkStatus;

@end

@implementation HMNetworkManager

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (instancetype)shareInstance {
    static HMNetworkManager *shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [self manager];
    });
    
    return shareInstance;
}

+ (instancetype)manager
{
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif
    return [self managerForAddress:&address];
}

+ (instancetype)managerForAddress:(const void *)address {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);
    id manager = [[self alloc] initWithReachability:reachability];

    return manager;
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    if (self = [super init]) {
        _networkReachability = CFRetain(reachability);
        _networkStatus = HMNetworkStatusUnknown;
    }

    return self;
}

- (void)startMonitoring {
    [self stopMonitoring];
    
    if (!_networkReachability) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    HMNetworkChangeBlock callback = ^(HMNetworkStatus status) {
        __typeof__(self) strongSelf = weakSelf;
        strongSelf.networkStatus = status;
        if (strongSelf.networkStatusChangeBlock) {
            strongSelf.networkStatusChangeBlock(status);
        }
    };
    
    SCNetworkReachabilityContext context;
    context.version = 0;
    context.info = (__bridge void *)callback;
    context.retain = HMNetworkRetainCallback;
    context.release = HMNetworkReleaseCallback;
    
    SCNetworkReachabilitySetCallback(_networkReachability, HMNetworkCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(_networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    dispatch_async(globalBackgroundQueue, ^{
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(_networkReachability, &flags)) {
            HMPostStatusChange(flags, callback);
        }
    });
}

- (void)stopMonitoring {
    if (!_networkReachability) {
        return;
    }
    
    SCNetworkReachabilityUnscheduleFromRunLoop(_networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWifi];
}

- (BOOL)isReachableViaWifi {
    return _networkStatus == HMNetworkStatusReachableViaWWAN;
}

- (BOOL)isReachableViaWWAN {
    return _networkStatus == HMNetworkStatusReachableViaWifi;
}

@end

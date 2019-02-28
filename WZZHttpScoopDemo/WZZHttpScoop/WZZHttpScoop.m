//
//  WZZHttpScoop.m
//  SampleHttpService
//
//  Created by mac on 2019/2/21.
//  Copyright © 2019 zenggen. All rights reserved.
//

#import "WZZHttpScoop.h"
#import "WZZHttpScoopTask.h"
#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>

static WZZHttpScoop * wzzHttpScoop;

@interface WZZHttpScoop ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) dispatch_queue_t serverQueue;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, strong) GCDAsyncSocket *serverSocket;
@property (nonatomic, strong) NSMutableArray<WZZHttpScoopTask *> *tasks;
@property (nonatomic, strong) NSRecursiveLock *taskLock;

@end

@implementation WZZHttpScoop

+ (instancetype)shareInstance {
    if (!wzzHttpScoop) {
        wzzHttpScoop = [[WZZHttpScoop alloc] init];
        [wzzHttpScoop setup];
    }
    return wzzHttpScoop;
}

- (void)setup {
    self.tasks = [NSMutableArray array];
    self.serverQueue = dispatch_queue_create("com.zenggen.ZGHTTPServer.serverQueue", NULL);
    self.taskQueue = dispatch_queue_create("com.zenggen.ZGHTTPServer.taskQueue", NULL);
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_serverQueue];
}

- (NSError *)startWithPort:(NSInteger)port {
    __block NSError *error;
    dispatch_sync(self.serverQueue, ^{
        WZZHttpScoopTask_Log(@"服务启动，等待连接");
        [self.serverSocket acceptOnPort:port error:&error];
    });
    return error;
}

- (void)stop{
    [self.taskLock lock];
    [self.tasks removeAllObjects];
    [self.taskLock unlock];
    [self.serverSocket disconnect];
}

- (NSString *)IP {
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"]){
                    freeifaddrs(addrs);
                    return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return @"127.0.0.1";
}

#pragma mark scoket代理
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    if(!self.taskLock) {
        self.taskLock = [[NSRecursiveLock alloc] init];
    }
    
    if(!self.tasks) {
        self.tasks = [NSMutableArray array];
    }
    
    __weak typeof(self) weakSelf = self;
    WZZHttpScoopTask * connectTask = [[WZZHttpScoopTask alloc] initWithSocket:newSocket queue:self.taskQueue complete:^(WZZHttpScoopTask * _Nonnull aTask) {
        [weakSelf.taskLock lock];
        [weakSelf.tasks removeObject:aTask];
        [weakSelf.taskLock unlock];
    }];
    connectTask.handleRequestOK = self.handleRequestOK;
    connectTask.handleResponseOK = self.handleResponseOK;
    [_taskLock lock];
    [_tasks addObject:connectTask];
    [_taskLock unlock];
    [connectTask start];
}

@end

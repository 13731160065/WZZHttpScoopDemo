//
//  WZZHttpScoopTask.h
//  SampleHttpService
//
//  Created by mac on 2019/2/21.
//  Copyright © 2019 zenggen. All rights reserved.
//  网络请求任务

#import <Foundation/Foundation.h>
#import <GCDAsyncSocket.h>
#import "WZZHttpScoopRequestModel.h"
#import "WZZHttpScoopResponseModel.h"

#define WZZHttpScoopTask_LogOpen 1

#if WZZHttpScoopTask_LogOpen
#define WZZHttpScoopTask_Log(xxx, ...) NSLog(xxx, ##__VA_ARGS__)
#else
#define WZZHttpScoopTask_Log(xxx, ...)
#endif

NS_ASSUME_NONNULL_BEGIN

@interface WZZHttpScoopTask : NSObject

@property (strong, nonatomic) GCDAsyncSocket * socket;

/**
 请求
 */
@property (strong, nonatomic) WZZHttpScoopRequestModel * request;

/**
 响应
 */
@property (strong, nonatomic) WZZHttpScoopResponseModel * response;

/**
 处理请求结束回调
 */
@property (strong, nonatomic) void(^handleRequestOK)(WZZHttpScoopTask * aTask);

/**
 处理响应结束回调
 */
@property (strong, nonatomic) void(^handleResponseOK)(WZZHttpScoopTask * aTask);

/**
 初始化

 @param socket socket
 @param complete 结束
 @return 实例
 */
- (instancetype)initWithSocket:(GCDAsyncSocket *)socket
                         queue:(dispatch_queue_t)queue
                      complete:(void(^)(WZZHttpScoopTask * aTask))complete;

/**
 开始任务
 */
- (void)start;

@end

NS_ASSUME_NONNULL_END

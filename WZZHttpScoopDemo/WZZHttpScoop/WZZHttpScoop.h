//
//  WZZHttpScoop.h
//  SampleHttpService
//
//  Created by mac on 2019/2/21.
//  Copyright © 2019 zenggen. All rights reserved.
//  http代理服务器

#import <Foundation/Foundation.h>
#import "WZZHttpScoopTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface WZZHttpScoop : NSObject

/**
 允许地址
 */
@property (strong, nonatomic) NSArray * allowHosts;

/**
 允许端口
 */
@property (strong, nonatomic) NSArray * allowPorts;

/**
 抓到请求
 */
@property (strong, nonatomic) void(^handleRequestOK)(WZZHttpScoopTask * aTask);

/**
 抓到响应
 */
@property (strong, nonatomic) void(^handleResponseOK)(WZZHttpScoopTask * aTask);

/**
 单例

 @return 实例
 */
+ (instancetype)shareInstance;

/**
 开启代理服务

 @param port 端口
 @return 错误
 */
- (NSError *)startWithPort:(NSInteger)port;

/**
 停止
 */
- (void)stop;

/**
 获取本机ip

 @return ip
 */
- (NSString *)IP;

@end

NS_ASSUME_NONNULL_END

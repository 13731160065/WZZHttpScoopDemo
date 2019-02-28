//
//  WZZHttpScoopResponseModel.h
//  SampleHttpService
//
//  Created by mac on 2019/2/21.
//  Copyright © 2019 zenggen. All rights reserved.
//  响应模型

#import <Foundation/Foundation.h>

@interface WZZHttpScoopResponseModel : NSObject

/**
 原始数据
 */
@property (strong, nonatomic, readonly) NSData * orgData;

/**
 原始字符串
 */
@property (strong, nonatomic, readonly) NSString * orgStr;

/**
 是否编辑过
 */
@property (assign, nonatomic) BOOL isEdit;

/**
 协议
 */
@property (strong, nonatomic) NSString *protocol;

/**
 版本
 */
@property (strong, nonatomic) NSString *version;

/**
 状态码
 */
@property (assign, nonatomic) NSInteger stateCode;

/**
 状态描述
 */
@property (strong, nonatomic) NSString *stateDesc;

/**
 响应头
 */
@property (strong, nonatomic) NSDictionary *headerDic;

/**
 响应体类型
 */
@property (strong, nonatomic) NSString * ContentType;

/**
 响应数据
 */
@property (strong, nonatomic) NSString * responseStr;

/**
 生成模型
 
 @param aData 响应数据
 @return 实例
 */
+ (instancetype)modelWithResponseData:(NSData *)aData;

/**
 组织响应数据

 @return 数据
 */
- (NSData *)makeResponse;

/**
 转字符串

 @return 描述字符串
 */
- (NSString *)toString;

@end

//
//  WZZHttpScoopRequestModel.h
//  SampleHttpService
//
//  Created by mac on 2019/2/21.
//  Copyright © 2019 zenggen. All rights reserved.
//  请求模型

#import <Foundation/Foundation.h>

@interface WZZHttpScoopRequestModel : NSObject

/**
 原始数据
 */
@property (strong, nonatomic, readonly) NSData * orgData;

/**
 原始字符串
 */
@property (strong, nonatomic, readonly) NSString * orgStr;

/**
 请求方式
 */
@property (strong, nonatomic) NSString * method;

/**
 路径
 */
@property (strong, nonatomic) NSString * url;

/**
 协议
 */
@property (strong, nonatomic) NSString * protocol;

/**
 版本
 */
@property (strong, nonatomic) NSString * version;

/**
 请求头
 */
@property (strong, nonatomic) NSDictionary * headerDic;

/**
 请求体长度
 */
@property (assign, nonatomic) NSInteger ContentLength;

/**
 请求体类型
 */
@property (strong, nonatomic) NSString * ContentType;

/**
 请求体
 */
@property (strong, nonatomic) NSDictionary * bodyDic;

/**
 url参数
 */
@property (strong, nonatomic) NSDictionary * urlParamDic;

/**
 是否编辑过
 */
@property (assign, nonatomic) BOOL isEdited;

/**
 生成模型

 @param aData 请求数据
 @return 实例
 */
+ (instancetype)modelWithRequestData:(NSData *)aData;

/**
 组织请求数据

 @return 数据
 */
- (NSData *)makeRequest;

/**
 转字符串

 @return 描述字符串
 */
- (NSString *)toString;

@end

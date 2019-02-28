//
//  WZZHttpScoopResponseModel.m
//  SampleHttpService
//
//  Created by mac on 2019/2/21.
//  Copyright © 2019 zenggen. All rights reserved.
//

#import "WZZHttpScoopResponseModel.h"

@implementation WZZHttpScoopResponseModel

+ (instancetype)modelWithResponseData:(NSData *)aData {
    NSString * aStr = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    WZZHttpScoopResponseModel * aModel = [[WZZHttpScoopResponseModel alloc] init];
    aModel->_orgData = aData;
    aModel->_orgStr = aStr;
    
    //处理响应
    NSArray * respArr = [aStr componentsSeparatedByString:@"\r\n\r\n"];
    NSString * headStr = respArr.firstObject;
    [aModel handleHeadWithStr:headStr];
    NSString * bodyStr = respArr.lastObject;
    aModel->_responseStr = bodyStr;
    
    return aModel;
}

/**
 MARK:处理响应头
 
 @param headStr 响应头
 */
- (void)handleHeadWithStr:(NSString *)headStr {
    NSArray * aArr = [headStr componentsSeparatedByString:@"\r\n"];
    NSString * response = aArr.firstObject;
    NSArray * responseArr = [response componentsSeparatedByString:@" "];
    if (responseArr.count >= 3) {
        NSString * httpProxyVersion = responseArr[0];
        NSString * stateCode = responseArr[1];
        NSString * stateStr = responseArr[2];
        _stateCode = [stateCode integerValue];
        _stateDesc = stateStr;
        _protocol = [[httpProxyVersion componentsSeparatedByString:@"/"] firstObject];
        _version = [[httpProxyVersion componentsSeparatedByString:@"/"] lastObject];
    }
    
    if (aArr.count > 1) {
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        for (int i = 1; i < aArr.count; i++) {
            NSString * headerStr = aArr[i];
            NSArray * headerArr = [headerStr componentsSeparatedByString:@": "];
            dic[headerArr[0]] = headerArr[1];
        }
        _headerDic = dic;
        _ContentType = dic[@"Content-Type"];
    }
}

/**
 组织响应数据

 @return 数据
 */
- (NSData *)makeResponse {
    if (self.isEdit) {
        //编辑过，组织数据
        NSMutableString * str = [NSMutableString string];
        
        //响应行
        NSMutableArray * respArr = [NSMutableArray array];
        [respArr addObject:[NSString stringWithFormat:@"%@/%@", self.protocol, self.version]];
        [respArr addObject:@(self.stateCode).stringValue];
        [respArr addObject:self.stateDesc];
        [str appendFormat:@"%@", [respArr componentsJoinedByString:@" "]];
        
        //响应头
        NSMutableArray * headerArr = [NSMutableArray array];
        NSArray * keyArr = self.headerDic.allKeys;
        for (int i = 0; i < keyArr.count; i++) {
            NSString * key = keyArr[i];
            NSString * value = self.headerDic[key];
            [headerArr addObject:[NSString stringWithFormat:@"%@: %@", key, value?value:@""]];
        }
        [str appendFormat:@"%@", [headerArr componentsJoinedByString:@"\r\n"]];
        
        return [str dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        //没编辑过直接返回原始数据
        return self.orgData;
    }
}

- (NSString *)toString {
    return [[NSString alloc] initWithData:[self makeResponse] encoding:NSUTF8StringEncoding];
}

@end

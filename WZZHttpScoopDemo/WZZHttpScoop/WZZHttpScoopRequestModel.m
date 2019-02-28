//
//  WZZHttpScoopRequestModel.m
//  SampleHttpService
//
//  Created by mac on 2019/2/21.
//  Copyright © 2019 zenggen. All rights reserved.
//

#import "WZZHttpScoopRequestModel.h"

@implementation WZZHttpScoopRequestModel

+ (instancetype)modelWithRequestData:(NSData *)aData {
    NSString * aStr = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    WZZHttpScoopRequestModel * aModel = [[WZZHttpScoopRequestModel alloc] init];
    //原始数据
    aModel->_orgData = aData;
    aModel->_orgStr = aStr;
    
    //处理请求
    NSArray * reqArr = [aStr componentsSeparatedByString:@"\r\n\r\n"];
    NSString * headStr = reqArr.firstObject;
    [aModel handleHeadWithStr:headStr];
    NSString * bodyStr = reqArr.lastObject;
    [aModel handleBodyWithStr:bodyStr];
    
    return aModel;
}

/**
 MARK:处理请求头

 @param headStr 请求头
 */
- (void)handleHeadWithStr:(NSString *)headStr {
    NSArray * aArr = [headStr componentsSeparatedByString:@"\r\n"];
    NSString * request = aArr.firstObject;
    NSArray * requestArr = [request componentsSeparatedByString:@" "];
    if (requestArr.count >= 3) {
        NSString * method = requestArr[0];
        NSString * url = requestArr[1];
        NSString * httpProxyVersion = requestArr[2];
        _method = method;
        _url = url;
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
        _ContentLength = [dic[@"Content-Length"] integerValue];
        _ContentType = dic[@"Content-Type"];
    }
}

/**
 MARK:处理请求体

 @param bodyStr 请求体
 */
- (void)handleBodyWithStr:(NSString *)bodyStr {
    NSString * type = [[self.ContentType componentsSeparatedByString:@";"] firstObject];
    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
    if ([type isEqualToString:@"application/x-www-form-urlencoded"]) {
        NSArray * arr = [bodyStr componentsSeparatedByString:@"&"];
        for (NSString * item in arr) {
            NSArray * kvArr = [item componentsSeparatedByString:@"="];
            if (kvArr.firstObject) {
                dic[kvArr.firstObject] = kvArr.lastObject;
            }
        }
    } else if ([type isEqualToString:@"application/json"]) {
        NSDictionary * body = [NSJSONSerialization JSONObjectWithData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        [dic addEntriesFromDictionary:body];
    } else if ([type isEqualToString:@"multipart/form-data"]) {
        
    }
    
    _bodyDic = dic;
}

//MARK:组织请求数据
- (NSData *)makeRequest {
    if (_isEdited) {
        //编辑过则组http请求
        NSMutableString * str = [NSMutableString string];
        
        //请求行
        NSMutableArray * reqArr = [NSMutableArray array];
        [reqArr addObject:self.method];
        [reqArr addObject:self.url];
        [reqArr addObject:[NSString stringWithFormat:@"%@/%@", self.protocol, self.version]];
        [str appendFormat:@"%@", [reqArr componentsJoinedByString:@" "]];
        
        //请求头
        NSMutableArray * headerArr = [NSMutableArray array];
        NSArray * keyArr = self.headerDic.allKeys;
        for (int i = 0; i < keyArr.count; i++) {
            NSString * key = keyArr[i];
            NSString * value = self.headerDic[key];
            [headerArr addObject:[NSString stringWithFormat:@"%@: %@", key, value?value:@""]];
        }
        [str appendFormat:@"%@", [headerArr componentsJoinedByString:@"\r\n"]];
        
        //请求体
        if (self.bodyDic.count) {
            [str appendFormat:@"\r\n\r\n"];
            NSString * type = [[self.ContentType componentsSeparatedByString:@";"] firstObject];
            if ([type isEqualToString:@"application/x-www-form-urlencoded"]) {
                NSMutableArray * paramArr = [NSMutableArray array];
                NSArray * bodyKeyArr = self.headerDic.allKeys;
                for (int i = 0; i < bodyKeyArr.count; i++) {
                    NSString * key = bodyKeyArr[i];
                    NSString * value = self.bodyDic[key];
                    [paramArr addObject:[NSString stringWithFormat:@"%@=%@", key, value?value:@""]];
                }
                [str appendFormat:@"%@", [paramArr componentsJoinedByString:@"&"]];
            } else if ([type isEqualToString:@"application/json"]) {
                NSData * data = [NSJSONSerialization dataWithJSONObject:self.bodyDic options:0 error:nil];
                [str appendFormat:@"%@", data?[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]:@""];
            } else if ([type isEqualToString:@"multipart/form-data"]) {
                
            }
        }
        
        return [str dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        //如果没编辑过，则直接发送原始数据
        return self.orgData;
    }
}

- (NSString *)toString {
    return [[NSString alloc] initWithData:[self makeRequest] encoding:NSUTF8StringEncoding];
}

@end

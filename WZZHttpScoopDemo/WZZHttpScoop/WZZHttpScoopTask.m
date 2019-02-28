//
//  WZZHttpScoopTask.m
//  SampleHttpService
//
//  Created by mac on 2019/2/21.
//  Copyright © 2019 zenggen. All rights reserved.
//

#import "WZZHttpScoopTask.h"
#import "WZZHttpScoopRequestModel.h"

typedef enum : NSUInteger {
    WZZHttpScoopTask_Tag_Request = 51993,//请求
    WZZHttpScoopTask_Tag_Response,//响应
    WZZHttpScoopTask_Tag_ReRequest,//转发请求
    WZZHttpScoopTask_Tag_ReResponse,//转发响应
} WZZHttpScoopTask_Tag;

NSTimeInterval WZZHttpScoopTask_TimeOut = 30;

@interface WZZHttpScoopTask ()<GCDAsyncSocketDelegate>

@property (strong, nonatomic) void(^completeBlock)(WZZHttpScoopTask *);

/**
 转发socket
 */
@property (strong, nonatomic) GCDAsyncSocket * relaySocket;

@end

@implementation WZZHttpScoopTask

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket
                         queue:(dispatch_queue_t)queue
                      complete:(void (^)(WZZHttpScoopTask * _Nonnull))complete {
    self = [super init];
    if (self) {
        self.completeBlock = complete;
        self.socket = socket;
        [self.socket setDelegate:self delegateQueue:queue];
    }
    return self;
}

//开始任务
- (void)start {
    WZZHttpScoopTask_Log(@"读取请求");
    [self.socket readDataWithTimeout:WZZHttpScoopTask_TimeOut tag:WZZHttpScoopTask_Tag_Request];
}

//MARK:转发请求
- (void)relayRequest {
    if (self.handleRequestOK) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.handleRequestOK(self);
        });
    }
    WZZHttpScoopTask_Log(@"准备转发请求");
    
    dispatch_queue_t queue = dispatch_queue_create("WZZHttpScoopTask", DISPATCH_QUEUE_CONCURRENT);
    self.relaySocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:queue];
    NSError * err;
    NSDictionary * dic = [self getHostPartWithUrl:self.request.url];
    [self.relaySocket connectToHost:dic[@"host"] onPort:[dic[@"port"] integerValue] error:&err];
    if (err) {
        WZZHttpScoopTask_Log(@"转发socket连接错误:\n%@", err);
        return;
    }
    WZZHttpScoopTask_Log(@"转发socket连接服务器:\n%@", dic);
}

//MARK:转发响应
- (void)relayResponse {
    WZZHttpScoopTask_Log(@"断开转发socket连接");
    [self.relaySocket disconnect];
    //返回响应成功
    if (self.handleResponseOK) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.handleResponseOK(self);
        });
    }
    WZZHttpScoopTask_Log(@"准备返回响应");
    WZZHttpScoopTask_Log(@"写入响应数据");
    WZZHttpScoopTask_Log(@"%@", [self.response toString]);
    [self.socket writeData:[self.response makeResponse] withTimeout:WZZHttpScoopTask_TimeOut tag:WZZHttpScoopTask_Tag_Response];
}

- (NSDictionary *)getHostPartWithUrl:(NSString *)url {
    if ([url containsString:@"://"]) {
        NSRange range = [url rangeOfString:@"://"];
        if (url.length > range.location+range.length) {
            url = [url substringFromIndex:range.location+range.length];
        }
    }
    url = [[url componentsSeparatedByString:@"http://"] componentsJoinedByString:@""];
    url = [url componentsSeparatedByString:@"?"].firstObject;
    NSString * hostPort = [url componentsSeparatedByString:@"/"].firstObject;
    NSArray * hostPortArr = [hostPort componentsSeparatedByString:@":"];
    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
    dic[@"host"] = hostPortArr.firstObject;
    dic[@"port"] = hostPortArr.lastObject?hostPortArr.lastObject:@"80";
    return dic;
}

//收到socket数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    if (tag == WZZHttpScoopTask_Tag_Request) {
        //处理请求
        self.request = [WZZHttpScoopRequestModel modelWithRequestData:data];
        WZZHttpScoopTask_Log(@"处理请求");
        WZZHttpScoopTask_Log(@"%@", [self.request toString]);
        
        //转发请求
        [self relayRequest];
    } else if (tag == WZZHttpScoopTask_Tag_ReResponse) {
        //得到转发响应
        WZZHttpScoopResponseModel * resp = [WZZHttpScoopResponseModel modelWithResponseData:data];
        self.response = resp;
        WZZHttpScoopTask_Log(@"收到转发响应");
        WZZHttpScoopTask_Log(@"%@", [resp toString]);
        [self relayResponse];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    if (tag == WZZHttpScoopTask_Tag_ReRequest) {
        WZZHttpScoopTask_Log(@"转发socket成功，等待响应");
        //等待回应
        [self.relaySocket readDataWithTimeout:WZZHttpScoopTask_TimeOut tag:WZZHttpScoopTask_Tag_ReResponse];
    } else if (tag == WZZHttpScoopTask_Tag_Response) {
        WZZHttpScoopTask_Log(@"返回响应成功");
        WZZHttpScoopTask_Log(@"断开连接");
        [self.socket disconnect];
        if (self.completeBlock) {
            self.completeBlock(self);
        }
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (sock == self.relaySocket) {
        WZZHttpScoopTask_Log(@"转发socket连接错误:\n%@", err);
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    if (sock == self.relaySocket) {
        WZZHttpScoopTask_Log(@"转发socket连接成功");
        WZZHttpScoopTask_Log(@"写转发数据");
        WZZHttpScoopTask_Log(@"%@", [self.request toString]);
        //写数据
        [self.relaySocket writeData:[self.request makeRequest] withTimeout:WZZHttpScoopTask_TimeOut tag:WZZHttpScoopTask_Tag_ReRequest];
    }
}

@end

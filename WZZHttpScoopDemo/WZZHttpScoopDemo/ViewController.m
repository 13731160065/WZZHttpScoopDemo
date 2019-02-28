//
//  ViewController.m
//  WZZHttpScoopDemo
//
//  Created by mac on 2019/2/28.
//  Copyright © 2019 wzz. All rights reserved.
//

#import "ViewController.h"
#import "WZZHttpScoop.h"
#import <CoreLocation/CoreLocation.h>
#import "TextViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    CLLocationManager * appleLocationManager;
}

@property (weak, nonatomic) IBOutlet UITableView *mainTableView;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextView *msgTV;

@property (strong, nonatomic) WZZHttpScoop * sever;

@property (strong, nonatomic) dispatch_source_t badgeTimer;

/**
 数据
 */
@property (strong, nonatomic) NSMutableArray * dataArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.portTF.keyboardType = UIKeyboardTypeNumberPad;
    
    self.dataArr = [NSMutableArray array];
    appleLocationManager = [[CLLocationManager alloc] init];
    appleLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    [appleLocationManager startUpdatingLocation];
    [self.mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    [self getAuth];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)getAuth {
    [appleLocationManager requestAlwaysAuthorization];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        appleLocationManager.allowsBackgroundLocationUpdates = YES;
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self getAuth];
        });
    }
}

- (void)sendMsg:(id)msg {
    if (self.msgTV.text.length) {
        self.msgTV.text = [NSString stringWithFormat:@"%@\n%@", self.msgTV.text, msg];
    } else {
        self.msgTV.text = [NSString stringWithFormat:@"%@", msg];
    }
    [self.msgTV scrollRectToVisible:CGRectMake(0, 0, 0, self.msgTV.contentSize.height) animated:YES];
}

- (IBAction)okClick:(id)sender {
    if (!_portTF.text.length) {
        [self sendMsg:@"请输入端口号"];
        return;
    }
    
    __weak ViewController * weakSelf = self;
    self.sever = [WZZHttpScoop shareInstance];
    self.sever.handleRequestOK = ^(WZZHttpScoopTask * _Nonnull aTask) {
        WZZHttpScoopRequestModel * model = aTask.request;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf sendMsg:[model toString]];
        });
    };
    self.sever.handleResponseOK = ^(WZZHttpScoopTask * _Nonnull aTask) {
        WZZHttpScoopResponseModel * model = aTask.response;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf sendMsg:[model toString]];
            [weakSelf.dataArr addObject:aTask];
            [weakSelf.mainTableView reloadData];
        });
    };
    NSError * err = [self.sever startWithPort:self.portTF.text.intValue];
    if (err) {
        [self sendMsg:err];
    }
    [self sendMsg:[self.sever IP]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    WZZHttpScoopTask * task = self.dataArr[indexPath.row];
    cell.textLabel.text = task.request.url;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.numberOfLines = 0;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WZZHttpScoopTask * task = self.dataArr[indexPath.row];
    TextViewController * vc = [[TextViewController alloc] init];
    vc.str = [@">>>>请求<<<<\n" stringByAppendingFormat:@"%@", [[task.request toString] stringByAppendingFormat:@"\n\n>>>>响应<<<<\n%@", [task.response toString]]];
    [self presentViewController:vc animated:YES completion:nil];
}

@end

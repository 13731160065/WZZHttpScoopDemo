//
//  TextViewController.m
//  WZZHttpScoopDemo
//
//  Created by mac on 2019/2/28.
//  Copyright © 2019 wzz. All rights reserved.
//

#import "TextViewController.h"

@interface TextViewController ()

@property (strong, nonatomic) IBOutlet UITextView * mainTV;

@end

@implementation TextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mainTV.text = self.str;
}

- (IBAction)backClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

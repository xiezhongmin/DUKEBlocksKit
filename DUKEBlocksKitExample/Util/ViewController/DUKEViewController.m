//
//  ViewController.m
//  DUKEBlocksKitExample
//
//  Copyright © 2016年 请叫我杜克. All rights reserved.
//

#import "DUKEViewController.h"
#import "DUKEBlocksKit.h"
#import "DUKEExample1ViewController.h"
#import "DUKEExample2ViewController.h"

@interface DUKEViewController ()
@property (nonatomic, strong) UIActionSheet *sheet;
@property (nonatomic, weak) UIButton *exampleBtn;
@end

@implementation DUKEViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"DUKEBlocksKitExample";
    
    [self exampleBtn];
    
    NSDictionary *exampleMap = @{
                                 @"Example1" : @"blocksKitDelegateExample",
                                 @"Example2" : @"blocksKitObservationExample",
                                 };
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"DUKEBlocksKitExample" delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"Example1",@"Example2",nil];
    
    [sheet duke_mapSelector:@selector(actionSheet:clickedButtonAtIndex:) usingBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
        NSString *exampleKey = [actionSheet buttonTitleAtIndex:buttonIndex];
        NSString *methodName = [exampleMap objectForKey:exampleKey];
        if (methodName) {
            SEL exampleSEL = NSSelectorFromString(methodName);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:exampleSEL];
#pragma clang diagnostic pop
        }
    }];
    
    [sheet duke_beginDynamicDelegate];
    [sheet showInView:self.view];
    _sheet = sheet;
}

- (void)blocksKitDelegateExample {
    [self.navigationController pushViewController:[[DUKEExample1ViewController alloc] init] animated:YES];
}

- (void)blocksKitObservationExample {
    [self.navigationController pushViewController:[[DUKEExample2ViewController alloc] init] animated:YES];
}

- (UIButton *)exampleBtn {
    if (_exampleBtn == nil) {
        UIButton *exampleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat width = 200;
        CGFloat height = 30;
        CGFloat x = self.view.frame.size.width * 0.5 - width * 0.5;
        CGFloat y = self.view.frame.size.height * 0.5;
        exampleBtn.frame = CGRectMake(x, y, width, height);
        [exampleBtn setTitle:@"showExampleSheet" forState:UIControlStateNormal];
        [exampleBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        // UIControl+DUKEBlocksKit
        [exampleBtn duke_addTouchUpInside:^(id sender) {
            [_sheet showInView:self.view];
        }];
        [self.view addSubview:exampleBtn];
        _exampleBtn = exampleBtn;
    }
    return _exampleBtn;
}
@end

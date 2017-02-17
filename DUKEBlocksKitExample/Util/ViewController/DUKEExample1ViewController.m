//
//  DUKEExample1ViewController.m
//  DUKEBlocksKitExample
//
//  Copyright © 2016年 请叫我杜克. All rights reserved.
//

#import "DUKEExample1ViewController.h"
#import "DUKEExample1TableViewCell.h"
#import "DUKEExample1Model.h"
#import "DUKEBlocksKit.h"

@interface DUKEExample1ViewController () <UITableViewDataSource, UITableViewDelegate>
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
@implementation DUKEExample1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // setUpTableView
    self.title = @"DUKEDelegateExample";
    [self setupTableView];
}

- (void)setupTableView {
    UITableView *tableView = [[UITableView alloc] init];
    tableView.frame = self.view.frame;
    
    [tableView duke_mapSelector:@selector(tableView:numberOfRowsInSection:) usingBlock:^(UITableView *tableView, NSInteger section) {
        return 20;
    }];
    
    [tableView duke_mapSelector:@selector(tableView:cellForRowAtIndexPath:) usingBlock:^(UITableView *tableView, NSIndexPath *indexPath) {
        DUKEExample1TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DUKEExample1TableViewCell"];
        if (cell == nil) {
            cell = [[NSBundle mainBundle] loadNibNamed:@"DUKEExample1TableViewCell" owner:nil options:nil].firstObject;
        }
        DUKEExample1Model *model = [[DUKEExample1Model alloc] initWithName:[NSString stringWithFormat:@"请叫我杜克 - %zd", indexPath.row] icon:@"icon" html:@"https://github.com/xiezhongmin"];
        [cell configureCellWithModel:model];
        return cell;
    }];
    
    [tableView duke_mapSelector:@selector(tableView:heightForRowAtIndexPath:) usingBlock:^CGFloat(UITableView *tableView, NSIndexPath *indexPath) {
        return 80;
    }];
    
    [tableView duke_beginDynamicDelegate];
    [self.view addSubview:tableView];
}
#pragma clang diagnostic pop
@end


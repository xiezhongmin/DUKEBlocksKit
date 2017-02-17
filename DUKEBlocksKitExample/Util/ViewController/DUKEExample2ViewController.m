//
//  DUKEExample2ViewController.m
//  DUKEBlocksKitExample
//
//  Copyright © 2016年 请叫我杜克. All rights reserved.
//

#import "DUKEExample2ViewController.h"
#import "DUKEBlocksKit.h"

@interface Message : NSObject
@property (nonatomic, copy) NSString *text;
@end

@implementation Message
@end

@interface DUKEExample2ViewController ()
@property (nonatomic, weak) IBOutlet UITextField *textfield;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic, strong) Message *message;
@end

@implementation DUKEExample2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"DUKEObservationExample";
    DUKE(self.textfield, text) = DUKEObserve(self.message, text);
}

- (IBAction)changeMessage:(id)sender
{
    NSArray *msgs = @[@"Hello World!", @"Objective C", @"Swift", @"DUKEBlocksKit", @"https://github.com/xiezhongmin", @"XZMTabbarExtension", @"XZMRefresh"];
    NSUInteger index = arc4random_uniform((u_int32_t)msgs.count);
    self.message.text = msgs[index];
}

- (Message *)message {
    if (_message == nil) {
        _message = [Message new];
    }
    return _message;
}
@end

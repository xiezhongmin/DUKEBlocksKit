//
//  DUKEExample1Model.m
//  DUKEBlocksKitExample
//
//  Copyright © 2016年 请叫我杜克. All rights reserved.
//

#import "DUKEExample1Model.h"

@implementation DUKEExample1Model
- (instancetype)initWithName:(NSString *)name icon:(NSString *)icon html:(NSString *)html {
    self = [super init];
    if (self) {
        _name = name;
        _icon = icon;
        _html = html;
    }
    return self;
}
@end

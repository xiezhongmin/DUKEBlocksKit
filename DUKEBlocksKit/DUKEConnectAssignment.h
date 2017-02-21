//
//  DUKEConnectAssignment.h
//  DUKEBlocksKit
//
//  Created by 请叫我杜克 on 16/12/14.
//  Copyright © 2016年 com.xiezhongmin.new. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "metamacros.h"

@class DUKEObserver;

#define DUKE(TARGET, ...) \
metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) (DUKE_(TARGET, __VA_ARGS__, nil)) (DUKE_(TARGET, __VA_ARGS__))

#define DUKE_(TARGET, KEYPATH, NILVALUE) \
[[DUKEConnectAssignment alloc] initWithTarget:(TARGET) nilValue:(NILVALUE)][@keypath(TARGET, KEYPATH)]

@interface DUKEConnectAssignment : NSObject
- (id)initWithTarget:(id)target nilValue:(id)nilValue;
- (void)setObject:(DUKEObserver *)observer forKeyedSubscript:(NSString *)keyPath;
@end

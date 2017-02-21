//
//  DUKEAgentBlockKit.h
//  Created by 请叫我杜克 on 16/11/15.
//  Copyright © 2016年 com.xiezhongmin.new. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSObject (BlockDelegate)
- (void)duke_mapSelector:(SEL)aSelector usingBlock:(id)block;
- (BOOL)duke_beginDynamicDelegate;
@end

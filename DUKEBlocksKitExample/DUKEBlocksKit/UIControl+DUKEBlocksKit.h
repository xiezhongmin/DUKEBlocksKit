//
//  UIControl+DUKEBlocksKit.h
//  DUKEBlocksKit
//
//  Created by 请叫我杜克 on 16/12/16.
//  Copyright © 2016年 com.xiezhongmin.new. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIControl (DUKEBlocksKit)
- (void)duke_addTouchDown:(void (^)(id sender))eventHandler;
- (void)duke_addTouchDownRepeat:(void (^)(id sender))eventHandler;
- (void)duke_addTouchDragInside:(void (^)(id sender))eventHandler;
- (void)duke_addTouchDragOutside:(void (^)(id sender))eventHandler;
- (void)duke_addTouchDragEnter:(void (^)(id sender))eventHandler;
- (void)duke_addTouchDragExit:(void (^)(id sender))eventHandler;
- (void)duke_addTouchUpInside:(void (^)(id sender))eventHandler;
- (void)duke_addTouchUpOutside:(void (^)(id sender))eventHandler;
- (void)duke_addTouchCancel:(void (^)(id sender))eventHandler;
- (void)duke_addValueChanged:(void (^)(id sender))eventHandler;
- (void)duke_addEditingDidBegin:(void (^)(id sender))eventHandler;
- (void)duke_addEditingChanged:(void (^)(id sender))eventHandler;
- (void)duke_addEditingDidEnd:(void (^)(id sender))eventHandler;
- (void)duke_addEditingDidEndOnExit:(void (^)(id sender))eventHandler;
// Events
- (void)duke_addEventHandler:(void (^)(id sender))eventHandler forControlEvents:(UIControlEvents)controlEvents;
- (void)duke_removeEventHandlersforControlEvents:(UIControlEvents)controlEvents;
@end

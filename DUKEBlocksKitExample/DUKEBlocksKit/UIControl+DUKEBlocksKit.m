//
//  UIControl+DUKEBlocksKit.m
//  DUKEBlocksKit
//
//  Created by 请叫我杜克 on 16/12/16.
//  Copyright © 2016年 com.xiezhongmin.new. All rights reserved.
//

#import "UIControl+DUKEBlocksKit.h"
#import "metamacros.h"
@import ObjectiveC.runtime;

@interface DUKEControlWrapper : NSObject
@property (nonatomic, copy) void (^handler)(id);
@property (nonatomic, assign) UIControlEvents controlEvents;

- (instancetype)initWithHandler:(void (^)(id sender))handler forControlEvents:(UIControlEvents)controlEvents;
- (void)invoke:(id)sender;
@end

@implementation DUKEControlWrapper
- (instancetype)initWithHandler:(void (^)(id sender))handler forControlEvents:(UIControlEvents)controlEvents {
    self = [super init];
    if (self) {
        _handler = [handler copy];
        _controlEvents = controlEvents;
    }
    return self;
}

- (void)invoke:(id)sender {
    if (self.handler) {
        self.handler(sender);
    }
}
@end

#define DUKECONTROL_EVENT(methodName, eventName) \
- (void)duke_##methodName:(void (^)(id sender))eventHandler { \
    [self duke_addEventHandler:eventHandler forControlEvents:UIControlEvent##eventName]; \
}
static void * DUKEControlEventBlockKey = &DUKEControlEventBlockKey;
@implementation UIControl (DUKEBlocksKit)
DUKECONTROL_EVENT(addTouchDown, TouchDown)
DUKECONTROL_EVENT(addTouchDownRepeat, TouchDownRepeat)
DUKECONTROL_EVENT(addTouchDragInside, TouchDragInside)
DUKECONTROL_EVENT(addTouchDragOutside, TouchDragOutside)
DUKECONTROL_EVENT(addTouchDragEnter, TouchDragEnter)
DUKECONTROL_EVENT(addTouchDragExit, TouchDragExit)
DUKECONTROL_EVENT(addTouchUpInside, TouchUpInside)
DUKECONTROL_EVENT(addTouchUpOutside, TouchUpOutside)
DUKECONTROL_EVENT(addTouchCancel, TouchCancel)
DUKECONTROL_EVENT(addValueChanged, ValueChanged)
DUKECONTROL_EVENT(addEditingDidBegin, EditingDidBegin)
DUKECONTROL_EVENT(addEditingChanged, EditingChanged)
DUKECONTROL_EVENT(addEditingDidEnd, EditingDidEnd)
DUKECONTROL_EVENT(addEditingDidEndOnExit, EditingDidEndOnExit)

- (void)duke_addEventHandler:(void (^)(id sender))eventHandler forControlEvents:(UIControlEvents)controlEvents {
    DUKEParameterAssert(eventHandler);
    
    NSMutableArray *wrappers = [self duke_controlWrappersArray];
    
    DUKEControlWrapper *target = [[DUKEControlWrapper alloc] initWithHandler:eventHandler forControlEvents:controlEvents];
    
    [wrappers addObject:target];
    
    [self addTarget:target action:@selector(invoke:) forControlEvents:controlEvents];
}

- (void)duke_removeEventHandlersforControlEvents:(UIControlEvents)controlEvents {
    DUKEParameterAssert(controlEvents);
    
    NSMutableArray *wrappers = [self duke_controlWrappersArray];
    
    if (!wrappers.count) {
        return;
    }
    
    NSMutableArray *removeTargets = [NSMutableArray arrayWithCapacity:wrappers.count];
    [wrappers enumerateObjectsUsingBlock:^(DUKEControlWrapper *target, NSUInteger idx, BOOL * _Nonnull stop) {
        if (target.controlEvents == controlEvents) {
            [self removeTarget:target action:@selector(invoke:) forControlEvents:controlEvents];
            [removeTargets addObject:target];
        }
    }];
    
    [wrappers removeObjectsInArray:removeTargets];
}

- (NSMutableArray *)duke_controlWrappersArray {
    NSMutableArray *wrappers = objc_getAssociatedObject(self, DUKEControlEventBlockKey);
    
    if (!wrappers) {
        wrappers = [NSMutableArray array];
        objc_setAssociatedObject(self, DUKEControlEventBlockKey, wrappers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return wrappers;
}
@end

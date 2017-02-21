//
//  DUKEConnectAssignment.m
//  DUKEBlocksKit
//
//  Created by 请叫我杜克 on 16/12/14.
//  Copyright © 2016年 com.xiezhongmin.new. All rights reserved.
//

#import "DUKEConnectAssignment.h"
#import "NSObject+DUKEBlockObservation.h"

@interface DUKEConnectAssignment()
// The object to bind to.
@property (nonatomic, strong, readonly) id target;

// A value to use when `nil` is sent on the bound signal.
@property (nonatomic, strong, readonly) id nilValue;
@end

@implementation DUKEConnectAssignment

- (id)initWithTarget:(id)target nilValue:(id)nilValue {
    // This is often a programmer error, but this prevents crashes if the target
    // object has unexpectedly deallocated.
    if (target == nil) return nil;
    
    self = [super init];
    if (self == nil) return nil;
    
    _target = target;
    _nilValue = nilValue;
    
    return self;
}

- (void)setObject:(DUKEObserver *)observer forKeyedSubscript:(NSString *)keyPath {
    DUKEParameterAssert(observer);
    DUKEParameterAssert(keyPath.length);
    
    SEL startObservingSEL = sel_registerName("startObservingWithOptions:");
    
    if ([observer respondsToSelector:startObservingSEL]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [observer performSelector:startObservingSEL withObject:@(NSKeyValueObservingOptionNew)];
#pragma clang diagnostic pop
    };
    
    __block void * volatile objectPtr = (__bridge void *)_target;
    
    void (^callback)(id, NSString *, NSDictionary *) = [observer valueForKey:@"callback"];
    
    if (callback) {
        return;
    }
    
    callback = ^(id obj, NSString *keyPath, id newValue) {
        
        __strong NSObject *object __attribute__((objc_precise_lifetime)) = (__bridge __strong id)objectPtr;
        
        [object setValue:newValue ?: _nilValue forKey:keyPath];
    };
    
    [observer setValue:callback forKey:@"callback"];
}
@end

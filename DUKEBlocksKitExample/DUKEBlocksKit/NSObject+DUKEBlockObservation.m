//
//  NSObject+DUKEBlockObservation.m
//  DUKEBlocksKit
//
//  Created by 请叫我杜克 on 16/12/14.
//  Copyright © 2016年 com.xiezhongmin.new. All rights reserved.
//

#import "NSObject+DUKEBlockObservation.h"
@import ObjectiveC.runtime;
@import ObjectiveC.message;

typedef NS_ENUM(NSUInteger, DUKEObserverContext) {
    DUKEObserverContextNormal,
    DUKEObserverContextOptions
};

@interface DUKEObserver ()
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, unsafe_unretained) NSObject *observer;
@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, copy) void (^handler)(id obj, NSDictionary *change);
@property (nonatomic, copy) void (^callback)(id obj, NSString *keyPath, id newValue) ;
@property (nonatomic, copy) id (^mapBlock)(id value);
@property (nonatomic, copy, readwrite) NSString *token;
- (instancetype)initWithObserver:(id)observer keyPath:(NSString *)keyPath;
@end

@implementation DUKEObserver
- (instancetype)initWithObserver:(id)observer keyPath:(NSString *)keyPath {
    self = [super init];
    if (self) {
        _observer = observer;
        _keyPath = keyPath;
        _token = [[NSProcessInfo processInfo] globallyUniqueString];
    }
    return self;
}

- (void)startObservingWithOptions:(NSKeyValueObservingOptions)options {
    @synchronized(self) {
        if (_isObserving) return;
        
        [self.observer addObserver:self forKeyPath:self.keyPath options:options context:NULL];
        
        _isObserving = YES;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    @synchronized (self) {
        if (self.handler) {
            self.handler(object, change);
        } else if (self.callback) {
            id newValue = nil;
            if (self.mapBlock) {
                newValue = self.mapBlock([change objectForKey:@"new"]);
            } else {
                newValue = [change objectForKey:@"new"];
            }
            self.callback(object, keyPath, newValue);
        }
    }
}

- (NSString *)duke_addHandler:(void (^)(id obj, NSDictionary *change))block {
    return [self duke_addHandler:block forOptions:NSKeyValueObservingOptionNew];
}

- (NSString *)duke_addHandler:(void (^)(id obj, NSDictionary *change))block forOptions:(NSKeyValueObservingOptions)options {
    DUKEParameterAssert(block);
    DUKEParameterAssert(options);
    
    if (_isObserving) {
        return self.token;
    }
    
    self.handler = [block copy];
    
    [self startObservingWithOptions:options];
    
    return self.token;
}

- (DUKEObserver *)duke_map:(id (^)(id value))block {
    DUKEParameterAssert(block);
    
   __block DUKEObserver *result = self;
    
    if (result.isObserving) {
        return result;
    }
    
    self.mapBlock = ^(id value) {
        return block(value);
    };
    
    return result;
}

- (void)_stopObservingLocked
{
    if (!_isObserving) return;
    
    [_observer removeObserver:self forKeyPath:_keyPath context:nil];
    _keyPath     = nil;
    _observer    = nil;
    _token       = nil;
    _handler     = nil;
    _isObserving = NO;
}

- (void)stopObserving
{
    if (_observer == nil) return;
    
    @synchronized (self) {
        [self _stopObservingLocked];
    }
}

- (void)dealloc
{
    if (self.keyPath) {
        [self _stopObservingLocked];
    }
}
@end

@implementation NSObject (DUKEBlockObservation)
static void _duke_modifySwizzledClasses(void (^block)(NSMutableSet *swizzledClasses)) {
    static NSMutableSet *swizzledClasses;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        swizzledClasses = [NSMutableSet new];
    });
    @synchronized(swizzledClasses) {
        block(swizzledClasses);
    }
}

static void duke_swizzleClassDealloc(Class class) {
    DUKEParameterAssert(class);
    
    SEL deallocSEL = sel_registerName("dealloc");
    
    __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
    
    id swizzleDealloc = ^(__unsafe_unretained id object) {
        [object duke_removeAllObservers];
        
        if (originalDealloc == NULL) {
            struct objc_super superclazz = {
                .receiver = object,
                .super_class = class_getSuperclass(class)
            };
            
            // cast our pointer so the compiler won't complain
            void (*objc_msgSendSuperCasted)(void *, SEL) = (void *)objc_msgSendSuper;
            
            objc_msgSendSuperCasted(&superclazz, deallocSEL);
        } else {
            originalDealloc(object, deallocSEL);
        }
    };
    
    IMP swizzleDeallocIMP = imp_implementationWithBlock(swizzleDealloc);
    
    if (!class_addMethod(class, deallocSEL, swizzleDeallocIMP, "v@:")) {
        Method deallocMethod = class_getInstanceMethod(class, deallocSEL);
        
        originalDealloc = (void(*)(__unsafe_unretained id, SEL))method_getImplementation(deallocMethod);
        
        originalDealloc = (void(*)(__unsafe_unretained id, SEL))method_setImplementation(deallocMethod, swizzleDeallocIMP);
    }
}

static void duke_swizzleClassInPlace(Class class) {
    NSString *className = NSStringFromClass(class);
    _duke_modifySwizzledClasses(^(NSMutableSet *swizzledClasses) {
        if (![swizzledClasses containsObject:className]) {
            duke_swizzleClassDealloc(class);
            [swizzledClasses addObject:className];
        }
    });
}


- (DUKEObserver *)duke_observerForKeyPath:(NSString *)keyPath {
    DUKEParameterAssert(keyPath.length);
    
    NSMutableDictionary *_map;
    
    DUKEObserver *observer = [[DUKEObserver alloc] initWithObserver:self keyPath:keyPath];
    
    Class clazz = self.class;
    duke_swizzleClassInPlace(clazz);
    
    @synchronized(observer) {
        _map = [self duke_associatedObserverMap];
        
        if (_map == nil) {
            _map = [NSMutableDictionary dictionary];
            [self duke_setAssociatedObserverMap:_map];
        }
    }
    
    NSString *identifier = observer.token;
    _map[identifier] = observer;
    
    return observer;
}

- (void)duke_removeObserverWithToken:(NSString *)token {
    DUKEParameterAssert(token);
    
    NSMutableDictionary *_map;
    
    @synchronized (self) {
        _map = [self duke_associatedObserverMap];
        if (!_map) return;
    }
    
    if (![_map.allKeys containsObject:token]) {
        DUKEParameterAssert(token);
        return;
    }
    
    DUKEObserver *observer = [_map objectForKey:token];
    [observer stopObserving];
    
    [_map removeObjectForKey:token];
    
    if (_map.count == 0) [self duke_setAssociatedObserverMap:nil];
}

- (void)duke_removeAllObservers {
    
    NSDictionary *_map;
    
    @synchronized (self) {
        _map = [self duke_associatedObserverMap];
        [self duke_setAssociatedObserverMap:nil];
    }
    
    for (DUKEObserver *observer in _map.allValues) {
        [observer stopObserving];
    }
}

- (void)duke_setAssociatedObserverMap:(NSMutableDictionary *)dict {
    objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)duke_associatedObserverMap {
    return objc_getAssociatedObject(self, @selector(duke_setAssociatedObserverMap:));
}

@end

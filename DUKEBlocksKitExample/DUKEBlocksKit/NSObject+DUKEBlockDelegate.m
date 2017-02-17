//
//  DUKEAgentBlockKit.m
//
//  Created by 请叫我杜克 on 16/11/15.
//  Copyright © 2016年 com.xiezhongmin.new. All rights reserved.
//

#import "NSObject+DUKEBlockDelegate.h"
#import <pthread.h>
#import "metamacros.h"

@import ObjectiveC.message;
@import ObjectiveC.runtime;

typedef NS_OPTIONS(int, DukeBlockFlags) {
    DukeBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    DukeBlockFlagsHasSignature          = (1 << 30)
};

typedef struct DukeBlock {
    __unused Class isa;
    DukeBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct DukeBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        // requires BKBlockFlagsHasCopyDisposeHelpers
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        // requires BKBlockFlagsHasSignature
        const char *signature;
        const char *layout;
    } *descriptor;
    // imported variables
} *DukeBlockRef;
@interface DukeIdentifier : NSObject
+ (instancetype)identifierWithSelector:(SEL)selector object:(id)object block:(id)block;
- (void)update:(SEL)selector block:(id)block;
- (BOOL)invoke:(NSInvocation *)invocation;
@property (nonatomic, weak) id object;
@property (nonatomic, strong) id block;
@property (nonatomic, strong) id dynamicDelegate;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) Class dynamicDelegateClass;
@property (nonatomic, strong) Protocol *protocol;
@property (nonatomic, strong) NSMutableSet *methodsList;
@property (nonatomic, strong) NSMethodSignature *blockSignature;
@property (nonatomic, strong) NSMethodSignature *methodSignature;
@property (nonatomic, strong) NSMutableDictionary *methodsBlockMap;
@property (nonatomic, strong) NSMutableDictionary *methodSignatureMap;
@property (nonatomic, strong) NSMutableDictionary *blockSignatureMap;
@end

typedef struct {
    DukeIdentifier *__unsafe_unretained identifier;
    NSObject       *__unsafe_unretained obj;
} DukeClassIdentifier;
static  DukeClassIdentifier *allClassIdentifiers = NULL;
static pthread_mutex_t agentSelectorLock = PTHREAD_MUTEX_INITIALIZER;
static  size_t classIdentifierCount = 0, classIdentifierCapacity = 0;
static  NSString *const DUKEClassIdentifiersKey         = @"DUKEClassIdentifiersKey";
static  NSString *const DUKESubclassSuffix              = @"_DUKE_";
@implementation NSObject (BlockDelegate)
- (void)duke_mapSelector:(SEL)aSelector usingBlock:(id)block {
    DUKEParameterAssert(aSelector);
    DUKEParameterAssert(block);
    if (duke_isNSObjectAllowDelegating(self, aSelector)) {
        pthread_mutex_lock(&agentSelectorLock);
        if (classIdentifierCount >= classIdentifierCapacity) {
            size_t newCapacity = 0;
            if (classIdentifierCount == 0) {
                newCapacity = 1;
            } else {
                newCapacity = classIdentifierCapacity << 1;
            }
            allClassIdentifiers = realloc(allClassIdentifiers, sizeof(*allClassIdentifiers) * newCapacity);
            classIdentifierCapacity = newCapacity;
        }
        DukeIdentifier *identifier = duke_prepareIdentifier(self, aSelector, block);
        allClassIdentifiers[classIdentifierCount] = (DukeClassIdentifier){
            .identifier = identifier,
            .obj        = self,
        };
        duke_prepareDelegatingSelector(self, aSelector);
        classIdentifierCount++;
        pthread_mutex_unlock(&agentSelectorLock);
    }
}

- (BOOL)duke_beginDynamicDelegate {
    NSMutableArray *identifierArr = [NSMutableArray arrayWithCapacity:classIdentifierCount];
    
    for (size_t index = 0; index < classIdentifierCount; ++index) {
        if (allClassIdentifiers[index].obj == self) {
            DukeIdentifier *identifier = allClassIdentifiers[index].identifier;
            if (![identifierArr containsObject:identifier]) {
                [identifierArr addObject:identifier];
            }
        }
    }
    
    if (!identifierArr.count) {
        duke_free();
        return NO;
    }
    
    __block BOOL _isDelegating = NO;
    __weak typeof(self) weakSelf = self;
    [identifierArr enumerateObjectsUsingBlock:^(DukeIdentifier *identifier, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSObject *dynamicDelegate = identifier.dynamicDelegate;
        NSString *protocolNamed = NSStringFromProtocol(identifier.protocol);
        if ([strongSelf respondsToSelector:@selector(setDelegate:)] && [protocolNamed hasSuffix:@"Delegate"]) {
            [strongSelf performSelector:@selector(setDelegate:) withObject:dynamicDelegate];
            _isDelegating = YES;
        } else if ([strongSelf respondsToSelector:@selector(setDataSource:)] && [protocolNamed hasSuffix:@"DataSource"]) {
            [strongSelf performSelector:@selector(setDataSource:) withObject:dynamicDelegate];
            _isDelegating = YES;
        }
    }];
    
    duke_free();
    
    return _isDelegating;
}

static void duke_free() {
    if (allClassIdentifiers != NULL) {
        free(allClassIdentifiers);
        classIdentifierCount = 0, classIdentifierCapacity = 0;
        allClassIdentifiers = NULL;
    }
}

static DukeIdentifier *duke_prepareIdentifier(NSObject *self, SEL selector, id block) {
    Protocol *protocol = duke_classInProtocolByDelegating([self class], selector);
    SEL protocolSelector = NSSelectorFromString(NSStringFromProtocol(protocol));
    DukeIdentifier *identifier = objc_getAssociatedObject(self, protocolSelector);
    if (!identifier) {
        identifier = [DukeIdentifier identifierWithSelector:selector object:self block:block];
        objc_setAssociatedObject(self, protocolSelector, identifier, OBJC_ASSOCIATION_RETAIN);
    } else {
        [identifier update:selector block:block];
    }
    return identifier;
}

static BOOL duke_isNSObjectAllowDelegating(NSObject *self, SEL selector) {
    Protocol * protocol = duke_classInProtocolByDelegating([self class], selector);
    if (!protocol) {
        DUKEParameterAssert(protocol);
        return NO;
    }
    
    if ([self respondsToSelector:@selector(setDelegate:)]) {
        return YES;
    } else if ([self respondsToSelector:@selector(setDataSource:)]) {
        return YES;
    }
    return NO;
}

static BOOL duke_protocolContainSelector(Protocol *p, SEL selector) {
    if (!p) return NO;
    
    unsigned int r_outCount;
    unsigned int o_outCount;
    struct objc_method_description *requiredMethods = protocol_copyMethodDescriptionList(p, YES, YES, &r_outCount);
    struct objc_method_description *optionalMethods = protocol_copyMethodDescriptionList(p, NO, YES,  &o_outCount);
    if (!requiredMethods && !optionalMethods) return NO;
    struct objc_method_description required_method_description;
    struct objc_method_description optional_method_description;
    for (int i = 0, outCount = MAX(r_outCount, o_outCount); i < outCount; i++) {
        if (requiredMethods) required_method_description = requiredMethods[MIN(i, r_outCount)];
        if (optionalMethods) optional_method_description = optionalMethods[MIN(i, o_outCount)];
        else return NO;
        if (required_method_description.name == selector || optional_method_description.name == selector) {
            return YES;
        }
    }
    return NO;
}

static Protocol *duke_classInProtocolByDelegating(Class class, SEL selector) {
    DUKEParameterAssert(class);
    DUKEParameterAssert(selector);
    Protocol *pro_dataSource = duke_classInProtocolBySelector(class, @"DataSource", selector);
    if (pro_dataSource) return pro_dataSource;
    Protocol *pro_delegate = duke_classInProtocolBySelector(class, @"Delegate", selector);
    if (pro_delegate) return pro_delegate;
    return nil;
}

static Protocol *duke_classInProtocolBySelector(Class cls, NSString *suffix, SEL selector) {
    Class _cls = cls;
    while (_cls) {
        NSString *className = NSStringFromClass(_cls);
        NSString *protocolName = [className stringByAppendingString:suffix];
        Protocol *protocol = objc_getProtocol(protocolName.UTF8String);
        if (protocol && duke_protocolContainSelector(protocol, selector))
            return protocol;
        _cls = class_getSuperclass(_cls);
    }
    return nil;
}

static void duke_prepareDelegatingSelector(NSObject *self, SEL selector) {
    DUKEParameterAssert(selector);
    Class dynamicDelegateClass = duke_prepareDynamicDelegateClass(self, [self class], selector);
    if (!dynamicDelegateClass) {
        DUKEParameterAssert(dynamicDelegateClass);
        return;
    }
    
    Protocol *protocol = duke_classInProtocolByDelegating([self class], selector);
    NSString *protocolNamed = NSStringFromProtocol(protocol);
    SEL protocolSelector = NSSelectorFromString(protocolNamed);
    DukeIdentifier *identifier = objc_getAssociatedObject(self, protocolSelector);
    if (identifier) {
        if (!identifier.dynamicDelegate) {
            NSObject *dynamicDelegate = [[dynamicDelegateClass alloc] init];
            [dynamicDelegate setValue:identifier forKey:@"identifier"];
            identifier.dynamicDelegate = dynamicDelegate;
        }
    } else {
        NSLog(@"identifier is nil");
    }
}

static BOOL duke_dynamicDelegateClassAddIvar(Class class, char *ivarName, const char * encode) {
    const char *typeStr = encode;
    NSUInteger size, alignment;
    NSGetSizeAndAlignment(typeStr, &size, &alignment);
    return class_addIvar(class, ivarName, size, log2(alignment), typeStr);
}

static Class duke_prepareDynamicDelegateClass(NSObject *self, Class class, SEL selector) {
    DUKEParameterAssert(class);
    DUKEParameterAssert(selector);
    Protocol *protocol = duke_classInProtocolByDelegating(class, selector);
    if (!protocol) {
        DUKEParameterAssert(protocol);
        return nil;
    }
    SEL protocolSelector = NSSelectorFromString(NSStringFromProtocol(protocol));
    DukeIdentifier *identifier = objc_getAssociatedObject(self, protocolSelector);
    if (identifier && identifier.dynamicDelegateClass) {
        return identifier.dynamicDelegateClass;
    }
    
    Class dynamicDelegateClass = NULL;
    NSString *protocolNamed = NSStringFromProtocol(protocol);
    const char *subclassName = [protocolNamed stringByAppendingString:DUKESubclassSuffix].UTF8String;
    dynamicDelegateClass = objc_getClass(subclassName);
    if (dynamicDelegateClass == nil) {
        dynamicDelegateClass = objc_allocateClassPair([NSObject class], subclassName, 0);
        duke_dynamicDelegateClassAddIvar(dynamicDelegateClass,"identifier", @encode(id));
        duke_swizzleRespondsToSelector(dynamicDelegateClass);
        duke_swizzleMethodSignatureForSelector(dynamicDelegateClass);
        duke_swizzleForwardInvocation(dynamicDelegateClass);
        objc_registerClassPair(dynamicDelegateClass);
        identifier.dynamicDelegateClass = dynamicDelegateClass;
    }
    return dynamicDelegateClass;
}

static void duke_swizzleRespondsToSelector(Class class) {
    DUKEParameterAssert(class);
    class_replaceMethod(class, @selector(respondsToSelector:), (IMP)__DUKE_RESPONDSTOSELECTOR__, "B@::");
}
static void duke_swizzleMethodSignatureForSelector(Class class) {
    DUKEParameterAssert(class);
    class_replaceMethod(class, @selector(methodSignatureForSelector:), (IMP)__DUKE_METHODSIGNATUREFORSELECTOR__, "#@::");
}
static void duke_swizzleForwardInvocation(Class class) {
    DUKEParameterAssert(class);
    class_replaceMethod(class, @selector(forwardInvocation:), (IMP)__DUKE_FORWARDINVOCATION__, "v@:@");
}

static DukeIdentifier *duke_getIdentifie(NSObject *self) {
    Ivar ivar = class_getInstanceVariable([self class], "identifier");
    return object_getIvar(self, ivar);
}

static BOOL __DUKE_RESPONDSTOSELECTOR__(__unsafe_unretained NSObject *self, SEL _cmd, SEL selector) {
    DUKEParameterAssert(self);
    DUKEParameterAssert(selector);
    DukeIdentifier *identifier = duke_getIdentifie(self);
    NSString *selectorNamed = NSStringFromSelector(selector);
    if ([identifier.methodSignatureMap.allKeys containsObject:selectorNamed]) {
        return YES;
    }
    else
    {
        struct objc_super superclazz = {
            .receiver = self,
            .super_class = class_getSuperclass(object_getClass(self))
        };
        
        // cast our pointer so the compiler won't complain
        BOOL (*objc_msgSendSuperCasted)(void *, SEL, SEL) = (void *)objc_msgSendSuper;
        
        // call super's method, which is original class's method
        return objc_msgSendSuperCasted(&superclazz, _cmd, selector);
    }
}

static NSMethodSignature * __DUKE_METHODSIGNATUREFORSELECTOR__(__unsafe_unretained NSObject *self, SEL _cmd, SEL selector) {
    DUKEParameterAssert(self);
    DUKEParameterAssert(selector);
    DukeIdentifier *identifier = duke_getIdentifie(self);
    NSString *selectorNamed = NSStringFromSelector(selector);
    if ([identifier.methodSignatureMap.allKeys containsObject:selectorNamed]) {
        return identifier.methodSignatureMap[selectorNamed];
    } else if (class_respondsToSelector(object_getClass(self), selector)) {
        return [object_getClass(self) methodSignatureForSelector:selector];
    }
    return [[NSObject class] methodSignatureForSelector:selector];
}

static void __DUKE_FORWARDINVOCATION__(__unsafe_unretained NSObject *self, SEL _cmd, NSInvocation *invocation) {
    DUKEParameterAssert(self);
    DUKEParameterAssert(invocation);
    DukeIdentifier *identifier = duke_getIdentifie(self);
    if (identifier) {
        [identifier invoke:invocation];
    }
    else
    {
        struct objc_super superclazz = {
            .receiver = self,
            .super_class = class_getSuperclass(object_getClass(self))
        };
        
        // cast our pointer so the compiler won't complain
        void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
        
        // call super's method, which is original class's method
        objc_msgSendSuperCasted(&superclazz, _cmd, invocation);
    }
}
@end


/////////////////////////////////////////////////////////////////////////////////////////
#pragma make - DukeIdentifier
@implementation DukeIdentifier

static NSMethodSignature *duke_blockMethodSignature(id block) {
    DukeBlockRef layout = (__bridge void *)block;
    
    if (!(layout->flags & DukeBlockFlagsHasSignature))
        return nil;
    
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    
    if (layout->flags & DukeBlockFlagsHasCopyDisposeHelpers)
        desc += 2 * sizeof(void *);
    
    if (!desc)
        return nil;
    
    const char *signature = (*(const char **)desc);
    
    return [NSMethodSignature signatureWithObjCTypes:signature];
}


// blockSignature签名是否兼容
static BOOL duke_isCompatibleBlockSignature(NSMethodSignature *blockSignature, NSMethodSignature *methodSignature, id object, SEL selector) {
    DUKEParameterAssert(blockSignature);
    DUKEParameterAssert(methodSignature);
    DUKEParameterAssert(object);
    DUKEParameterAssert(selector);
    
    BOOL signaturesMatch = YES;
    if (blockSignature.numberOfArguments > methodSignature.numberOfArguments) {
        signaturesMatch = NO;
    }else {
        if (blockSignature.numberOfArguments > 1) {
            const char *blockType = [blockSignature getArgumentTypeAtIndex:1];
            if (blockType[0] != '@') {
                signaturesMatch = NO;
            }
        }
        
        if (signaturesMatch) {
            for (NSUInteger idx = 2; idx < blockSignature.numberOfArguments; idx++) {
                const char *methodType = [methodSignature getArgumentTypeAtIndex:idx + 1];
                const char *blockType = [blockSignature getArgumentTypeAtIndex:idx];
                if (!methodType || !blockType || methodType[0] != blockType[0]) {
                    signaturesMatch = NO; break;
                }
            }
        }
    }
    
    if (!signaturesMatch) {
        NSString *description = [NSString stringWithFormat:@"Block signature %@ doesn't match %@.", blockSignature, methodSignature];
        NSLog(@"%@",description);
        return NO;
    }
    return YES;
}

static NSMethodSignature *duke_methodSignature(Protocol *protocol, SEL selector) {
    DUKEParameterAssert(protocol);
    DUKEParameterAssert(selector);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, YES, YES);
    if (!methodDescription.name) methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    if (methodDescription.name) {
        NSMethodSignature *protoSignature = [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:protoSignature];
        return inv.methodSignature;
    }
    return nil;
}

+ (instancetype)identifierWithSelector:(SEL)selector object:(id)object block:(id)block {
    DUKEParameterAssert(block);
    DUKEParameterAssert(selector);
    NSMethodSignature *blockSignature = duke_blockMethodSignature(block);
    Protocol *protocol = duke_classInProtocolByDelegating([object class], selector);
    
    NSMutableDictionary *methodsBlockMap    = [NSMutableDictionary dictionary];
    NSMutableDictionary *blockSignatureMap  = [NSMutableDictionary dictionary];
    NSMutableDictionary *methodSignatureMap = [NSMutableDictionary dictionary];
    
    NSMethodSignature *methodSignature = duke_methodSignature(protocol, selector);
    
    if (!duke_isCompatibleBlockSignature(blockSignature, methodSignature, object, selector) && !methodSignature) {
        return nil;
    }
    
    [methodSignatureMap setValue:methodSignature forKey:NSStringFromSelector(selector)];
    [methodsBlockMap setObject:block forKey:NSStringFromSelector(selector)];
    [blockSignatureMap setObject:blockSignature forKey:NSStringFromSelector(selector)];
    
    DukeIdentifier *identifier = nil;
    if (blockSignature) {
        identifier = [DukeIdentifier new];
        identifier.selector = selector;
        identifier.block = block;
        identifier.blockSignature = blockSignature;
        identifier.methodSignature = methodSignature;
        identifier.object = object; // weak
        identifier.protocol = protocol;
        identifier.methodSignatureMap = methodSignatureMap;
        identifier.methodsBlockMap    = methodsBlockMap;
        identifier.blockSignatureMap  = blockSignatureMap;
    }
    return identifier;
}

- (void)update:(SEL)selector block:(id)block {
    DUKEParameterAssert(block);
    DUKEParameterAssert(selector);
    NSString *selectorNamed = NSStringFromSelector(selector);
    if (![self.methodSignatureMap.allKeys containsObject:selectorNamed]) {
        Protocol *protocol = duke_classInProtocolByDelegating([self.object class], selector);
        NSMethodSignature *methodSignature = duke_methodSignature(protocol, selector);
        NSMethodSignature *blockSignature = duke_blockMethodSignature(block);
        if (methodSignature && blockSignature) {
            [self.methodSignatureMap setObject:methodSignature forKey:NSStringFromSelector(selector)];
            [self.methodsBlockMap setObject:block forKey:NSStringFromSelector(selector)];
            [self.blockSignatureMap setObject:blockSignature forKey:NSStringFromSelector(selector)];
        }
    }
}

- (BOOL)invoke:(NSInvocation *)invocation {
    NSInvocation *originalInvocation = invocation;
    NSMethodSignature *blockSignature = [self.blockSignatureMap objectForKey:NSStringFromSelector(originalInvocation.selector)];
    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:blockSignature];
    
    NSUInteger numberOfArguments = invocation.methodSignature.numberOfArguments;
    if (numberOfArguments > originalInvocation.methodSignature.numberOfArguments) {
        return NO;
    }
    
    void *argBuf = NULL;
    
    for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
        const char *type = [originalInvocation.methodSignature getArgumentTypeAtIndex:idx];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);
        
        if (!(argBuf = reallocf(argBuf, argSize))) {
            return NO;
        }
        
        [originalInvocation getArgument:argBuf atIndex:idx];
        [blockInvocation setArgument:argBuf atIndex:idx - 1];
    }
    
    id block = [self.methodsBlockMap objectForKey:NSStringFromSelector(originalInvocation.selector)];
    [blockInvocation invokeWithTarget:block];
    
    NSUInteger retSize = originalInvocation.methodSignature.methodReturnLength;
    if (retSize) {
        if (!(argBuf = reallocf(argBuf, retSize))) {
            return NO;
        }
        [blockInvocation getReturnValue:argBuf];
        [originalInvocation setReturnValue:argBuf];
    }
    
    if (argBuf != NULL) {
        free(argBuf);
    }
    return YES;
}
@end

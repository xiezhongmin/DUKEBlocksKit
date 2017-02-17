//
//  NSObject+DUKEBlockObservation.h
//  DUKEBlocksKit
//
//  Created by 请叫我杜克 on 16/12/14.
//  Copyright © 2016年 com.xiezhongmin.new. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "metamacros.h"

NS_ASSUME_NONNULL_BEGIN


#define DUKEObserve(TARGET, KEYPATH) \
({ \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wreceiver-is-weak\"") \
__weak id target_ = (TARGET); \
[target_ duke_observerForKeyPath:@keypath(TARGET, KEYPATH)]; \
_Pragma("clang diagnostic pop") \
})

@interface DUKEObserver : NSObject
@property (nonatomic, copy, readonly) NSString *token;
// default NSKeyValueObservingOptionNew
- (NSString *)duke_addHandler:(void (^)(id obj, NSDictionary *change))block;

// options
- (NSString *)duke_addHandler:(void (^)(id obj, NSDictionary *change))block forOptions:(NSKeyValueObservingOptions)options;

// map
- (DUKEObserver *)duke_map:(id (^)(id value))block;
@end

@interface NSObject (DUKEBlockObservation)
- (DUKEObserver *)duke_observerForKeyPath:(NSString *)keyPath;
- (void)duke_removeObserverWithToken:(NSString *)token;
- (void)duke_removeAllObservers;
@end
                               
NS_ASSUME_NONNULL_END

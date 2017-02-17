//
//  DUKEExample1Model.h
//  DUKEBlocksKitExample
//
//  Copyright © 2016年 请叫我杜克. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DUKEExample1Model : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *html;
- (instancetype)initWithName:(NSString *)name icon:(NSString *)icon html:(NSString *)html;
@end

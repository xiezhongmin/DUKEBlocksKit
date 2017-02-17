# DUKEBlocksKit
- DUKEBlocksKit is an Objective-C category on UIControl ,dynamic delegate, Observer that allows for handling of control events with blocks

## DUKEBlocksKit【前言】
- DUKEBlocksKit部分借鉴了著名框架[Aspects](https://github.com/steipete/Aspects) , [BlocksKit](https://github.com/zwaldowski/BlocksKit) 与 [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) 神奇的宏定义
- 1.动态代理:
	- 先简单的介绍一下[BlocksKit](https://github.com/zwaldowski/BlocksKit) 框架的动态代理 在动态代理这部分可以说是 BlocksKit 的精华。它使用 block 属性替换 UIKit中的所有能够通过代理完成的事件，省略了设置代理和实现方法的过程，让对象自己实现代理方法（其实不是对象自己实现的代理方法，只是框架为我们提供的便捷方法，不需要构造其它对象就能完成代理方法的实现），而且这个功能的实现是极其动态的。具体可以参照博客 [神奇的BlocksKit](http://draveness.me/blockskit-2)
	- [DUKEBlocksKit]()在使用上优于BlocksKit, BlocksKit动态代理步骤比较繁琐：1.获取及注册被代理类的动态代理对象 2.需要将委托对象的代理方法映射一个block对象 3.设置为动态代理  DUKEBlocksKit使用步骤请见后面示例
	- [DUKEBlocksKit]()支持自定义委托方法转block
	
- 2.RAC(TARGET, ...) 与 RACObserve(TARGET, KEYPATH)的巧妙结合
	- [DUKEBlocksKit]()模仿了[ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) 支持KVO神奇的宏，例如 RAC宏绑定属性:
```objc	
	RAC(self.outputLabel, text) = RACObserve(self.model, name);
```	
- 3.UIControl事件转`block`

```objc
UIButton *exampleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
[exampleBtn duke_addTouchUpInside:^(id sender) {
           // TouchUpInside事件回调
        }];
```

##DUKEBlocksKit【支持】
- 动态代理（UIKit 中的所有能够通过代理完成的事件与自定义委托）

- 支持[ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)神奇`RAC(TARGET, ...)` 与 `RACObserve(TARGET, KEYPATH)`的巧妙结合的宏

- UIControl事件转`block`

- 后续还会增加

##DUKEBlocksKit【示例】
###1.动态代理

```objc
UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"DUKEBlocksKitExample" delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"Example1",@"Example2",nil];
    
    [sheet duke_mapSelector:@selector(actionSheet:clickedButtonAtIndex:) usingBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
         // UIActionSheet 回调事件
    }];
    
    [sheet duke_beginDynamicDelegate];
    [sheet showInView:self.view];
```

###2.RAC(TARGET, ...) 与 RACObserve(TARGET, KEYPATH)

```objc
DUKE(self.textfield, text) = DUKEObserve(self.message, text);
```

###3.UIControl事件转`block`

```objc
UIButton *exampleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
[exampleBtn duke_addTouchUpInside:^(id sender) {
           // TouchUpInside事件回调
        }];
```

##DUKEBlocksKit【安装】
### From CocoaPods【使用CocoaPods】
```ruby
pod 'DUKEBlocksKit'
```

##DUKEBlocksKit【期待】
* 如果在使用过程中遇到BUG，希望你能Issues我，谢谢（或者尝试下载最新的框架代码看看BUG修复没有）
* 如果在使用过程中发现功能不够用，希望你能Issues我，我非常想为这个框架增加更多好用的功能，谢谢
* 如果你想为DUKEBlocksKit输出代码，请拼命Pull Requests我
* 感谢你的支持是我无限的动力
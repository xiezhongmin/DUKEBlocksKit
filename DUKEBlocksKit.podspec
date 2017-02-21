Pod::Spec.new do |s|
version            = "1.0.1"
s.name             = "DUKEBlocksKit"
s.version          =  version
s.summary          = "DUKEBlocksKit部分借鉴了著名框架Aspects，BlocksKit，ReactiveCocoa的神奇的宏定义。实现了更加灵活的动态代理，模仿RAC神奇的宏RAC与RACObserve属性绑定"
s.homepage         = "https://github.com/xiezhongmin/DUKEBlocksKit"
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { "xie1988" => "364101515@qq.com" }
s.platform         = :ios, '7.0'
s.source           = { :git => "https://github.com/xiezhongmin/DUKEBlocksKit.git", :tag => version }
#s.source_files    = 'DUKEBlocksKit/*'
s.requires_arc     =  true

s.subspec 'DUKEBlocksKit' do |ss|
ss.source_files  = 'DUKEBlocksKit/*'
end

end

Pod::Spec.new do |s|
  s.name             = 'CRUDE-Futures'
  s.version          = '0.1.28'
  s.summary          = 'Easily Create, Read, Update, Delete and Enumerate objects with the help of Alamofire, SwiftyJSON, and BrightFutures.'

  s.description      = <<-DESC
Easily Create, Read, Update, Delete and Enumerate objects with the help of Alamofire, SwiftyJSON, and BrightFutures. Simply use the provided protocols with any model structures.
                       DESC

  s.homepage         = 'https://github.com/JasonCanCode/CRUDE-Futures'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jason Welch' => 'JasonCanCode@gmail.com' }
  s.source           = { :git => 'https://github.com/JasonCanCode/CRUDE-Futures.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.source_files = 'CRUDEFutures/**/*'
end

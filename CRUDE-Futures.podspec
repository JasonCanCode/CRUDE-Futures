#
# Be sure to run `pod lib lint CRUDE-Futures.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CRUDE-Futures'
  s.version          = '0.1.27'
  s.summary          = 'Easily Create, Read, Update, Delete and Enumerate objects with the help of Alamofire, SwiftyJSON, and BrightFutures.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Easily Create, Read, Update, Delete and Enumerate objects with the help of Alamofire, SwiftyJSON, and BrightFutures. Simply use the provided protocols with any model structures.
                       DESC

  s.homepage         = 'https://github.com/JasonCanCode/CRUDE-Futures'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jason Welch' => 'JasonCanCode@gmail.com' }
  s.source           = { :git => 'https://github.com/JasonCanCode/CRUDE-Futures.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.source_files = 'CRUDEFutures/**/*'
  s.dependency 'Alamofire', '>= 3.4'
  s.dependency 'SwiftyJSON', '>= 2.3'
  s.dependency 'BrightFutures', '>= 4.1'
  s.dependency 'Result', '>= 2.0'

# s.resource_bundles = {
#  'CRUDE-Futures' => ['CRUDEFutures/Assets.xcassets/*.png']
# }

  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
end

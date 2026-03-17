#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint improv_wifi_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'improv_wifi_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter wrapper for the improv-wifi native SDKs.'
  s.description      = <<-DESC
Flutter wrapper around the improv-wifi iOS SDK.
                       DESC
  s.homepage         = 'https://github.com/improv-wifi'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'shushikeji' => 'example@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.3'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'improv_wifi_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end

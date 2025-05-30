Pod::Spec.new do |s|
  s.name             = 'Auth0'
  s.version          = '2.13.0'
  s.summary          = "Auth0 SDK for Apple platforms"
  s.description      = <<-DESC
                        Auth0 SDK for iOS, macOS, tvOS, watchOS and visionOS apps.
                        DESC
  s.homepage         = 'https://github.com/auth0/Auth0.swift'
  s.license          = 'MIT'
  s.authors          = { 'Auth0' => 'support@auth0.com', 'Rita Zerrizuela' => 'rita.zerrizuela@auth0.com' }
  s.source           = { :git => 'https://github.com/auth0/Auth0.swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/auth0'
  s.source_files     = 'Auth0/**/*.swift'
  s.resource_bundles = { s.name => 'Auth0/PrivacyInfo.xcprivacy' }
  s.swift_versions   = ['5.0']

  s.dependency 'SimpleKeychain', '1.3.0'
  s.dependency 'JWTDecode', '3.3.0'

  s.ios.deployment_target   = '14.0'
  s.ios.pod_target_xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM PASSKEYS_PLATFORM'
  }

  s.osx.deployment_target   = '11.0'
  s.osx.pod_target_xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM PASSKEYS_PLATFORM'
  }

  s.tvos.deployment_target = '14.0'
  s.watchos.deployment_target = '7.0'

  s.visionos.deployment_target = '1.0'
  s.visionos.pod_target_xcconfig =  {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM PASSKEYS_PLATFORM'
  }
end

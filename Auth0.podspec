web_auth_files = [
  'Auth0/ObjectiveC/A0ChallengeGenerator.h',
  'Auth0/ObjectiveC/A0ChallengeGenerator.m',
  'Auth0/ObjectiveC/A0RSA.h',
  'Auth0/ObjectiveC/A0RSA.m',
  'Auth0/ObjectiveC/A0SHA.h',
  'Auth0/ObjectiveC/A0SHA.m',
  'Auth0/Array+Encode.swift',
  'Auth0/ASCallbackTransaction.swift',
  'Auth0/ASTransaction.swift',
  'Auth0/AuthSession.swift',
  'Auth0/AuthTransaction.swift',
  'Auth0/Auth0WebAuth.swift',
  'Auth0/BaseCallbackTransaction.swift',
  'Auth0/BaseTransaction.swift',
  'Auth0/BioAuthentication.swift',
  'Auth0/ClaimValidators.swift',
  'Auth0/IDTokenSignatureValidator.swift',
  'Auth0/IDTokenValidator.swift',
  'Auth0/IDTokenValidatorContext.swift',
  'Auth0/JWK+RSA.swift',
  'Auth0/JWT+Header.swift',
  'Auth0/JWTAlgorithm.swift',
  'Auth0/NSURLComponents+OAuth2.swift',
  'Auth0/OAuth2Grant.swift',
  'Auth0/TransactionStore.swift',
  'Auth0/WebAuth.swift',
  'Auth0/WebAuthError.swift'
]

ios_files = [
  'Auth0/MobileWebAuth.swift'
]

macos_files = [
  'Auth0/DesktopWebAuth.swift'
]

excluded_files = [
  *web_auth_files,
  *ios_files,
  *macos_files
]

Pod::Spec.new do |s|
  s.name             = 'Auth0'
  s.version          = '2.0.0-beta'
  s.summary          = "Swift toolkit for Auth0 API"
  s.description      = <<-DESC
                        Auth0 API toolkit written in Swift for iOS, watchOS, tvOS & macOS apps
                        DESC
  s.homepage         = 'https://github.com/auth0/Auth0.swift'
  s.license          = 'MIT'
  s.authors          = { "Auth0" => "support@auth0.com" }, { "Hernan Zalazar" => "hernan@auth0.com" }, { "Martin Walsh" => "martin.walsh@auth0.com" }
  s.source           = { :git => 'https://github.com/auth0/Auth0.swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/auth0'

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'
  s.watchos.deployment_target = '6.2'
  s.tvos.deployment_target = '12.0'
  s.requires_arc = true

  s.ios.source_files = 'Auth0/*.{swift,h,m}', 'Auth0/ObjectiveC/*.{h,m}'
  s.ios.exclude_files = macos_files
  s.ios.frameworks = 'UIKit', 'LocalAuthentication', 'AuthenticationServices'
  s.ios.dependency 'SimpleKeychain'
  s.ios.dependency 'JWTDecode', '~> 2.0'
  s.ios.pod_target_xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) WEB_AUTH_PLATFORM=1'
  }

  s.osx.source_files = 'Auth0/*.{swift,h,m}', 'Auth0/ObjectiveC/*.{h,m}'
  s.osx.exclude_files = ios_files
  s.osx.frameworks = 'AppKit', 'LocalAuthentication', 'AuthenticationServices'
  s.osx.dependency 'SimpleKeychain'
  s.osx.dependency 'JWTDecode', '~> 2.0'
  s.osx.pod_target_xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) WEB_AUTH_PLATFORM=1'
  }

  s.watchos.source_files = 'Auth0/*.swift'
  s.watchos.exclude_files = excluded_files
  s.watchos.dependency 'SimpleKeychain'
  s.watchos.dependency 'JWTDecode', '~> 2.0'

  s.tvos.source_files = 'Auth0/*.swift'
  s.tvos.exclude_files = excluded_files
  s.tvos.dependency 'SimpleKeychain'
  s.tvos.dependency 'JWTDecode', '~> 2.0'

  s.swift_versions = ['5.3', '5.4', '5.5']
end

version = `agvtool mvers -terse1`.strip

web_auth_files = [
  'Auth0/A0ChallengeGenerator.h',
  'Auth0/A0ChallengeGenerator.m',
  'Auth0/A0RSA.h',
  'Auth0/A0RSA.m',
  'Auth0/A0SHA.h',
  'Auth0/A0SHA.m',
  'Auth0/A0SimpleKeychain+RSAPublicKey.swift',
  'Auth0/Array+Encode.swift',
  'Auth0/AuthCancelable.swift',
  'Auth0/AuthProvider.swift',
  'Auth0/AuthSession.swift',
  'Auth0/AuthTransaction.swift',
  'Auth0/AuthenticationServicesSession.swift',
  'Auth0/AuthenticationServicesSessionCallback.swift',
  'Auth0/BaseAuthTransaction.swift',
  'Auth0/BaseWebAuth.swift',
  'Auth0/BioAuthentication.swift',
  'Auth0/ClaimValidators.swift',
  'Auth0/IDTokenSignatureValidator.swift',
  'Auth0/IDTokenValidator.swift',
  'Auth0/IDTokenValidatorContext.swift',
  'Auth0/JWK+RSA.swift',
  'Auth0/JWT+Header.swift',
  'Auth0/JWTAlgorithm.swift',
  'Auth0/NativeAuth.swift',
  'Auth0/NSURLComponents+OAuth2.swift',
  'Auth0/OAuth2Grant.swift',
  'Auth0/ResponseType.swift',
  'Auth0/SessionCallbackTransaction.swift',
  'Auth0/SessionTransaction.swift',
  'Auth0/TransactionStore.swift',
  'Auth0/WebAuthenticatable.swift',
  'Auth0/WebAuthError.swift',
  'Auth0/_ObjectiveWebAuth.swift'
]

ios_files = [
  'Auth0/ControllerModalPresenter.swift',
  'Auth0/MobileWebAuth.swift',
  'Auth0/SafariSession.swift',
  'Auth0/SilentSafariViewController.swift',
  'Auth0/UIApplication+Shared.swift'
]

macos_files = [
  'Auth0/DesktopWebAuth.swift',
  'Auth0/NSApplication+Shared.swift'
]

excluded_files = [
  *web_auth_files,
  *ios_files,
  *macos_files
]

Pod::Spec.new do |s|
  s.name             = 'Auth0'
  s.version          = version
  s.summary          = "Swift toolkit for Auth0 API"
  s.description      = <<-DESC
                        Auth0 API toolkit written in Swift for iOS, watchOS, tvOS & macOS apps
                        DESC
  s.homepage         = 'https://github.com/auth0/Auth0.swift'
  s.license          = 'MIT'
  s.authors          = { "Auth0" => "support@auth0.com" }, { "Hernan Zalazar" => "hernan@auth0.com" }, { "Martin Walsh" => "martin.walsh@auth0.com" }
  s.source           = { :git => 'https://github.com/auth0/Auth0.swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/auth0'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true

  s.ios.source_files = 'Auth0/*.{swift,h,m}'
  s.ios.frameworks = 'UIKit', 'SafariServices', 'LocalAuthentication'
  s.ios.weak_framework = 'AuthenticationServices'
  s.ios.dependency 'SimpleKeychain'
  s.ios.dependency 'JWTDecode'
  s.ios.exclude_files = macos_files
  s.ios.pod_target_xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM'
  }

  s.osx.source_files = 'Auth0/*.{swift,h,m}'
  s.osx.exclude_files = ios_files
  s.osx.dependency 'SimpleKeychain'
  s.osx.dependency 'JWTDecode'
  s.osx.pod_target_xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM'
  }

  s.watchos.source_files = 'Auth0/*.swift'
  s.watchos.exclude_files = excluded_files
  s.watchos.dependency 'SimpleKeychain'
  s.watchos.dependency 'JWTDecode'

  s.tvos.source_files = 'Auth0/*.swift'
  s.tvos.exclude_files = excluded_files
  s.tvos.dependency 'SimpleKeychain'
  s.tvos.dependency 'JWTDecode'

  s.swift_versions = ['4.0', '4.1', '4.2', '5.0', '5.1', '5.2', '5.3']
end

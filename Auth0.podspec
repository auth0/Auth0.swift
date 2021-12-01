web_auth_files = [
  'Auth0/Array+Encode.swift',
  'Auth0/ASCallbackTransaction.swift',
  'Auth0/ASTransaction.swift',
  'Auth0/AuthSession.swift',
  'Auth0/AuthTransaction.swift',
  'Auth0/Auth0WebAuth.swift',
  'Auth0/BaseCallbackTransaction.swift',
  'Auth0/BaseTransaction.swift',
  'Auth0/BioAuthentication.swift',
  'Auth0/ChallengeGenerator.swift',
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

ios_files = ['Auth0/MobileWebAuth.swift']
macos_files = ['Auth0/DesktopWebAuth.swift']
excluded_files = [*web_auth_files, *ios_files, *macos_files]

Pod::Spec.new do |s|
  s.name             = 'Auth0'
  s.version          = '2.0.0-beta'
  s.summary          = "Swift toolkit for Auth0 API"
  s.description      = <<-DESC
                        Auth0 API toolkit written in Swift for iOS, watchOS, tvOS & macOS apps
                        DESC
  s.homepage         = 'https://github.com/auth0/Auth0.swift'
  s.license          = 'MIT'
  s.authors          = { 'Auth0' => 'support@auth0.com', 'Rita Zerrizuela' => 'rita.zerrizuela@auth0.com' }
  s.source           = { :git => 'https://github.com/auth0/Auth0.swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/auth0'
  s.source_files     = 'Auth0/*.swift'
  s.swift_versions   = ['5.3', '5.4', '5.5']

  s.dependency 'SimpleKeychain'
  s.dependency 'JWTDecode', '~> 2.0'

  s.ios.deployment_target   = '12.0'
  s.ios.exclude_files       = macos_files
  s.ios.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM' }

  s.osx.deployment_target   = '10.15'
  s.osx.exclude_files       = ios_files
  s.osx.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM' }

  s.tvos.deployment_target = '12.0'
  s.tvos.exclude_files     = excluded_files

  s.watchos.deployment_target = '6.2'
  s.watchos.exclude_files     = excluded_files
end

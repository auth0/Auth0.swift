version = `agvtool mvers -terse1`.strip
Pod::Spec.new do |s|
  s.name             = 'Auth0'
  s.version          = version
  s.summary          = "Swift toolkit for Auth0 API"
  s.description      = <<-DESC
                        Auth0 API toolkit written in Swift for iOS & OSX apps
                        DESC
  s.homepage         = 'https://github.com/auth0/Auth0.swift'
  s.license          = 'MIT'
  s.author           = { 'Auth0' => 'support@auth0.com', 'Hernan Zalazar' => 'hernan@auth0.com' }
  s.source           = { :git => 'https://github.com/auth0/Auth0.swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/auth0'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.requires_arc = true

  s.ios.source_files = 'Auth0/**/*.{swift,h,m}'
  s.osx.source_files = ['Auth0/*.swift', 'Auth0/{Authentication,Extensions,Logger,Management,Networking}/*.{swift,h,m}']
end
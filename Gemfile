source 'https://rubygems.org'

gem 'fastlane'
gem 'cocoapods'
gem 'slather'
gem 'xcpretty', git: 'https://github.com/xcpretty/xcpretty.git', ref: 'fbe3f010bf0ce200664425a8f6b3470e7acbe6a6'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)

Pod::Spec.new do |s|
  s.name     = 'TOSMBClient'
  s.version  = '1.0'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'An Objective-C framework that wraps libdsm, an SMB client library.'
  s.homepage = 'https://github.com/TimOliver/TOSMBClient'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOSMBClient.git', :tag => '1.0' }
  s.platform = :ios, '7.0'
  s.source_files = 'TOSMBClient/**/*.{h,m}'
  s.requires_arc = true
end

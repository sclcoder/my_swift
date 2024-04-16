# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'my_swift' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for my_swift
  
  pod 'Toast-Swift', '~> 5.0.1'
  pod 'PKHUD', '~> 5.0'
  pod 'ProgressHUD'

  
  
  pod 'Moya', '~> 15.0'
  pod 'SnapKit'
  pod 'Alamofire', :path => './Alamofire'

  pod 'RxSwift'
  pod 'RxCocoa'
  
  post_install do |installer|
      installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
              end
          end
      end
  end
  
end

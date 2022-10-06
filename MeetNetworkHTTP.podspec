Pod::Spec.new do |spec|
    
    # UPDATE POD REPO -> RUN:
    # pod repo push meetingCore MeetNetworkHTTP.podspec --allow-warnings

    spec.name         = "MeetNetworkHTTP"
    spec.version      = "0.1.0"
    spec.summary      = "MeetNetworkHTTP is an HTTP networking library written in Swift."

    spec.homepage     = "https://meetinglawyers.com"

    spec.license      = { :type => 'Copyright', :text => 'Copyright © 2021 MeetingLawyers S.L. All rights reserved.' }

    spec.authors      = { "Manel Roca" => "manel.roca@meetinglawyers.com" }

    spec.source       = {   :git => "https://github.com/MeetingLawyers/ios-meeting-shared.git",
                            :tag => spec.name + '-' + spec.version.to_s }

    spec.ios.deployment_target = '13.0'
    spec.platform = :ios, '13.0'
    spec.swift_version = '5.3'

    spec.source_files = "MeetNetwork/MeetNetworkHTTP/**/*.{swift}"
    
    spec.test_spec do|test|
        test.source_files = "MeetNetwork/MeetNetworkHTTPTests/**/*.swift"
    end
    
    # Xcode 12 Workaround for Simulator
#    spec.pod_target_xcconfig = {
#        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
#    }
#
#    spec.user_target_xcconfig = {
#        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
#    }

#    spec.resources = "MeetNetwork/MeetNetworkHTTP/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

end

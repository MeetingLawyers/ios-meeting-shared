Pod::Spec.new do |spec|

    spec.name         = "MeetNetworkHTTP"
    spec.version      = "0.0.1"
    spec.summary      = "MeetNetworkHTTP is an HTTP networking library written in Swift."

    spec.homepage     = "https://meetinglawyers.com"

    spec.license      = { :type => 'Copyright', :text => 'Copyright © 2021 MeetingLawyers S.L. All rights reserved.' }

    spec.authors      = { "Manel Roca" => "manel.roca@meetinglawyers.com" }

    spec.source       = { :git => "https://github.com/MeetingLawyers/ios-meeting-shared.git", :tag => spec.name + '-' + spec.version.to_s }

    spec.ios.deployment_target = '11.0'
    spec.platform = :ios, '11.0'
    spec.swift_version = '5.3'

    spec.source_files = "MeetNetwork/MeetNetworkHTTP/**/*.{swift}"

#    spec.resources = "MeetNetwork/MeetNetworkHTTP/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

end

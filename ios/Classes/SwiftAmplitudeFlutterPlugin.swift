import Flutter
import UIKit
import Amplitude

@objc public class SwiftAmplitudeFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "amplitude_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftAmplitudeFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func getPropertiesFromArguments(_ callArguments: Any?) throws -> [String:Any]? {
        if let arguments = callArguments, let data = (arguments as! String).data(using: .utf8) {

            let properties = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
            return properties;
        }
        return nil;
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            if let args = try getPropertiesFromArguments(call.arguments) {
                let instanceName = args["instanceName"] as! String

                switch (call.method) {
                // Init
                case "init":
                    let apiKey = args["apiKey"] as! String

                    if (apiKey.isEmpty) {
                        result(FlutterError.init(code: "EMPTY_APP_KEY",
                                                 message: "Please initialize the Amplitude with a valid API Key.", details: nil))
                        return
                    }

                    let userId = args["userId"] as! String?
                    Amplitude.instance(withName: instanceName).initializeApiKey(apiKey, userId: userId)
                    result(true)

                // Setters
                case "enableCoppaControl":
                    Amplitude.instance(withName: instanceName).enableCoppaControl();
                    result(true)
                case "disableCoppaControl":
                    Amplitude.instance(withName: instanceName).disableCoppaControl();
                    result(true)
                case "setOptOut":
                    let optOut = args["optOut"] as! Bool
                    Amplitude.instance(withName: instanceName).optOut = optOut
                    result(true)
                case "setLibraryName":
                    let libraryName = args["libraryName"] as! String
                    Amplitude.instance(withName: instanceName).libraryName = libraryName
                    result(true)
                case "setLibraryVersion":
                    let libraryVersion = args["libraryVersion"] as! String
                    Amplitude.instance(withName: instanceName).libraryVersion = libraryVersion
                    result(true)
                case "trackingSessionEvents":
                    let trackingSessionEvents = args["trackingSessionEvents"] as! Bool
                    Amplitude.instance(withName: instanceName).trackingSessionEvents = trackingSessionEvents
                    result(true)
                case "setUseDynamicConfig":
                    let useDynamicConfig = args["useDynamicConfig"] as! Bool
                    Amplitude.instance(withName: instanceName).useDynamicConfig = useDynamicConfig
                    result(true)
                case "setUserId":
                    var userId: String? = nil
                    if !(args["userId"] is NSNull) {
                        userId = args["userId"] as! String?
                    }
                    let startNewSession = args["startNewSession"] == nil ? false : (args["startNewSession"] as! Bool)

                    Amplitude.instance(withName: instanceName).setUserId(userId, startNewSession: startNewSession)
                    result(true)
                case "setServerUrl":
                    if !(args["serverUrl"] is NSNull) {
                        if let serverUrl = args["serverUrl"] as! String? {
                            Amplitude.instance(withName: instanceName).setServerUrl(serverUrl)
                        }
                    }

                    result(true)

                // Regenerates a new random deviceId for current user    
                case "regenerateDeviceId":
                    Amplitude.instance(withName: instanceName).regenerateDeviceId()
                    result(true)

                // Event logging
                case "logEvent":
                    let eventType = args["eventType"] as! String
                    let eventProperties = args["eventProperties"] as! [String: Any]?
                    let outOfSession = args["outOfSession"] == nil ? false : (args["outOfSession"] as! Bool)

                    Amplitude.instance(withName: instanceName).logEvent(eventType,
                                                                         withEventProperties: eventProperties,
                                                                         outOfSession: outOfSession)
                    result(true)
                case "logRevenue":
                    let productIdentifier = args["productIdentifier"] as! String
                    let quantity = args["quantity"] as! Int
                    let price = args["price"] as! Double

                    Amplitude.instance(withName: instanceName).logRevenue(productIdentifier,
                                                                           quantity: quantity,
                                                                           price: NSNumber(value: price))
                    result(true)

                case "logRevenueAmount":
                    let amount = args["amount"] as! Double
                    Amplitude.instance(withName: instanceName).logRevenue(NSNumber(value: amount))

                    result(true)

                case "identify":
                    let userProperties = args["userProperties"] as! [String: [String : NSObject]]
                    let identify: AMPIdentify = createIdentify(userProperties)
                    Amplitude.instance(withName: instanceName).identify(identify)
                    result(true)

                case "setGroup":
                    let groupType = args["groupType"] as! String
                    let groupName = args["groupName"] as! NSObject
                    Amplitude.instance(withName: instanceName).setGroup(groupType, groupName: groupName)

                    result(true)
                case "groupIdentify":
                    let groupType = args["groupType"] as! String
                    let groupName = args["groupName"] as! NSObject
                    let userProperties = args["userProperties"] as! [String: [String : NSObject]]
                    let outOfSession = args["outOfSession"] == nil ? false : (args["outOfSession"] as! Bool)
                    let identify: AMPIdentify = createIdentify(userProperties)
                    Amplitude.instance(withName: instanceName).groupIdentify(withGroupType: groupType,
                                                                              groupName: groupName,
                                                                              groupIdentify: identify,
                                                                              outOfSession: outOfSession)
                    result(true)
                    
                // User properties
                case "setUserProperties":
                    let userProperties = args["userProperties"] as! [String: Any]? ?? [:]
                    Amplitude.instance(withName: instanceName).setUserProperties(userProperties)
                    result(true)
                case "clearUserProperties":
                    Amplitude.instance(withName: instanceName).clearUserProperties()
                    result(true)
                    
                case "uploadEvents":
                    Amplitude.instance(withName: instanceName).uploadEvents()
                    result(true)

                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        } catch {
            result(FlutterError.init(code: "EXCEPTION_IN_HANDLE",
                                     message: "Exception happened in handle.", details: nil))
        }
    }
    
    private func createIdentify(_ userProperties: [String: [String : NSObject]]) -> AMPIdentify {
        let identify = AMPIdentify()
        
        for (operation, properties) in userProperties {
            for (key, value) in properties {
                switch operation {
                case "$add":
                    identify.add(key, value: value)
                case "$append":
                    identify.append(key, value: value)
                case "$prepend":
                    identify.prepend(key, value: value)
                case "$set":
                    identify.set(key, value: value)
                case "$setOnce":
                    identify.setOnce(key, value: value)
                case "$unset":
                    identify.unset(key) // value is default to `-`
                default:
                    break
                }
            }
        }
        return identify
    }
}

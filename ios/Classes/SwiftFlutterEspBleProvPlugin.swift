import Flutter
import UIKit
import ESPProvision

// Error codes for ESP BLE Provisioning
struct EspBleProvErrorCodes {
    static let BLE_SCAN_FAILED = "BLE_SCAN_FAILED"
    static let DEVICE_NOT_FOUND = "DEVICE_NOT_FOUND"
    static let CONNECTION_FAILED = "CONNECTION_FAILED"
    static let AUTH_FAILED = "AUTH_FAILED"
    static let WIFI_SCAN_FAILED = "WIFI_SCAN_FAILED"
    static let PROVISION_FAILED = "PROVISION_FAILED"
    static let DEVICE_DISCONNECTED = "DEVICE_DISCONNECTED"
    static let UNKNOWN_ERROR = "UNKNOWN_ERROR"
}

public class SwiftFlutterEspBleProvPlugin: NSObject, FlutterPlugin {
    private let SCAN_BLE_DEVICES = "scanBleDevices"
    private let SCAN_WIFI_NETWORKS = "scanWifiNetworks"
    private let PROVISION_WIFI = "provisionWifi"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_esp_ble_prov", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterEspBleProvPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Uncomment to enable ESPProvision logs
        // ESPProvisionManager.shared.enableLogs(true)
    }
    

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let provisionService = BLEProvisionService(result: result);
        let arguments = call.arguments as! [String: Any]
        
        if(call.method == SCAN_BLE_DEVICES) {
            let prefix = arguments["prefix"] as! String
            provisionService.searchDevices(prefix: prefix)
        } else if(call.method == SCAN_WIFI_NETWORKS) {
            let deviceName = arguments["deviceName"] as! String
            let proofOfPossession = arguments["proofOfPossession"] as! String
            provisionService.scanWifiNetworks(deviceName: deviceName, proofOfPossession: proofOfPossession)
        } else if (call.method == PROVISION_WIFI) {
            let deviceName = arguments["deviceName"] as! String
            let proofOfPossession = arguments["proofOfPossession"] as! String
            let ssid = arguments["ssid"] as! String
            let passphrase = arguments["passphrase"] as! String
            provisionService.provision(
                deviceName: deviceName,
                proofOfPossession: proofOfPossession,
                ssid: ssid,
                passphrase: passphrase
            )
        } else {
            result("iOS " + UIDevice.current.systemVersion)
        }
    }
    
}

protocol ProvisionService {
    var result: FlutterResult { get }
    func searchDevices(prefix: String) -> Void
    func scanWifiNetworks(deviceName: String, proofOfPossession: String) -> Void
    func provision(deviceName: String, proofOfPossession: String, ssid: String, passphrase: String) -> Void
}

private class BLEProvisionService: ProvisionService {
    fileprivate var result: FlutterResult
    
    init(result: @escaping FlutterResult) {
        self.result = result
    }
    
    func searchDevices(prefix: String) {
        ESPProvisionManager.shared.searchESPDevices(devicePrefix: prefix, transport:.ble, security:.secure) { deviceList, error in
            if(error != nil) {
                ESPErrorHandler.handle(error: error!, result: self.result)
            }
            self.result(deviceList?.map({ (device: ESPDevice) -> String in
                return device.name
            }))
        }
    }
    
    func scanWifiNetworks(deviceName: String, proofOfPossession: String) {
        self.connect(deviceName: deviceName, proofOfPossession: proofOfPossession) {
            device in
            device?.scanWifiList { wifiList, error in
                if(error != nil) {
                    NSLog("Error scanning wifi networks, deviceName: \(deviceName) ")
                    ESPErrorHandler.handle(error: error!, result: self.result)
                }
                self.result(wifiList?.map({(networks: ESPWifiNetwork) -> String in return networks.ssid}))
                device?.disconnect()
            }
        }
    }
    
    func provision(deviceName: String, proofOfPossession: String, ssid: String, passphrase: String) {
        self.connect(deviceName: deviceName, proofOfPossession: proofOfPossession){
            device in
            device?.provision(ssid: ssid, passPhrase: passphrase) { status in
                switch status {
                case .success:
                    NSLog("Success provisioning device. ssid: \(ssid), deviceName: \(deviceName) ")
                    self.result(true)
                case .configApplied:
                    NSLog("Wifi config applied device. ssid: \(ssid), deviceName: \(deviceName) ")
                case .failure:
                    NSLog("Failed to provision device. ssid: \(ssid), deviceName: \(deviceName) ")
                    self.result(FlutterError(code: EspBleProvErrorCodes.PROVISION_FAILED, message: "Provisioning failed", details: nil))
                }
            }
        }
    }
    
    private func connect(deviceName: String, proofOfPossession: String, completionHandler: @escaping (ESPDevice?) -> Void) {
        ESPProvisionManager.shared.createESPDevice(deviceName: deviceName, transport: .ble, security: .secure, proofOfPossession: proofOfPossession) { espDevice, error in
            
            if(error != nil) {
                ESPErrorHandler.handle(error: error!, result: self.result)
            }
            espDevice?.connect { status in
                switch status {
                case .connected:
                    completionHandler(espDevice!)
                case let .failedToConnect(error):
                    ESPErrorHandler.handle(error: error, result: self.result)
                default:
                    self.result(FlutterError(code: EspBleProvErrorCodes.DEVICE_DISCONNECTED, message: "Device disconnected", details: nil))
                }
            }
        }
    }
    
}

private class ESPErrorHandler {
    static func handle(error: ESPError, result: FlutterResult) {
        // Map ESPError to standardized error codes based on ESPErrors.swift
        let standardizedCode: String

        NSLog("Error code: \(error.code) Error description: \(error.description)")
        
        switch error.code {
        // ESPWiFiScanError cases (1-3)
        case 1: // emptyConfigData
            standardizedCode = EspBleProvErrorCodes.WIFI_SCAN_FAILED
        case 2: // emptyResultCount
            standardizedCode = EspBleProvErrorCodes.WIFI_SCAN_FAILED
        case 3: // scanRequestError
            standardizedCode = EspBleProvErrorCodes.WIFI_SCAN_FAILED
            
        // ESPSessionError cases (11-20)
        case 11: // sessionInitError
            standardizedCode = EspBleProvErrorCodes.AUTH_FAILED
        case 12: // sessionNotEstablished
            standardizedCode = EspBleProvErrorCodes.CONNECTION_FAILED
        case 13: // sendDataError
            standardizedCode = EspBleProvErrorCodes.CONNECTION_FAILED
        case 14: // softAPConnectionFailure
            standardizedCode = EspBleProvErrorCodes.CONNECTION_FAILED
        case 15: // securityMismatch
            standardizedCode = EspBleProvErrorCodes.AUTH_FAILED
        case 16: // versionInfoError
            standardizedCode = EspBleProvErrorCodes.CONNECTION_FAILED
        case 17: // bleFailedToConnect
            standardizedCode = EspBleProvErrorCodes.CONNECTION_FAILED
        case 18: // encryptionError
            standardizedCode = EspBleProvErrorCodes.AUTH_FAILED
        case 19: // noPOP
            standardizedCode = EspBleProvErrorCodes.AUTH_FAILED
        case 20: // noUsername
            standardizedCode = EspBleProvErrorCodes.AUTH_FAILED
            
        // ESPDeviceCSSError cases (21-28)
        case 26: // invalidQRCode
            standardizedCode = EspBleProvErrorCodes.UNKNOWN_ERROR
        case 27: // espDeviceNotFound
            standardizedCode = EspBleProvErrorCodes.DEVICE_NOT_FOUND
        case 28: // softApSearchNotSupported
            standardizedCode = EspBleProvErrorCodes.UNKNOWN_ERROR
            
        // ESPProvisionError cases (31-38)
        case 31: // sessionError
            standardizedCode = EspBleProvErrorCodes.CONNECTION_FAILED
        case 32: // configurationError
            standardizedCode = EspBleProvErrorCodes.PROVISION_FAILED
        case 33: // wifiStatusError
            standardizedCode = EspBleProvErrorCodes.PROVISION_FAILED
        case 34: // wifiStatusDisconnected
            standardizedCode = EspBleProvErrorCodes.PROVISION_FAILED
        case 35: // wifiStatusAuthenticationError
            standardizedCode = EspBleProvErrorCodes.PROVISION_FAILED
        case 36: // wifiStatusNetworkNotFound
            standardizedCode = EspBleProvErrorCodes.PROVISION_FAILED
        case 37: // wifiStatusUnknownError
            standardizedCode = EspBleProvErrorCodes.PROVISION_FAILED
        case 38: // unknownError
            standardizedCode = EspBleProvErrorCodes.UNKNOWN_ERROR
            
        default:
            standardizedCode = EspBleProvErrorCodes.UNKNOWN_ERROR
        }
        
        // Use the native error description directly as it's already accurate
        result(FlutterError(code: standardizedCode, message: error.description, details: nil))
    }
}

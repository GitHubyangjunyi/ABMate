//
//  DeviceRepository.swift
//  ABMateDemo
//
//  Created by Bluetrum.
//  

import Foundation
import CoreBluetooth
import Utils
import DeviceManager
import RxRelay
import UIKit

class DeviceRepository: NSObject {
    
    weak var logger: LoggerDelegate? = DefaultLogger.shared
    
    static let shared = DeviceRepository()
    
    // MARK: - Properties
    
    private let bluetoothManager = BluetoothManager.shared
    
    private var workingDevice: ABDevice?
    
    private var isOpened: Bool = false
    private var isScanning: Bool = false
    
    public let deviceCommManager = DefaultDeviceCommManager()
    private var preparingDevice: ABDevice?
    private var waitingDeviceReady: Bool = false
    
    private var _latestDiscoveredDevice: ABDevice? {
        didSet {
            latestDiscoveredDevice.accept(_latestDiscoveredDevice)
        }
    }
    let latestDiscoveredDevice: BehaviorRelay<ABDevice?> = BehaviorRelay(value: nil)
    
    private var _discoveredDevices = [ABDevice]() {
        didSet {
            discoveredDevices.accept(_discoveredDevices)
        }
    }
    let discoveredDevices: BehaviorRelay<[ABDevice]> = BehaviorRelay(value: [])
    
    private var _activeDevice: ABDevice? {
        didSet {
            activeDevice.accept(_activeDevice)
        }
    }
    let activeDevice: BehaviorRelay<ABDevice?> = BehaviorRelay(value: nil)
    
    var devicePower: BehaviorRelay<DevicePower?> { deviceCommManager.devicePower }
    var deviceFirmwareVersion: BehaviorRelay<UInt32?> { deviceCommManager.deviceFirmwareVersion }
    var deviceName: BehaviorRelay<String?> { deviceCommManager.deviceName }
    var deviceEqSetting: BehaviorRelay<RemoteEqSetting?> { deviceCommManager.deviceEqSetting }
    var deviceKeySettings: BehaviorRelay<[KeyType: KeyFunction]?> { deviceCommManager.deviceKeySettings }
    var deviceVolume: BehaviorRelay<UInt8?> { deviceCommManager.deviceVolume }
    var devicePlayState: BehaviorRelay<Bool?> { deviceCommManager.devicePlayState }
    var deviceWorkMode: BehaviorRelay<UInt8?> { deviceCommManager.deviceWorkMode }
    var deviceInEarStatus: BehaviorRelay<Bool?> { deviceCommManager.deviceInEarStatus }
    var deviceLanguageSetting: BehaviorRelay<UInt8?> { deviceCommManager.deviceLanguageSetting }
    var deviceAutoAnswer: BehaviorRelay<Bool?> { deviceCommManager.deviceAutoAnswer }
    var deviceAncMode: BehaviorRelay<UInt8?> { deviceCommManager.deviceAncMode }
    var deviceIsTws: BehaviorRelay<Bool?> { deviceCommManager.deviceIsTws }
    var deviceTwsConnected: BehaviorRelay<Bool?> { deviceCommManager.deviceTwsConnected }
    var deviceLedSwitch: BehaviorRelay<Bool?> { deviceCommManager.deviceLedSwitch }
    var deviceFwChecksum: BehaviorRelay<Data?> { deviceCommManager.deviceFwChecksum }
    var deviceAncGain: BehaviorRelay<Int?> { deviceCommManager.deviceAncGain }
    var deviceTransparencyGain: BehaviorRelay<Int?> { deviceCommManager.deviceTransparencyGain }
    var deviceAncGainNum: BehaviorRelay<Int?> { deviceCommManager.deviceAncGainNum }
    var deviceTransparencyGainNum: BehaviorRelay<Int?> { deviceCommManager.deviceTransparencyGainNum }
    var deviceRemoteEqSettings: BehaviorRelay<[RemoteEqSetting]?> { deviceCommManager.deviceRemoteEqSettings }
    var deviceLeftIsMainSide: BehaviorRelay<Bool?> { deviceCommManager.deviceLeftIsMainSide }
    var deviceProductColor: BehaviorRelay<UInt8?> { deviceCommManager.deviceProductColor }
    var deviceSpatialAudioMode: BehaviorRelay<SpatialAudioMode?> { deviceCommManager.deviceSpatialAudioMode }
    var deviceMultipointStatus: BehaviorRelay<Bool?> { deviceCommManager.deviceMultipointStatus }
    var deviceMultipointInfo: BehaviorRelay<Multipoint?> { deviceCommManager.deviceMultipointInfo }
    var deviceVoiceRecognitionStatus: BehaviorRelay<Bool?> { deviceCommManager.deviceVoiceRecognitionStatus }
    var deviceAncFadeStatus: BehaviorRelay<Bool?> { deviceCommManager.deviceAncFadeStatus }
    var deviceBassEngineStatus: BehaviorRelay<Bool?> { deviceCommManager.deviceBassEngineStatus }
    var deviceBassEngineValue: BehaviorRelay<Int8?> { deviceCommManager.deviceBassEngineValue }
    var deviceBassengineRange: BehaviorRelay<BassEngineRange?> { deviceCommManager.deviceBassEngineRange }
    var deviceAntiWindNoise: BehaviorRelay<Bool?> { deviceCommManager.deviceAntiWindNoise }
    var deviceCapacities: BehaviorRelay<DeviceCapacities?> { deviceCommManager.deviceCapacities }
    
    let deviceMaxPacketSize: BehaviorRelay<UInt16?> = BehaviorRelay(value: nil)
    
    // MARK: - Public API
    
    public override init() {
        super.init()
        self.bluetoothManager.delegate = self
    }
    
    func startScanning() {
        guard !isScanning else { return }
        
        resetPeripherals()
        isScanning = true
        bluetoothManager.startScanning()
    }
    
    func stopScanning() {
        guard isScanning else { return }
        
        bluetoothManager.stopScanning()
        isScanning = false
    }
    
    func connect(_ device: ABDevice) {
        workingDevice = device
        
        device.connectionStateCallback = self
        device.dataDelegate = self
        preparingDevice = device

        var options: [String: Any] = [:]
        if #available(iOS 13.2, *) {
            options[CBConnectPeripheralOptionEnableTransportBridgingKey] = true
        }
        bluetoothManager.connect(device.peripheral, options: options)
        isOpened = true
    }
    
    func disconnect() {
        guard let device = workingDevice else {
            return
        }
        _activeDevice?.stop()
        bluetoothManager.disconnect(device.peripheral)
        isOpened = false
    }
    
    func sendRequest(_ request: Request) {
        sendRequest(request, completion: nil)
    }
    
    func sendRequest(_ request: Request, completion: RequestCompletion?) {
        guard let device = workingDevice, device.peripheral.state == .connected else {
            return
        }
        deviceCommManager.sendRequest(request, completion: completion)
    }
    
    func resetDeviceStatus() {
        _latestDiscoveredDevice = nil
        _discoveredDevices = []
        
        deviceCommManager.resetDeviceStatus()
        deviceMaxPacketSize.accept(nil)
    }
    
    // MARK: - Implementation
    
    private func discoverDevice(_ device: ABDevice) {
//        logger?.v(.deviceRepository, "Found device: \(device)")
        
        _discoveredDevices.append(device)
        _latestDiscoveredDevice = device
    }
    
    private func resetPeripherals() {
        _latestDiscoveredDevice = nil
        _discoveredDevices.removeAll()
    }
    
    private func onDisconnected() {
        // 释放掉正在认证的设备
        if let device = preparingDevice {
            device.connectionStateCallback = nil
            device.dataDelegate = nil
            device.stop()
            preparingDevice = nil
        }
        
        // 释放当前活跃设备
        if let activeDevice = _activeDevice {
            activeDevice.connectionStateCallback = nil
            activeDevice.dataDelegate = nil
            activeDevice.stop()
            _activeDevice = nil
        }
        
        deviceCommManager.commDelegate = nil
        deviceCommManager.responseErrorHandler = nil
        deviceCommManager.reset()
        // 重置设备状态
        resetDeviceStatus()
    }
    
}

// MARK: - BluetoothDelegate

extension DeviceRepository: BluetoothDelegate {
    
    func didUpdateState(_ state: CBManagerState) {
        
        if state == .poweredOn {
            // TODO: move to another place
            // Listen bluetooth connection events
//            if #available(iOS 13.0, *) {
//                let ABMateServiceUUID = CBUUID(string: "FDB3")
//                self.bluetoothManager.registerForConnectionEvents(options: [.serviceUUIDs: ABMateServiceUUID]) // TODO: options未定，预留
//            }
            
            if isOpened {
                connect(workingDevice!)
            }
            if isScanning {
                startScanning()
            }
        } else if state == .poweredOff {
            isOpened = false
            isScanning = false
        }
    }
    
    func didStopScanning() {
        isScanning = false
    }
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        
        if let manufacturerData = advertisementData.manufacturerData(companyId: GlobalConfig.MANUFACTURER_ID),
           let deviceBeacon = DeviceBeacon.getDeviceBeacon(data: manufacturerData),
           deviceBeacon.brandId == GlobalConfig.BRAND_ID >> 16 {
            
//            logger?.v(.deviceRepository, "\(deviceBeacon)")
            
            // 如果是耳机广播
            if let earbudsBeacon = deviceBeacon as? EarbudsBeacon {
                // 如果广播里包含的地址和当前连接的音频设备相同（理所当然isConnected==true）
                // 或者未连接
                if (earbudsBeacon.btAddress == Utils.bluetoothAudioDeviceAddress) || !earbudsBeacon.isConnected {
                    // 如果设备已经存在于列表，则更新状态
                    // 否则列表添加新设备
                    if let device = _discoveredDevices.first(where: { $0.peripheral == peripheral }) {
                        device.updateDeviceStatus(deviceBeacon: earbudsBeacon)
                        device.rssi = RSSI.intValue
                        latestDiscoveredDevice.accept(device)
                    } else if peripheral.name != nil {
                        // TODO: Define Product ID
                        if earbudsBeacon.productId == 1 {
                            let device = ABEarbuds(peripheral: peripheral, earbudsBeacon: earbudsBeacon)
                            device.rssi = RSSI.intValue
                            discoverDevice(device)
                        }
                    }
                }
            }
        }
    }
    
    func didConnectedPeripheral(_ connectedPeripheral: CBPeripheral) {
        if connectedPeripheral == workingDevice?.peripheral {
            logger?.i(.deviceRepository, "Connected to \(workingDevice!.name ?? "Unknown Device")")
            preparingDevice?.connect()
        }
    }
    
    func failToConnectPeripheral(_ peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            logger?.w(.deviceRepository, error)
        } else {
            logger?.d(.deviceRepository, "Device is disconnected")
        }
    }
    
    func didDisconnectPeripheral(_ peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.workingDevice?.peripheral {
            let deviceNotSupported = preparingDevice != nil
            if let error = error as NSError? {
                switch error.code {
                case 6, 7: logger?.e(.deviceRepository, error.localizedDescription)
                default: logger?.e(.deviceRepository, "Disconnected from \(peripheral.name ?? "Unknown Device") with error: \(error)")
                }
            } else {
                if !deviceNotSupported {
                    logger?.i(.deviceRepository, "Disconnected from \(peripheral.name ?? "Unknown Device")")
                } else {
                    logger?.e(.deviceRepository, "Disconnected from \(peripheral.name ?? "Unknown Device") with error: Device not supported")
                }
            }
            
            self.workingDevice = nil
            onDisconnected()
        }
    }
    
    func connectionEventDidOccur(_ event: CBConnectionEvent, for peripheral: CBPeripheral) {
        switch event {
        case .peerDisconnected:
            print("TODO: peerDisconnected, check peripheral")
        case .peerConnected:
            print("TODO: peerConnected, check peripheral")
        @unknown default:
            print("connectionEventDidOccur: unknown event")
        }
    }
}

// MARK: - ConnectionStateCallback
extension DeviceRepository: ConnectionStateCallback {
    
    func onConnected(device: ABDevice) {
        deviceCommManager.commDelegate = device
        deviceCommManager.responseErrorHandler = self
        
        // 获取必要的信息
        // Get necessary infomation
        requireNecessaryInfomation()
    }
    
    func onReceiveAuthResult(device: ABDevice, passed: Bool) {
        if passed {
            _activeDevice = device
            // Require all device info
            deviceCommManager.sendRequest(DeviceInfoRequest.defaultInfoRequest) { request, result, timeout in
                guard #available(iOS 13.2, *), device.supportCTKD else { return }
                guard let result = result as? Bool, result else { return }
                device.triggerCTKD()
            }
        } else {
            device.stop()
            bluetoothManager.disconnect(device.peripheral)
        }
        // 已经不处于认证状态
        preparingDevice = nil
    }
}

// MARK: - DeviceDataDelegate
extension DeviceRepository: DeviceDataDelegate {
    func onReceiveData(_ data: Data) {
        logger?.d(.deviceRepository, "<- 0x\(data.hex)")
        deviceCommManager.handleData(data)
    }
}

// MARK: - DeviceResponseErrorHandler
extension DeviceRepository: DeviceResponseErrorHandler {
    func onError(_ error: ResponseError) {
        logger?.d(.deviceRepository, "Device Response error: \(error)")
    }
    
}

// MARK: - DeviceCommManager
extension DeviceRepository {
    
    var failureCompletion: RequestCompletion {
        return { _, result, timeout in
            // TODO: Handle error and failure
        }
    }
    
    /// The last step before use
    func doneGetNecessaryInfomation() {
        self.deviceCommManager.prepare()
        // Start authentication, if the device does not require authentication, it will directly return success
        self.preparingDevice?.startAuth()
    }
    
    func requireNecessaryInfomation() {
        // 先获取MTU，以便设置分包大小，然后再获取Capabilities，最后获取其他信息
        // First of all, require MTU, in order to set max packet size, and then require capabilities, finally other info
        requireMaxPacketSize()
    }
    
    func requireMaxPacketSize() {
        deviceCommManager.registerDeviceInfoCallback(Command.INFO_MAX_PACKET_SIZE, callableType: MtuPayloadHandler.self) {
            [weak self] in
            // No longer deal with Command.INFO_MAX_PACKET_SIZE
            self?.deviceCommManager.unregisterDeviceInfoCallback(Command.INFO_MAX_PACKET_SIZE)
            
            if let maxPacketSize = $0 as? Int {
                self?.logger?.d(.deviceRepository, "Max Packet Size: \(maxPacketSize)")
                // Update Value
                self?.deviceMaxPacketSize.accept(UInt16(maxPacketSize))
                // Set max communication packet size
                self?.deviceCommManager.maxPacketSize = maxPacketSize
                // Get Device Capabilities
                self?.requireCapabilities()
            }
        }
        deviceCommManager.sendRequest(DeviceInfoRequest(Command.INFO_MAX_PACKET_SIZE), completion: failureCompletion)
    }
    
    func requireCapabilities() {
        deviceCommManager.registerDeviceInfoCallback(Command.INFO_DEVICE_CAPABILITIES, callableType: DeviceCapacitiesPayloadHandler.self) {
            [weak self] in
            // No longer deal with Command.INFO_DEVICE_CAPABILITIES
            self?.deviceCommManager.unregisterDeviceInfoCallback(Command.INFO_DEVICE_CAPABILITIES)
            
            if let capabilities = $0 as? DeviceCapacities {
                if capabilities.supportMultipoint {
                    // 如果之前保存了地址，则现在发送
                    if let localBluetoothAddress = UserSettings.localBluetoothAddress {
                        self?.reportLocalBluetoothAddress(localBluetoothAddress) {
                            self?.doneGetNecessaryInfomation()
                        }
                    } else {
                        // 没有保存则获取
                        self?.requireMultipointInfo()
                    }
                } else {
                    self?.doneGetNecessaryInfomation()
                }
            }
        }
        deviceCommManager.sendRequest(DeviceInfoRequest(Command.INFO_DEVICE_CAPABILITIES), completion: failureCompletion)
    }
    
    func requireMultipointInfo() {
        deviceCommManager.registerDeviceInfoCallback(Command.INFO_MULTIPOINT_INFO, callableType: MultipointPayloadHandler.self) {
            [weak self] in
            // No longer deal with Command.INFO_MULTIPOINT_INFO
            self?.deviceCommManager.unregisterDeviceInfoCallback(Command.INFO_MULTIPOINT_INFO)
            
            if let multipoint = $0 as? Multipoint {
                let endpoints = multipoint.endpoints
                
                if endpoints.count == 1 {
                    let localBluetoothAddress = endpoints[0].address
                    UserSettings.localBluetoothAddress = localBluetoothAddress
                    // 报告给设备
                    self?.reportLocalBluetoothAddress(localBluetoothAddress) {
                        self?.doneGetNecessaryInfomation()
                    }
                } else {
                    // 报告不止一个，使用本机地址过滤
                    let filteredEndpoints = endpoints.filter { endpoint in
                        endpoint.bluetoothName.compare(UIDevice.current.name, options: .caseInsensitive) == .orderedSame
                    }
                    // 如果只有一个，则为本机
                    if filteredEndpoints.count == 1 {
                        let localBluetoothAddress = filteredEndpoints[0].address
                        UserSettings.localBluetoothAddress = localBluetoothAddress
                        // 报告给设备
                        self?.reportLocalBluetoothAddress(localBluetoothAddress) {
                            self?.doneGetNecessaryInfomation()
                        }
                    } else {
                        self?.doneGetNecessaryInfomation()
                    }
                }
            }
        }
        deviceCommManager.sendRequest(DeviceInfoRequest(Command.INFO_MULTIPOINT_INFO), completion: failureCompletion)
    }
    
    func reportLocalBluetoothAddress(_ address: String, successCompletion: @escaping () -> Void) {
        let localBluetoothAddress = Utils.addressStringToData(address)!
        let request = MultipointRequest.reportRequest(addressToReport: localBluetoothAddress)
        
        deviceCommManager.registerResponseCallable(command: Command.COMMAND_MULTIPOINT, callableType: TlvResponsePayloadHandler.self)
        deviceCommManager.sendRequest(request) { [weak self] request, result, timeout in
            self?.deviceCommManager.unregisterResponseCallable(command: Command.COMMAND_MULTIPOINT)
            
            if let res = result as? TlvResponse,
               // TODO: 目前直接判断第一个
               res.first!.value == true {
                successCompletion()
            } else {
                self?.failureCompletion(request, result, timeout)
            }
        }
    }
}

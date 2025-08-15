//
//  ABEarbuds.swift
//  ABMate
//
//  Created by Bluetrum on 2022/5/28.
//

import Foundation
import CoreBluetooth
import DeviceManager
import DequeModule
import Utils

public class ABEarbuds: ABDevice {
    
    private static let DEFAULT_AUTHENTICATION_STATE: AuthenticationState = .pass // TODO: No need to Auth for now
    
    weak var logger: LoggerDelegate? = DefaultLogger.shared
    
    // MARK: - Properties
    
    private var centralManager: CBCentralManager
    
    private var authenticationState: AuthenticationState = ABEarbuds.DEFAULT_AUTHENTICATION_STATE
    
    // MARK: - Characteristic properties
    
    // In and Out, for Device
    private var dataReadCharacteristic: CBCharacteristic?
    private var dataWriteCharacteristic: CBCharacteristic?
    private var ctkdCharacteristic:CBCharacteristic?
    
    private var requestDataQueue: Deque<RequestData> = Deque()
    
    public private(set) var btAddress: String
    
    private var connectionState: DeviceConnectionState
    public private(set) var needAuth: Bool
    
    private let _supportCTKD: Bool
    public override var supportCTKD: Bool { _supportCTKD }
    
    public override var isConnected: Bool {
        return connectionState == .connected
    }
    
    public private(set) var leftBatteryLevel: Int?
    public private(set) var leftCharging: Bool?
    public private(set) var rightBatteryLevel: Int?
    public private(set) var rightCharging: Bool?
    public private(set) var caseBatteryLevel: Int?
    public private(set) var caseCharging: Bool?
    
    // MARK: - Computed properties
    
    var isOpen: Bool {
        return dataReadCharacteristic?.isNotifying ?? false
    }
    
    // MARK: - Public API
    
    public init(peripheral: CBPeripheral, earbudsBeacon: EarbudsBeacon) {
        self.centralManager = CBCentralManager()
        self.connectionState = earbudsBeacon.connectionState
        self.needAuth = earbudsBeacon.needAuth
        self._supportCTKD = earbudsBeacon.supportCTKD
        self.btAddress = earbudsBeacon.btAddress
        // Only version 1 has battery information
        if earbudsBeacon.beaconVersion == 1 {
            let beacon = earbudsBeacon as! DeviceBeaconV1
            // Update battery information
            self.leftBatteryLevel = beacon.leftBatteryLevel
            self.rightBatteryLevel = beacon.rightBatteryLevel
            self.caseBatteryLevel = beacon.caseBatteryLevel
            self.leftCharging = beacon.leftCharging
            self.rightCharging = beacon.rightCharging
            self.caseCharging = beacon.caseCharging
        }
        super.init(peripheral: peripheral, deviceBeacon: earbudsBeacon)
        self.peripheral.delegate = self
    }
    
    public override func updateDeviceStatus(deviceBeacon: DeviceBeacon) {
        if let earbudsBeacon = deviceBeacon as? EarbudsBeacon {
            connectionState = earbudsBeacon.connectionState
            needAuth = earbudsBeacon.needAuth
        }
        // Only version 1 has battery information
        if deviceBeacon.beaconVersion == 1 {
            let beacon = deviceBeacon as! DeviceBeaconV1
            // Update battery information
            leftBatteryLevel = beacon.leftBatteryLevel
            rightBatteryLevel = beacon.rightBatteryLevel
            caseBatteryLevel = beacon.caseBatteryLevel
            leftCharging = beacon.leftCharging
            rightCharging = beacon.rightCharging
            caseCharging = beacon.caseCharging
        }
    }
    
    public override func connect() {
        discoverServices()
    }
    
    public override func startAuth() {
        if authenticationState == .idle {
            // TODO: 开始认证
        } else if authenticationState == .pass {
            connectionStateCallback?.onReceiveAuthResult(device: self, passed: true)
        }
    }
    
    public override func sendRequestData(_ requestData: RequestData) {
        requestDataQueue.append(requestData)
        nextSend()
    }
    
    private func nextSend() {
        guard let dataWriteCharacteristic = dataWriteCharacteristic else {
            return
        }
        
        if let requestData = requestDataQueue.popFirst() {
            let data = requestData.data
            
            if requestData.writeWithResponse {
                peripheral.writeValue(data, for: dataWriteCharacteristic, type: .withResponse)
                logger?.v(.abEarbuds, "writeWithResp -> \(data.hex)")
            } else {
                peripheral.writeValue(data, for: dataWriteCharacteristic, type: .withoutResponse)
                logger?.v(.abEarbuds, "writeWithoutResp -> \(data.hex)")
            }
        }
    }
    
    public override func stop() {
        authenticationState = ABEarbuds.DEFAULT_AUTHENTICATION_STATE
        requestDataQueue.removeAll()
    }
    
    public override func triggerCTKD() {
        guard supportCTKD, let ctkdCharacteristic = ctkdCharacteristic else { return }
        // 固件端通过写ctkdCharacteristic触发CTKD
        let data: Data = "CTKD".data(using: .utf8)!
        peripheral.writeValue(data, for: ctkdCharacteristic, type: .withResponse)
    }

    // MARK: - Implementation
    
    /// Starts service discovery, only given Service.
    private func discoverServices() {
        if self.centralManager.state == .poweredOn {
            peripheral.discoverServices([CompanionService.uuid])
        }
    }
    
    /// Starts characteristic discovery for Data In and Data Out Characteristics.
    ///
    /// - parameter service: The service to look for the characteristics in.
    private func discoverCharacteristics(for service: CBService) {
        let uuids: [CBUUID] = CompanionService.uuids
        peripheral.discoverCharacteristics(uuids, for: service)
    }
    
    /// Enables notification for the given characteristic.
    ///
    /// - parameter characteristic: The characteristic to enable notifications for.
    private func enableNotifications(for characteristic: CBCharacteristic) {
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
}

// MARK: - CBPeripheralDelegate

extension ABEarbuds: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if CompanionService.matches(service) {
                    logger?.v(.abEarbuds, "Service found")
                    discoverCharacteristics(for: service)
                    return
                }
            }
        }
        // Required service not found.
        logger?.e(.abEarbuds, "Device not supported")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Look for required characteristics.
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if CompanionService.dataReadUuid == characteristic.uuid {
                    logger?.v(.abEarbuds, "Data Read characteristic found")
                    dataReadCharacteristic = characteristic
                } else if CompanionService.dataWriteUuid == characteristic.uuid {
                    logger?.v(.abEarbuds, "Data Write characteristic found")
                    dataWriteCharacteristic = characteristic
                } else if CompanionService.ctkdUuid == characteristic.uuid {
                    logger?.v(.abEarbuds, "CTKD characteristic found")
                    ctkdCharacteristic = characteristic
                }
            }
        }

        // Ensure all required characteristics were found.
        guard let _ = dataWriteCharacteristic,
              let dataReadCharacteristic = dataReadCharacteristic, dataReadCharacteristic.properties.contains(.notify) else {
                logger?.e(.abEarbuds, "Device not supported")
                return
        }

        enableNotifications(for: dataReadCharacteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == dataReadCharacteristic, characteristic.isNotifying else {
            return
        }
        logger?.v(.abEarbuds, "Data In notifications enabled")

        logger?.i(.abEarbuds, "Device ready")

        connectionStateCallback?.onConnected(device: self)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // This method will not be called, if data is sent without response.
        logger?.d(.abEarbuds, "didWriteValueFor: \(String(describing: characteristic.value?.hex))")
        
        nextSend()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == dataReadCharacteristic, let data = characteristic.value else {
            return
        }
        dataDelegate?.onReceiveData(data)
    }
    
    // This method is available only on iOS 11+.
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        nextSend()
    }
    
}

extension ABEarbuds {
    
    static func == (lhs: ABEarbuds, rhs: ABEarbuds) -> Bool {
        return lhs.peripheral == rhs.peripheral
    }
    
}

extension ABEarbuds {
    
    public override var description: String {
        return """
               ABEarbuds: btAddress=\(btAddress), productId=\(productId), \
               supportCTKD=\(supportCTKD), isConnected=\(isConnected), needAuth=\(needAuth), \
               peripheral=\(peripheral)
               """
    }
    
}

//
//  BluetoothDelegate.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/17.
//

import Foundation
import CoreBluetooth

// MARK: - 蓝牙管理类事件委托协议
@objc public protocol BluetoothDelegate : NSObjectProtocol {
    
    @objc optional func didUpdateState(_ state: CBManagerState)
    
    @objc optional func didStopScanning()
    
    @objc optional func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber)
    
    @objc optional func didConnectedPeripheral(_ connectedPeripheral: CBPeripheral)
    
    @objc optional func failToConnectPeripheral(_ peripheral: CBPeripheral, error: Error?)
    
    @objc optional func didDisconnectPeripheral(_ peripheral: CBPeripheral, error: Error?)
    
    @objc optional func connectionEventDidOccur(_ event: CBConnectionEvent, for peripheral: CBPeripheral)
}

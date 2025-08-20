//
//  ScannerViewModel.swift
//  ABMate
//
//  Created by Bluetrum on 2022/4/15.
//

import Foundation
import RxRelay
import CoreBluetooth
import DeviceManager

// MARK: - 扫描VM
class ScannerViewModel: BaseViewModel {
    
    static let shared = ScannerViewModel()
    
    // MARK: - 扫描发现的设备
    func startScanning() {
        sharedDeviceRepo.startScanning()
    }
    
    func stopScanning() {
        sharedDeviceRepo.stopScanning()
    }
    
    var latestDiscoveredPeripheral: BehaviorRelay<ABDevice?> {
        return sharedDeviceRepo.latestDiscoveredDevice
    }
    
    var discoveredPeripherals: BehaviorRelay<[ABDevice]> {
        return sharedDeviceRepo.discoveredDevices
    }
}

//
//  SinglePoint.swift
//  DeviceManager
//
//  Created by Bluetrum on 2023/6/12.
//

import Foundation

public final class SinglePoint {
    
    public static let CONNECTION_STATE_DISCONNECTED: UInt8  = 0
    public static let CONNECTION_STATE_CONNECTED: UInt8     = 1
    
    private var _address: Data
    public private(set) var bluetoothName: String
    private var connectionState: UInt8
    
    public init(address: Data, bluetoothName: String, connectionState: UInt8) {
        self._address = address
        self.bluetoothName = bluetoothName
        self.connectionState = connectionState
    }
    
    public var addressBytes: Data {
        return _address
    }
    
    public var address: String {
        return String(format: "%02X:%02X:%02X:%02X:%02X:%02X",
                      _address[0], _address[1], _address[2], _address[3], _address[4], _address[5])
    }
    
    public var isConnected: Bool {
        return connectionState == SinglePoint.CONNECTION_STATE_CONNECTED
    }
}

//
//  UserSettings.swift
//  ABMate
//
//  Created by Bluetrum on 2023/6/14.
//

import Foundation

class UserSettings {
    
    private static let KEY_LOCAL_BLUETOOTH_ADDRESS = "local_bluetooth_address"
    
    public static var localBluetoothAddress: String? {
        get {
            let defaults = UserDefaults.standard
            return defaults.string(forKey: KEY_LOCAL_BLUETOOTH_ADDRESS)
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: KEY_LOCAL_BLUETOOTH_ADDRESS)
        }
    }
}

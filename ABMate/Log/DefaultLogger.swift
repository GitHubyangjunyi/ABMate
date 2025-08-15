//
//  DefaultLogger.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/14.
//

import Foundation
import Utils
import os.log

class DefaultLogger {
    static let shared = DefaultLogger()
}

// MARK: - Logger Delegate
extension DefaultLogger: LoggerDelegate {
    func log(message: String, ofCategory category: String, withLevel level: LogLevel) {
        os_log("%{public}@", log: category.log, type: level.type, message)
    }
    
}

enum LogCategory: String {
    case bluetoothManager   = "BluetoothManager"
    case deviceRepository   = "DeviceRepository"
    case abEarbuds          = "ABEarbuds"
    // VCs
    case scannerVC          = "ScanDeviceViewController"
    case mainVC             = "MainViewController"
    case homeVC             = "HomeViewController"
    case functionVC         = "FunctionViewController"
    case deviceInfosVC      = "DeviceInfosViewController"
    case ancSettingsVC      = "AncSettingsViewController"
    case equalizerVC        = "EqualizerViewController"
}

extension LogLevel {
    
    /// Mapping from log levels to system log types.
    var type: OSLogType {
        switch self {
        case .debug:       return .debug
        case .verbose:     return .debug
        case .info:        return .info
        case .application: return .default
        case .warning:     return .error
        case .error:       return .fault
        }
    }
}

extension LogCategory {
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
}

extension String {
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: self)
    }
}

extension LoggerDelegate {
    func log(message: String, ofCategory category: LogCategory, withLevel level: LogLevel) {
        log(message: message, ofCategory: category.rawValue, withLevel: level)
    }
    
    func d(_ category: LogCategory, _ message: String) {
        log(message: message, ofCategory: category, withLevel: .debug)
    }
    
    func v(_ category: LogCategory, _ message: String) {
        log(message: message, ofCategory: category, withLevel: .verbose)
    }
    
    func i(_ category: LogCategory, _ message: String) {
        log(message: message, ofCategory: category, withLevel: .info)
    }
    
    func a(_ category: LogCategory, _ message: String) {
        log(message: message, ofCategory: category, withLevel: .application)
    }
    
    func w(_ category: LogCategory, _ message: String) {
        log(message: message, ofCategory: category, withLevel: .warning)
    }
    
    func w(_ category: LogCategory, _ error: Error) {
        log(message: error.localizedDescription, ofCategory: category, withLevel: .warning)
    }
    
    func e(_ category: LogCategory, _ message: String) {
        log(message: message, ofCategory: category, withLevel: .error)
    }
    
    func e(_ category: LogCategory, _ error: Error) {
        log(message: error.localizedDescription, ofCategory: category, withLevel: .error)
    }
}

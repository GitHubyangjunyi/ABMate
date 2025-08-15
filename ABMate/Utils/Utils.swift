//
//  Utils.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/14.
//

import UIKit
import AVFoundation

class Utils {
    
    // MARK: - 设备名
    static let DEVICE_NAME_PREFIX = "AB_Mate"
    
    // MARK: - 获取FOT文件列表
    static let OTA_FILE_EXTENSION = "fot"
    
    static func fotFileList() -> [URL]? {
        if let documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: documentUrl, includingPropertiesForKeys: nil)
                // Filter
                let fotUrls = files.filter { $0.pathExtension == OTA_FILE_EXTENSION }
                return fotUrls
            } catch {
                return nil
            }
        }
        return nil
    }
    
    // MARK: - 获取音频输出端口信息
    static var audioOutputDevices: [AVAudioSessionPortDescription] {
        let session = AVAudioSession.sharedInstance()
        return session.currentRoute.outputs
    }
    
    static var currentAudioOutputDevice: AVAudioSessionPortDescription? {
        return audioOutputDevices.first
    }
    
    static var currentAudioOutputDeviceName: String? {
        return currentAudioOutputDevice?.portName
    }
    
    static var bluetoothAudioDeviceAddress: String? {
        guard let currentAudioOutputDevice = currentAudioOutputDevice else { return nil }
        // 蓝牙音频设备uid格式为“XX:XX:XX:XX:XX:XX-tacl”
        // 注意，苹果没有公开表明使用这个格式，所以目前在确定版本使用（iOS 15是OK的）
        let uid = currentAudioOutputDevice.uid
        return extractBluetootAddress(uid: uid)
    }
    
    static func extractBluetootAddress(uid: String) -> String? {
        let pattern = "([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2})"
        guard let range = uid.range(of: pattern, options: .regularExpression) else { return nil }
        var address = String(uid[range]) // 提取地址
        address.removeAll { $0 == ":" }  // 去掉冒号
        return address
    }
    
    static func addressStringToData(_ address: String) -> Data? {
        var hex = address
        hex.removeAll { $0 == ":" }
        if !hex.count.isMultiple(of: 2) {
            return nil
        }
        
        let chars = hex.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }
        
        guard hex.count / bytes.count == 2 else { return nil }
        return Data(bytes)
    }
}

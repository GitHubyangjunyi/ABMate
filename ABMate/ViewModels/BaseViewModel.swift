//
//  BaseViewModel.swift
//  ABMateDemo
//
//  Created by Bluetrum.
//  

import Foundation
import RxRelay
import DeviceManager
import CoreBluetooth

typealias SimpleRequestCompletion = (_ result: Bool?,  _ timeout: Bool) -> Void

@MainActor
class BaseViewModel {
    
    lazy var sharedDeviceRepo = DeviceRepository.shared
    lazy var deviceCommManager = sharedDeviceRepo.deviceCommManager
    
    // MARK: - 连接设备
    func connect(_ device: ABDevice) {
        sharedDeviceRepo.connect(device)
    }
    
    func disconnect() {
        sharedDeviceRepo.disconnect()
    }
    
    // MARK: - 用来检查响应是否成功
    func checkIfResponseAllSuccess(results: [UInt8: Bool]) -> Bool {
        for (_, result) in results {
            // 有一个错误就算失败
            if !result {
                return false
            }
        }
        return true
    }
    
    func checkIfResponseAtLeastOneSuccess(results: [UInt8: Bool]) -> Bool {
        for (_, result) in results {
            // 有一个成功就算成功
            if result {
                return true
            }
        }
        return false
    }
    
    // MARK: - ⚠️⚠️⚠️⚠️ViewModel发送请求入口点
    func sendRequest(_ request: Request) {
        sendRequest(request, completion: nil)
    }
    
    // MARK: - ⚠️⚠️⚠️⚠️ViewModel发送请求入口点
    func sendRequest(_ request: Request, completion: @escaping SimpleRequestCompletion) {
        sendRequestExpectAllSuccess(request, completion: completion)
    }
    
    func sendRequestExpectAllSuccess(_ request: Request, completion: @escaping SimpleRequestCompletion) {
        sendRequest(request, completion: completion, resultChecker: checkIfResponseAllSuccess)
    }
    
    func sendRequestExpectAtLeastOneSuccess(_ request: Request, completion: @escaping SimpleRequestCompletion) {
        sendRequest(request, completion: completion, resultChecker: checkIfResponseAtLeastOneSuccess)
    }
    
    func sendRequest(_ request: Request, completion: @escaping SimpleRequestCompletion, resultChecker: @escaping (_ results: [UInt8: Bool]) -> Bool) {
        sendRequest(request) { _, result, timeout in
            if timeout {
                completion(nil, true)
            } else {
                if let res = result as? Bool {
                    completion(res, false)
                }
                // TLV
                else if let res = result as? [UInt8: Bool] {
                    completion(resultChecker(res), false)
                }
            }
        }
    }
    
    func sendRequest(_ request: Request, completion: RequestCompletion?) {
        sharedDeviceRepo.sendRequest(request, completion: completion)
    }
    
    // MARK: - 当前连接设备
    var activeDevice: BehaviorRelay<ABDevice?> {
        return sharedDeviceRepo.activeDevice
    }
    
    // MARK: - 获取信息
    var devicePower: BehaviorRelay<DevicePower?> {
        return sharedDeviceRepo.devicePower
    }
    
    var deviceFirmwareVersion: BehaviorRelay<UInt32?> {
        return sharedDeviceRepo.deviceFirmwareVersion
    }
    
    var deviceName: BehaviorRelay<String?> {
        return sharedDeviceRepo.deviceName
    }
    
    var deviceEqSetting: BehaviorRelay<RemoteEqSetting?> {
        return sharedDeviceRepo.deviceEqSetting
    }
    
    var deviceKeySettings: BehaviorRelay<[KeyType: KeyFunction]?> {
        return sharedDeviceRepo.deviceKeySettings
    }
    
    var deviceVolume: BehaviorRelay<UInt8?> {
        return sharedDeviceRepo.deviceVolume
    }
    
    var devicePlayState: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.devicePlayState
    }
    
    var deviceWorkMode: BehaviorRelay<UInt8?> {
        return sharedDeviceRepo.deviceWorkMode
    }
    
    var deviceInEarStatus: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceInEarStatus
    }
    
    var deviceLanguageSetting: BehaviorRelay<UInt8?> {
        return sharedDeviceRepo.deviceLanguageSetting
    }
    
    var deviceAutoAnswer: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceAutoAnswer
    }
    
    var deviceAncMode: BehaviorRelay<UInt8?> {
        return sharedDeviceRepo.deviceAncMode
    }
    
    var deviceIsTws: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceIsTws
    }
    
    var deviceTwsConnected: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceTwsConnected
    }
    
    var deviceLedSwitch: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceLedSwitch
    }
    
    var deviceFwChecksum: BehaviorRelay<Data?> {
        return sharedDeviceRepo.deviceFwChecksum
    }
    
    var deviceAncGain: BehaviorRelay<Int?> {
        return sharedDeviceRepo.deviceAncGain
    }
    
    var deviceTransparencyGain: BehaviorRelay<Int?> {
        return sharedDeviceRepo.deviceTransparencyGain
    }
    
    var deviceAncGainNum: BehaviorRelay<Int?> {
        return sharedDeviceRepo.deviceAncGainNum
    }
    
    var deviceTransparencyGainNum: BehaviorRelay<Int?> {
        return sharedDeviceRepo.deviceTransparencyGainNum
    }
    
    var deviceRemoteEqSettings: BehaviorRelay<[RemoteEqSetting]?> {
        return sharedDeviceRepo.deviceRemoteEqSettings
    }
    
    var deviceMaxPacketSize: BehaviorRelay<UInt16?> {
        return sharedDeviceRepo.deviceMaxPacketSize
    }
    
    var deviceLeftIsMainSide: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceLeftIsMainSide
    }
    
    var deviceProductColor: BehaviorRelay<UInt8?> {
        return sharedDeviceRepo.deviceProductColor
    }
    
    var deviceSpatialAudioMode: BehaviorRelay<SpatialAudioMode?> {
        return sharedDeviceRepo.deviceSpatialAudioMode
    }
    
    var deviceMultipointStatus: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceMultipointStatus
    }
    
    var deviceMultipointInfo: BehaviorRelay<Multipoint?> {
        return sharedDeviceRepo.deviceMultipointInfo
    }
    
    var deviceVoiceRecognitionStatus: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceVoiceRecognitionStatus
    }
    
    var deviceAncFadeStatus: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceAncFadeStatus
    }
    
    var deviceBassEngineStatus: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceBassEngineStatus
    }
    
    var deviceBassEngineValue: BehaviorRelay<Int8?> {
        return sharedDeviceRepo.deviceBassEngineValue
    }
    
    var deviceBassEngineRange: BehaviorRelay<BassEngineRange?> {
        return sharedDeviceRepo.deviceBassengineRange
    }
    
    var deviceAntiWindNoise: BehaviorRelay<Bool?> {
        return sharedDeviceRepo.deviceAntiWindNoise
    }
    
    var deviceCapacities: BehaviorRelay<DeviceCapacities?> {
        return sharedDeviceRepo.deviceCapacities
    }
    
    // MARK: - Requests
    // EQ设置
    func sendEqRequest(_ request: EqRequest, completion: @escaping SimpleRequestCompletion) {
        sendRequest(request, completion: completion)
    }
    
    // Auto Shutdown
    func setAutoShutdownSetting(_ setting: AutoShutdownSetting, completion: @escaping SimpleRequestCompletion) {
        let request = AutoShutdownRequest(setting)
        sendRequest(request, completion: completion)
    }
    
    // Factory Reset
    func doFactoryReset(completion: @escaping SimpleRequestCompletion) {
        let request = FactoryResetRequest()
        sendRequest(request, completion: completion)
    }
    
    // Work Mode
    func setWorkMode(_ mode: WorkMode, completion: @escaping SimpleRequestCompletion) {
        let request = WorkModeRequest(mode)
        sendRequest(request, completion: completion)
    }
    
    // In Ear Detect
    func enableInEarDetect(_ enable: Bool, completion: @escaping SimpleRequestCompletion) {
        let request = InEarDetectRequest(enable)
        sendRequest(request, completion: completion)
    }
    
    // 语言设置
    func setLanguageSetting(_ setting: LanguageSetting, completion: @escaping SimpleRequestCompletion) {
        let request = LanguageRequest(setting)
        sendRequest(request, completion: completion)
    }
    
    // 查找设备
    func doFindDevice(_ enable: Bool, completion: @escaping SimpleRequestCompletion) {
        let request = FindDeviceRequest(enable)
        sendRequest(request, completion: completion)
    }
    
    // Auto Answer
    func enableAutoAnswer(_ enable: Bool, completion: @escaping SimpleRequestCompletion) {
        let request = AutoAnswerRequest(enable)
        sendRequest(request, completion: completion)
    }
    
    // ANC模式
    func setAncMode(_ mode: AncRequest.AncMode, completion: @escaping SimpleRequestCompletion) {
        let request = AncRequest.modeRequest(ancMode: mode)
        sendRequest(request, completion: completion)
    }
    
    // 蓝牙名称
    func setBluetoothName(_ name: String, completion: @escaping SimpleRequestCompletion) {
        let request = BluetoothNameRequest(name)
        sendRequest(request, completion: completion)
    }
    
    // LED模式
    func setLedOn(_ ledOn: Bool, completion: @escaping SimpleRequestCompletion) {
        let request = LedSwitchRequest(ledOn)
        sendRequest(request, completion: completion)
    }
    
    // Clear Pair Record
    func doClearPairRecord(completion: @escaping SimpleRequestCompletion) {
        let request = ClearPairRecordRequest()
        sendRequest(request, completion: completion)
    }
    
    // ANC Gain
    func setAncGain(_ gain: UInt8, completion: @escaping SimpleRequestCompletion) {
        let request = AncRequest.ncLevelRequest(ncLevel: gain)
        sendRequest(request, completion: completion)
    }
    
    // Transparency Gain
    func setTransparencyGain(_ gain: UInt8, completion: @escaping SimpleRequestCompletion) {
        let request = AncRequest.transparencyLevelRequest(transparencyLevel: gain)
        sendRequest(request, completion: completion)
    }
    
    // 音乐控制
    func setMusicControl(_ type: MusicControlType, completion: @escaping SimpleRequestCompletion) {
        let request = MusicControlRequest(type)
        sendRequest(request) { _, result, timeout in
            var controlResult: Bool?
            if let result = result as? TlvResponse {
                controlResult = result[request.controlType.rawValue]
            }
            completion(controlResult, timeout)
        }
    }
    
    // 按键设置
    func setKeySetting(keyType: KeyType, keyFunction: KeyFunction, completion: @escaping SimpleRequestCompletion) {
        let request = KeyRequest(keyType: keyType, keyFunction: keyFunction)
        sendRequest(request) { _, result, timeout in
            var keyResult: Bool?
            if let result = result as? TlvResponse {
                keyResult = result[request.keyType.rawValue]
            }
            completion(keyResult, timeout)
        }
    }
}

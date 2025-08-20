//
//  Defaultswift
//  DeviceManager
//
//  Created by Bluetrum on 2022/4/2.
//

import Foundation
import DeviceManager
import RxRelay

public class DefaultDeviceCommManager: DeviceCommManager {
    
    public let devicePower: BehaviorRelay<DevicePower?> = BehaviorRelay(value: nil)
    public let deviceFirmwareVersion: BehaviorRelay<UInt32?> = BehaviorRelay(value: nil)
    public let deviceName: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    public let deviceEqSetting: BehaviorRelay<RemoteEqSetting?> = BehaviorRelay(value: nil)
    public let deviceKeySettings: BehaviorRelay<[KeyType: KeyFunction]?> = BehaviorRelay(value: nil)
    public let deviceVolume: BehaviorRelay<UInt8?> = BehaviorRelay(value: nil)
    public let devicePlayState: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceWorkMode: BehaviorRelay<UInt8?> = BehaviorRelay(value: nil)
    public let deviceInEarStatus: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceLanguageSetting: BehaviorRelay<UInt8?> = BehaviorRelay(value: nil)
    public let deviceAutoAnswer: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceAncMode: BehaviorRelay<UInt8?> = BehaviorRelay(value: nil)
    public let deviceIsTws: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceTwsConnected: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceLedSwitch: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceFwChecksum: BehaviorRelay<Data?> = BehaviorRelay(value: nil)
    public let deviceAncGain: BehaviorRelay<Int?> = BehaviorRelay(value: nil)
    public let deviceTransparencyGain: BehaviorRelay<Int?> = BehaviorRelay(value: nil)
    public let deviceAncGainNum: BehaviorRelay<Int?> = BehaviorRelay(value: nil)
    public let deviceTransparencyGainNum: BehaviorRelay<Int?> = BehaviorRelay(value: nil)
    public let deviceRemoteEqSettings: BehaviorRelay<[RemoteEqSetting]?> = BehaviorRelay(value: nil)
    public let deviceLeftIsMainSide: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceProductColor: BehaviorRelay<UInt8?> = BehaviorRelay(value: nil)
    public let deviceSpatialAudioMode: BehaviorRelay<SpatialAudioMode?> = BehaviorRelay(value: nil)
    public let deviceMultipointStatus: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceMultipointInfo: BehaviorRelay<Multipoint?> = BehaviorRelay(value: nil)
    // public let deviceMultipointEvent: BehaviorRelay<Multipoint?> = BehaviorRelay(value: nil)
    public let deviceVoiceRecognitionStatus: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceAncFadeStatus: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceBassEngineStatus: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceBassEngineValue: BehaviorRelay<Int8?> = BehaviorRelay(value: nil)
    public let deviceBassEngineRange: BehaviorRelay<BassEngineRange?> = BehaviorRelay(value: nil)
    public let deviceAntiWindNoise: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
    public let deviceCapacities: BehaviorRelay<DeviceCapacities?> = BehaviorRelay(value: nil)
    
    // Request结果（如果成功）反映到DeviceInfo
    public var enableRequestToDevInfo: Bool = true
    private var requestToDeviceInfoDict: [UInt8: UInt8] = [:]
    private var tlvRequestToDeviceInfoDict: [UInt8: [UInt8: UInt8]] = [:]
    
    private var reportedLocalAddress = false
    
    public func prepare() {
        registerDefaultResponseCallables()
        registerDefaultNotificationCallables()
        registerDefaultDeviceInfoCallables()
        registerRequestToDeviceInfoDicts()
    }
    
    public override func sendRequest(_ request: Request, completion: RequestCompletion?) {
        let requestCompletion: RequestCompletion = { [weak self] request, result, timeout in
            if let completion = completion {
                completion(request, result, timeout)
                // 处理完Response，再看要不要将结果反应到DevInfo
                if !timeout, let strongSelf = self, strongSelf.enableRequestToDevInfo {
                    self?.processRequestToDevInfo(request: request, result: result!)
                }
            }
        }
        super.sendRequest(request, completion: requestCompletion)
    }
    
    @MainActor private func processRequestToDevInfo(request: Request, result: Any) {
        // Update BehaviorRelay directly, or sendRequest to get latest status
        // Here choose the first one method
        
        let command = request.getCommand()
        // ResponsePayloadHandler.self
        if let tlvRequest = request as? TlvRequest,
           let tlvResult = result as? TlvResponse {
            let tlvDataDict = tlvRequest.tlvDataDic
            
            // Key，不同按键没有对应deviceInfo，需要特殊处理
            if let keyRequest = request as? KeyRequest {
                let keyType = keyRequest.keyType
                let keyFunction = keyRequest.keyFunction
                if let keyResultSuccess = tlvResult[keyType.rawValue],
                   keyResultSuccess {
                    // Update all key settings, not only the current one
                    let newKeySetting = [keyType: keyFunction]
                    deviceKeySettingsChanged(newKeySetting)
                }
            } else {
                for (subCommand, subResult) in tlvResult {
                    // 如果命令执行成功
                    if (subResult) {
                        // 根据主命令，确定子命令对应的Info
                        if let tlvInfoType = getTlvDeviceInfoType(command: command, subCommand: subCommand),
                           let value = tlvDataDict[subCommand] {
                            processDeviceInfo(type: tlvInfoType, data: value)
                        }
                    }
                }
            }
        }
        // ResponsePayloadHandler.self
        else {
            // Get map, Command -> DevInfo
            if let infoType = getDeviceInfoType(command: command),
               let success = result as? Bool,
               success {
                processDeviceInfo(type: infoType, data: request.getPayload())
            }
        }
    }
    
    private func getDeviceInfoType(command: UInt8) -> UInt8? {
        return requestToDeviceInfoDict[command]
    }
    
    public func registerRequestToDeviceInfoDict(command: UInt8, deviceInfo: UInt8) {
        requestToDeviceInfoDict[command] = deviceInfo
    }
    
    public func unregisterRequestToDeviceInfoDict(command: UInt8) {
        requestToDeviceInfoDict[command] = nil
    }
    
    private func getTlvDeviceInfoType(command: UInt8, subCommand: UInt8) -> UInt8? {
        guard let subDict = tlvRequestToDeviceInfoDict[command] else { return nil }
        return subDict[subCommand]
    }
    
    public func registerTlvRequestToDeviceInfoDict(command: UInt8, subCommand: UInt8, deviceInfo: UInt8) {
        if var subDict = tlvRequestToDeviceInfoDict[command] {
            subDict[subCommand] = deviceInfo
            tlvRequestToDeviceInfoDict[command] = subDict
        } else {
            tlvRequestToDeviceInfoDict[command] = [subCommand: deviceInfo]
        }
    }
    
    public func unregisterTlvRequestToDeviceInfoDict(command: UInt8, subCommand: UInt8) {
        if var subDict = tlvRequestToDeviceInfoDict[command] {
            subDict[subCommand] = nil
            if subDict.count == 0 {
                tlvRequestToDeviceInfoDict[command] = nil
            } else {
                tlvRequestToDeviceInfoDict[command] = subDict
            }
        }
    }
    
    public func registerTlvRequestRangeToDeviceInfoDict(command: UInt8, subCommandRange: ClosedRange<UInt8>, deviceInfo: UInt8) {
        let lowerBound = subCommandRange.lowerBound
        let upperBound = subCommandRange.upperBound
        for i in lowerBound...upperBound {
            registerTlvRequestToDeviceInfoDict(command: command, subCommand: i, deviceInfo: deviceInfo)
        }
    }
    
    public func unregisterTlvRequestRangeToDeviceInfoDict(command: UInt8, subCommandRange: ClosedRange<UInt8>) {
        let lowerBound = subCommandRange.lowerBound
        let upperBound = subCommandRange.upperBound
        for i in lowerBound...upperBound {
            unregisterTlvRequestToDeviceInfoDict(command: command, subCommand: i)
        }
    }
    
    private func deviceKeySettingsChanged(_ newKeySettings: [KeyType: KeyFunction]) {
        if var settings = deviceKeySettings.value {
            settings.merge(newKeySettings) { (_, new) in new }
            deviceKeySettings.accept(settings)
        } else {
            deviceKeySettings.accept(newKeySettings)
        }
    }
    
    /// 注册回复数据处理类
    private func registerDefaultResponseCallables() {
        registerResponseCallables([
            Command.COMMAND_DEVICE_INFO:        ResponsePayloadHandler.self,
            Command.COMMAND_EQ:                 ResponsePayloadHandler.self,
            Command.COMMAND_AUTO_SHUTDOWN:      ResponsePayloadHandler.self,
            Command.COMMAND_FACTORY_RESET:      ResponsePayloadHandler.self,
            Command.COMMAND_WORK_MODE:          ResponsePayloadHandler.self,
            Command.COMMAND_IN_EAR_DETECT:      ResponsePayloadHandler.self,
            Command.COMMAND_LANGUAGE:           ResponsePayloadHandler.self,
            Command.COMMAND_FIND_DEVICE:        ResponsePayloadHandler.self,
            Command.COMMAND_AUTO_ANSWER:        ResponsePayloadHandler.self,
            Command.COMMAND_BLUETOOTH_NAME:     ResponsePayloadHandler.self,
            Command.COMMAND_LED_MODE:           ResponsePayloadHandler.self,
            Command.COMMAND_CLEAR_PAIR_RECORD:  ResponsePayloadHandler.self,
            Command.COMMAND_SPATIAL_AUDIO_MODE: ResponsePayloadHandler.self,
            Command.COMMAND_ANTI_WIND_NOISE:    ResponsePayloadHandler.self,
            Command.COMMAND_MUSIC_CONTROL:      TlvResponsePayloadHandler.self,
            Command.COMMAND_KEY:                TlvResponsePayloadHandler.self,
            Command.COMMAND_MULTIPOINT:         TlvResponsePayloadHandler.self,
            Command.COMMAND_ANC:                TlvResponsePayloadHandler.self,
            Command.COMMAND_BASS_ENGINE:        TlvResponsePayloadHandler.self,
        ])
    }
    
    /// 注册设备上传通知的处理类和回调
    /// callableType可以替换成自己想要的处理方法和结果
    private func registerDefaultNotificationCallables() {
        registerNotificationCallback(Command.NOTIFICATION_DEVICE_POWER, callableType: PowerPayloadHandler.self)           { self.devicePower.accept($0 as? DevicePower) }
        registerNotificationCallback(Command.NOTIFICATION_EQ_SETTING, callableType: RemoteEqSettingPayloadHandler.self)   { self.deviceEqSetting.accept($0 as? RemoteEqSetting) }
        registerNotificationCallback(Command.NOTIFICATION_KEY_SETTINGS, callableType: KeyPayloadHandler.self)             { self.deviceKeySettings.accept($0 as? [KeyType: KeyFunction]) }
        registerNotificationCallback(Command.NOTIFICATION_DEVICE_VOLUME, callableType: UInt8PayloadHandler.self)          { self.deviceVolume.accept($0 as? UInt8) }
        registerNotificationCallback(Command.NOTIFICATION_PLAY_STATE, callableType: BoolPayloadHandler.self)              { self.devicePlayState.accept($0 as? Bool) }
        registerNotificationCallback(Command.NOTIFICATION_WORK_MODE, callableType: UInt8PayloadHandler.self)              { self.deviceWorkMode.accept($0 as? UInt8) }
        registerNotificationCallback(Command.NOTIFICATION_IN_EAR_STATUS, callableType: BoolPayloadHandler.self)           { self.deviceInEarStatus.accept($0 as? Bool) }
        registerNotificationCallback(Command.NOTIFICATION_LANGUAGE_SETTING, callableType: UInt8PayloadHandler.self)       { self.deviceLanguageSetting.accept($0 as? UInt8) }
        registerNotificationCallback(Command.NOTIFICATION_ANC_MODE, callableType: UInt8PayloadHandler.self)               { self.deviceAncMode.accept($0 as? UInt8) }
        registerNotificationCallback(Command.NOTIFICATION_TWS_CONNECTED, callableType: BoolPayloadHandler.self)           { self.deviceTwsConnected.accept($0 as? Bool) }
        registerNotificationCallback(Command.NOTIFICATION_LED_SWITCH, callableType: BoolPayloadHandler.self)              { self.deviceLedSwitch.accept($0 as? Bool) }
        registerNotificationCallback(Command.NOTIFICATION_ANC_GAIN, callableType: UInt8ToIntPayloadHandler.self)          { self.deviceAncGain.accept($0 as? Int) }
        registerNotificationCallback(Command.NOTIFICATION_TRANSPARENCY_GAIN, callableType: UInt8ToIntPayloadHandler.self) { self.deviceTransparencyGain.accept($0 as? Int) }
        registerNotificationCallback(Command.NOTIFICATION_MAIN_SIDE, callableType: BoolPayloadHandler.self)               { self.deviceLeftIsMainSide.accept($0 as? Bool) }
        registerNotificationCallback(Command.NOTIFICATION_SPATIAL_AUDIO_MODE, callableType: SpatialAudioModePayloadHandler.self) { self.deviceSpatialAudioMode.accept($0 as? SpatialAudioMode) }
        registerNotificationCallback(Command.NOTIFICATION_MULTIPOINT_STATUS, callableType: BoolPayloadHandler.self)       { self.deviceMultipointStatus.accept($0 as? Bool) }
        registerNotificationCallback(Command.NOTIFICATION_MULTIPOINT_INFO, callableType: MultipointPayloadHandler.self)   { self.deviceMultipointInfo.accept($0 as? Multipoint) }
        registerNotificationCallback(Command.NOTIFICATION_VOICE_RECOGNITION, callableType: BoolPayloadHandler.self)       { self.deviceVoiceRecognitionStatus.accept($0 as? Bool) }
        registerNotificationCallback(Command.NOTIFICATION_BASS_ENGINE_STATUS, callableType: BoolPayloadHandler.self)      { self.deviceBassEngineStatus.accept($0 as? Bool) }
        registerNotificationCallback(Command.NOTIFICATION_ANTI_WIND_NOISE, callableType: BoolPayloadHandler.self)         { self.deviceAntiWindNoise.accept($0 as? Bool) }
    }
    
    /// 注册获取设备信息的处理类和回调
    /// callableType可以替换成自己想要的处理方法和结果
    private func registerDefaultDeviceInfoCallables() {
        registerDeviceInfoCallback(Command.INFO_DEVICE_POWER, callableType: PowerPayloadHandler.self)                   { self.devicePower.accept($0 as? DevicePower) }
        registerDeviceInfoCallback(Command.INFO_FIRMWARE_VERSION, callableType: UInt32PayloadHandler.self)              { self.deviceFirmwareVersion.accept($0 as? UInt32) }
        registerDeviceInfoCallback(Command.INFO_BLUETOOTH_NAME, callableType: StringPayloadHandler.self)                { self.deviceName.accept($0 as? String) }
        registerDeviceInfoCallback(Command.INFO_EQ_SETTING, callableType: RemoteEqSettingPayloadHandler.self)           { self.deviceEqSetting.accept($0 as? RemoteEqSetting) }
        registerDeviceInfoCallback(Command.INFO_KEY_SETTINGS, callableType: KeyPayloadHandler.self)                     { self.deviceKeySettings.accept($0 as? [KeyType: KeyFunction]) }
        registerDeviceInfoCallback(Command.INFO_DEVICE_VOLUME, callableType: UInt8PayloadHandler.self)                  { self.deviceVolume.accept($0 as? UInt8) }
        registerDeviceInfoCallback(Command.INFO_PLAY_STATE, callableType: BoolPayloadHandler.self)                      { self.devicePlayState.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_WORK_MODE, callableType: UInt8PayloadHandler.self)                      { self.deviceWorkMode.accept($0 as? UInt8) }
        registerDeviceInfoCallback(Command.INFO_IN_EAR_STATUS, callableType: BoolPayloadHandler.self)                   { self.deviceInEarStatus.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_LANGUAGE_SETTING, callableType: UInt8PayloadHandler.self)               { self.deviceLanguageSetting.accept($0 as? UInt8) }
        registerDeviceInfoCallback(Command.INFO_AUTO_ANSWER, callableType: BoolPayloadHandler.self)                     { self.deviceAutoAnswer.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_ANC_MODE, callableType: UInt8PayloadHandler.self)                       { self.deviceAncMode.accept($0 as? UInt8) }
        registerDeviceInfoCallback(Command.INFO_IS_TWS, callableType: BoolPayloadHandler.self)                          { self.deviceIsTws.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_TWS_CONNECTED, callableType: BoolPayloadHandler.self)                   { self.deviceTwsConnected.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_LED_SWITCH, callableType: BoolPayloadHandler.self)                      { self.deviceLedSwitch.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_FW_CHECKSUM, callableType: FirmwareChecksumPayloadHandler.self)         { self.deviceFwChecksum.accept($0 as? Data) }
        registerDeviceInfoCallback(Command.INFO_ANC_GAIN, callableType: UInt8ToIntPayloadHandler.self)                  { self.deviceAncGain.accept($0 as? Int) }
        registerDeviceInfoCallback(Command.INFO_TRANSPARENCY_GAIN, callableType: UInt8ToIntPayloadHandler.self)         { self.deviceTransparencyGain.accept($0 as? Int) }
        registerDeviceInfoCallback(Command.INFO_ANC_GAIN_NUM, callableType: UInt8ToIntPayloadHandler.self)              { self.deviceAncGainNum.accept($0 as? Int) }
        registerDeviceInfoCallback(Command.INFO_TRANSPARENCY_GAIN_NUM, callableType: UInt8ToIntPayloadHandler.self)     { self.deviceTransparencyGainNum.accept($0 as? Int) }
        registerDeviceInfoCallback(Command.INFO_ALL_EQ_SETTINGS, callableType: RemoteEqSettingsPayloadHandler.self)     { self.deviceRemoteEqSettings.accept($0 as? [RemoteEqSetting]) }
        registerDeviceInfoCallback(Command.INFO_MAIN_SIDE, callableType: BoolPayloadHandler.self)                       { self.deviceLeftIsMainSide.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_PRODUCT_COLOR, callableType: UInt8PayloadHandler.self)                  { self.deviceProductColor.accept($0 as? UInt8) }
        registerDeviceInfoCallback(Command.INFO_SPATIAL_AUDIO_MODE, callableType: SpatialAudioModePayloadHandler.self)  { self.deviceSpatialAudioMode.accept($0 as? SpatialAudioMode) }
        registerDeviceInfoCallback(Command.INFO_MULTIPOINT_STATUS, callableType: BoolPayloadHandler.self)               { self.deviceMultipointStatus.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_MULTIPOINT_INFO, callableType: MultipointPayloadHandler.self)           { self.deviceMultipointInfo.accept($0 as? Multipoint) }
        registerDeviceInfoCallback(Command.INFO_VOICE_RECOGNITION, callableType: BoolPayloadHandler.self)               { self.deviceVoiceRecognitionStatus.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_ANC_FADE_STATUS, callableType: BoolPayloadHandler.self)                 { self.deviceAncFadeStatus.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_BASS_ENGINE_STATUS, callableType: BoolPayloadHandler.self)              { self.deviceBassEngineStatus.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_BASS_ENGINE_VALUE, callableType: Int8PayloadHandler.self)               { self.deviceBassEngineValue.accept($0 as? Int8) }
        registerDeviceInfoCallback(Command.INFO_BASS_ENGINE_RANGE, callableType: BassEngineRangePayloadHandler.self)    { self.deviceBassEngineRange.accept($0 as? BassEngineRange) }
        registerDeviceInfoCallback(Command.INFO_ANTI_WIND_NOISE, callableType: BoolPayloadHandler.self)                 { self.deviceAntiWindNoise.accept($0 as? Bool) }
        registerDeviceInfoCallback(Command.INFO_DEVICE_CAPABILITIES, callableType: DeviceCapacitiesPayloadHandler.self) { self.deviceCapacities.accept($0 as? DeviceCapacities) }
    }
    
    public func registerRequestToDeviceInfoDicts() {
        registerRequestToDeviceInfoDict(command: Command.COMMAND_EQ, deviceInfo: Command.INFO_EQ_SETTING)
        registerRequestToDeviceInfoDict(command: Command.COMMAND_WORK_MODE, deviceInfo: Command.INFO_WORK_MODE)
        registerRequestToDeviceInfoDict(command: Command.COMMAND_IN_EAR_DETECT, deviceInfo: Command.INFO_IN_EAR_STATUS)
        registerRequestToDeviceInfoDict(command: Command.COMMAND_LANGUAGE, deviceInfo: Command.INFO_LANGUAGE_SETTING)
        registerRequestToDeviceInfoDict(command: Command.COMMAND_AUTO_ANSWER, deviceInfo: Command.INFO_AUTO_ANSWER)
        registerRequestToDeviceInfoDict(command: Command.COMMAND_BLUETOOTH_NAME, deviceInfo: Command.INFO_BLUETOOTH_NAME)
        registerRequestToDeviceInfoDict(command: Command.COMMAND_LED_MODE, deviceInfo: Command.INFO_LED_SWITCH)
        registerRequestToDeviceInfoDict(command: Command.COMMAND_SPATIAL_AUDIO_MODE, deviceInfo: Command.INFO_SPATIAL_AUDIO_MODE)
        registerRequestToDeviceInfoDict(command: Command.COMMAND_ANTI_WIND_NOISE, deviceInfo: Command.INFO_ANTI_WIND_NOISE)
        
        registerTlvRequestToDeviceInfoDict(command: Command.COMMAND_MUSIC_CONTROL, subCommand: MusicControlType.volume(0).rawValue, deviceInfo: Command.INFO_DEVICE_VOLUME)
        registerTlvRequestToDeviceInfoDict(command: Command.COMMAND_MULTIPOINT, subCommand: MultipointRequest.STATUS, deviceInfo: Command.INFO_MULTIPOINT_STATUS)
        registerTlvRequestToDeviceInfoDict(command: Command.COMMAND_ANC, subCommand: MultipointRequest.STATUS, deviceInfo: Command.INFO_ANC_MODE)
        registerTlvRequestToDeviceInfoDict(command: Command.COMMAND_ANC, subCommand: MultipointRequest.CONNECT, deviceInfo: Command.INFO_ANC_GAIN)
        registerTlvRequestToDeviceInfoDict(command: Command.COMMAND_ANC, subCommand: MultipointRequest.DISCONNECT, deviceInfo: Command.INFO_TRANSPARENCY_GAIN)
        registerTlvRequestToDeviceInfoDict(command: Command.COMMAND_ANC, subCommand: MultipointRequest.UNPAIR, deviceInfo: Command.INFO_ANC_FADE_STATUS)
        registerTlvRequestToDeviceInfoDict(command: Command.COMMAND_BASS_ENGINE, subCommand: BassEngineRequest.BASS_ENGINE_STATUS, deviceInfo: Command.INFO_BASS_ENGINE_STATUS)
        registerTlvRequestToDeviceInfoDict(command: Command.COMMAND_BASS_ENGINE, subCommand: BassEngineRequest.BASS_ENGINE_VALUE, deviceInfo: Command.INFO_BASS_ENGINE_VALUE)
        // Key
        registerTlvRequestRangeToDeviceInfoDict(command: Command.COMMAND_KEY, subCommandRange: KeyType.leftSingleTap.rawValue...KeyType.rightLongPress.rawValue, deviceInfo: Command.INFO_KEY_SETTINGS)
    }
    
    public func resetDeviceStatus() {
        devicePower.accept(nil)
        deviceFirmwareVersion.accept(nil)
        deviceName.accept(nil)
        deviceEqSetting.accept(nil)
        deviceKeySettings.accept(nil)
        deviceVolume.accept(nil)
        devicePlayState.accept(nil)
        deviceWorkMode.accept(nil)
        deviceInEarStatus.accept(nil)
        deviceLanguageSetting.accept(nil)
        deviceAutoAnswer.accept(nil)
        deviceAncMode.accept(nil)
        deviceIsTws.accept(nil)
        deviceTwsConnected.accept(nil)
        deviceLedSwitch.accept(nil)
        deviceFwChecksum.accept(nil)
        deviceAncGain.accept(nil)
        deviceTransparencyGain.accept(nil)
        deviceAncGainNum.accept(nil)
        deviceTransparencyGainNum.accept(nil)
        deviceRemoteEqSettings.accept(nil)
        deviceLeftIsMainSide.accept(nil)
        deviceProductColor.accept(nil)
        deviceSpatialAudioMode.accept(nil)
        deviceMultipointStatus.accept(nil)
        deviceMultipointInfo.accept(nil)
        // deviceMultipointEvent.accept(nil)
        deviceVoiceRecognitionStatus.accept(nil)
        deviceAncFadeStatus.accept(nil)
        deviceBassEngineStatus.accept(nil)
        deviceBassEngineValue.accept(nil)
        deviceBassEngineRange.accept(nil)
        deviceAntiWindNoise.accept(nil)
        deviceCapacities.accept(nil)
    }
}

//
//  PresetEqSetting.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/25.
//

import Foundation

class PresetEqSetting: EqSetting {
    
    private static let eqGainsDefault: [Int8] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ]
    private static let eqGainsPop: [Int8]     = [ 3, 1, 0, -2, -4, -4, -2, 0, 1, 2, ]
    private static let eqGainsRock: [Int8]    = [ -2, 0, 2, 4, -2, -2, 0, 0, 4, 4, ]
    private static let eqGainsJazz: [Int8]    = [ 0, 0, 0, 4, 4, 4, 0, 2, 3, 4, ]
    private static let eqGainsClassic: [Int8] = [ 0, 8, 8, 4, 0, 0, 0, 0, 2, 2, ]
    private static let eqGainsCountry: [Int8] = [ -2, 0, 0, 2, 2, 0, 0, 0, 4, 4, ]
    
    public static let eqSettingDefault = PresetEqSetting(name: "eq_setting_default".localized, gains: eqGainsDefault)
    public static let eqSettingPop     = PresetEqSetting(name: "eq_setting_pop".localized, gains: eqGainsPop)
    public static let eqSettingRock    = PresetEqSetting(name: "eq_setting_rock".localized, gains: eqGainsRock)
    public static let eqSettingJazz    = PresetEqSetting(name: "eq_setting_jazz".localized, gains: eqGainsJazz)
    public static let eqSettingClassic = PresetEqSetting(name: "eq_setting_classic".localized, gains: eqGainsClassic)
    public static let eqSettingCountry = PresetEqSetting(name: "eq_setting_country".localized, gains: eqGainsCountry)
    // Flag
    public static let eqSettingAdd     = PresetEqSetting(name: "eq_setting_add", gains: eqGainsDefault)
    
    private override init(name: String, gains: [Int8]) {
        super.init(name: name, gains: gains)
        isCustom = false
    }
    
    public static var allPresetEqSettings: [EqSetting] {
        return [
            eqSettingDefault,
            eqSettingPop,
            eqSettingRock,
            eqSettingJazz,
            eqSettingClassic,
            eqSettingCountry,
        ]
    }
    
}

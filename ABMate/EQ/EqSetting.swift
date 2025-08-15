//
//  EqSetting.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/25.
//

import Foundation

class EqSetting {
    
    public static let EQUALIZER_VIEW_MAX_VALUE: Int = 12 // 均衡器±最大增益
    
    var name: String
    var gains: [Int8]
    var isCustom: Bool = true
    
    init(name: String, gains: [Int8]) {
        self.name = name
        self.gains = gains
    }
    
}

extension EqSetting {
    
    convenience init(from setting: EqSavedSetting) {
        let name = setting.name!
        let gains = setting.gains!.map { Int8(bitPattern: $0) }
        self.init(name: name, gains: gains)
    }
    
}

extension Array where Element == EqSavedSetting {
    
    func convertToEqSettings() -> [EqSetting] {
        return map { EqSetting(from: $0) }
    }
    
}

extension EqSetting: Equatable {
    
    static func == (lhs: EqSetting, rhs: EqSetting) -> Bool {
        return lhs.name == rhs.name && lhs.isCustom == rhs.isCustom && lhs.gains == rhs.gains
    }
    
}

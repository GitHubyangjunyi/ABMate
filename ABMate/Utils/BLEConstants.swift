//
//  BLEConstants.swift
//  ABMateDemo
//
//  Created by Bluetrum.
//  

import Foundation
import CoreBluetooth

// MARK: - Companion service identifires
struct CompanionService {
    public static let uuid          = CBUUID(string: "FDB3")
    public static let dataWriteUuid = CBUUID(string: "FF17")
    public static let dataReadUuid  = CBUUID(string: "FF18")
    public static let ctkdUuid      = CBUUID(string: "FF20")
    
    public static let uuids: [CBUUID] = [dataWriteUuid, dataReadUuid, ctkdUuid]
    
    public static func matches(_ service: CBService) -> Bool {
        return service.isCompanionService
    }
    
    private init() {}
}

extension CBService {
    var isCompanionService: Bool {
        return uuid == CompanionService.uuid
    }
}

extension CBCharacteristic {
    var isCompanionDataWriteCharacteristic: Bool {
        return uuid == CompanionService.dataWriteUuid
    }
    
    var isCompanionDataReadCharacteristic: Bool {
        return uuid == CompanionService.dataReadUuid
    }
}

extension UInt16 {
    var isBluetrumId: Bool {
        return self == 0x0642
    }
}

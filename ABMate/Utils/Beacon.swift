//
//  Beacon.swift
//  ABMateDemo
//
//  Created by Bluetrum.
//  

import Foundation
import CoreBluetooth
import DeviceManager

public extension Dictionary where Key == String, Value == Any {
    
    /// Returns the value under the Complete or Shortened Local Name
    /// from the advertising packet, or `nil` if such doesn't exist.
    var localName: String? {
        return self[CBAdvertisementDataLocalNameKey] as? String
    }
    
    var manufacturerData: Data? {
        guard let manufacturerData = self[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return nil
        }
        return manufacturerData
    }
    
    func manufacturerData(companyId: UInt16) -> Data? {
        guard let data = self[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return nil
        }
        return data.manufacturerData(companyId: companyId)
    }
}

extension CBUUID {
    /// Converts the CBUUID to foundation UUID.
    var uuid: UUID {
        return data.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }
}

extension Data {
    func manufacturerData(companyId: UInt16) -> Data? {
        guard self.count >= 2, companyId == self.read() else {
            return nil
        }
        if self.count == 2 {
            return Data()
        }
        return self.subdata(in: 2..<self.count)
    }
}

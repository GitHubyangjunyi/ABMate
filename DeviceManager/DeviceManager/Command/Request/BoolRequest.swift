//
//  BoolRequest.swift
//  DeviceManager
//
//  Created by Bluetrum on 2023/4/26.
//

import Foundation

/// Used as abstract class for Bool Request
public class BoolRequest: Request {
    
    public private(set) var enable: Bool
    
    public init(_ command: UInt8, _ enable: Bool) {
        self.enable = enable
        super.init(command)
    }
    
    public override func getPayload() -> Data {
        let value: UInt8 = enable ? 0x01 : 0x00
        return Data([value])
    }
}

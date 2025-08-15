//
//  Multipoint.swift
//  DeviceManager
//
//  Created by Bluetrum on 2023/6/12.
//

import Foundation

public final class Multipoint {
    
    public let endpoints: [SinglePoint]
    
    public init(endpoints: [SinglePoint]) {
        self.endpoints = endpoints
    }
}

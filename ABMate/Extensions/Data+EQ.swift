//
//  Data+EQ.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/26.
//

import Foundation

extension Data {
    
    var eqInfo: (bandnum: Int, eqMode: UInt8, gains: [Int8])? {
        guard self.count >= 2 else {
            return nil
        }
        
        let bandnum = Int(self[0])
        if bandnum != self.count - 2 {
            return nil
        }
        let eqMode = self[1]
        let gains: [Int8] = self.subdata(in: 2..<self.count).map({ Int8(bitPattern: $0) })
        return (bandnum, eqMode, gains)
    }
}

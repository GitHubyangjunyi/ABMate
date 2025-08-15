//
//  ResponseHandler.swift
//  DeviceManager
//
//  Created by Bluetrum.
//  

import Foundation
import Utils

protocol ResponseHandlerDelegate: AnyObject {
    func didReceiveNotification(_ notification: Notification)
    func didReceiveResponse(_ response: Response)
    func onError(_ error: ResponseError)
}

class ResponseHandler {
    
    private static let HEAD_SIZE = 5
    
    private var expectedSeqNum: UInt8
    private let merger: ResponseMerger
    
    weak var delegate: ResponseHandlerDelegate?
    
    init(merger: ResponseMerger) {
        expectedSeqNum = 0
        self.merger = merger
        merger.delegate = self
    }
    
    convenience init() {
        self.init(merger: ResponseMerger())
    }
    
    func handleFrameData(_ frameData: Data) {
        DispatchQueue.global().async {
            // 检查包结构，按照结构拆包
            // （如果不符合条件，先不记录SeqNum）
            if frameData.count > ResponseHandler.HEAD_SIZE {
                let bb = ByteBuffer.wrap(frameData)
                let byte0 = bb.get()
                let seqNum = byte0 & 0xF
                
                if seqNum == self.expectedSeqNum {
                    
                    self.expectedSeqNum = (self.expectedSeqNum + 1) & 0xF
                    
                    let cmd = bb.get()
                    let cmdType = bb.get()
                    let byte3 = bb.get()
                    let frameSeq = byte3 & 0xF
                    let totalFrame = ((byte3 >> 4) & 0xF) + 1
                    let frameLen = bb.get()
                    
                    // Check payload length
                    if frameLen == bb.remainning {
                        var payload = Data(count: Int(frameLen))
                        bb.get(&payload)
                        let _ = self.merger.merge(command: cmd, commandType: cmdType, payload: payload, total: Int(totalFrame), index: Int(frameSeq))
                    } else {
                        print("The length of payload mismatch: Expected \(frameLen) but got \(bb.remainning)")
                    }
                } else {
                    print("Frame seq mismatch: Expected \(self.expectedSeqNum) but got \(seqNum)")
                    self.expectedSeqNum = (seqNum + 1) & 0xF
                }
            } else {
                print("The length of received data is too short")
            }
        }
    }
    
    func reset() {
        expectedSeqNum = 0
        merger.reset()
    }
    
}

extension ResponseHandler: ResponseMergerDelegate {
    
    func didReceiveNotification(_ notification: Notification) {
        delegate?.didReceiveNotification(notification)
    }
    
    func didReceiveResponse(_ response: Response) {
        delegate?.didReceiveResponse(response)
    }
    
    func onError(_ error: ResponseError) {
        delegate?.onError(error)
    }
    
}

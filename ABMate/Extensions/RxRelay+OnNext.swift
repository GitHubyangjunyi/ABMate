//
//  RxRelay+OnNext.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/23.
//

import Foundation
import RxSwift
import RxRelay

extension BehaviorRelay {
    public func subscribeOnNext(_ onNext: @escaping (Element) -> Void) -> Disposable {
        return subscribe(onNext: onNext)
    }
}

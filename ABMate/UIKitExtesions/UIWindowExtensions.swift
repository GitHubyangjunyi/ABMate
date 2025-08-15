//
//  UIWindowExtensions.swift
//  ABMate
//
//  Created by 杨俊艺 on 2025/8/15.
//

import UIKit

extension UIWindow {
    
    static var key: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

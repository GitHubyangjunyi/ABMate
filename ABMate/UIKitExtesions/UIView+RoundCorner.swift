//
//  UIView+RoundCorner.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/24.
//

import UIKit

extension UIView {
    func roundCorners(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

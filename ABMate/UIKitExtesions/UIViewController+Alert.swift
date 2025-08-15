//
//  UIViewControll+Alert.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/21.
//

import UIKit

extension UIViewController {
    
    func presentAlert(title: String?, message: String?, cancelable: Bool = false, option action: UIAlertAction? = nil, handler: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: cancelable ? "cancel".localized : "ok".localized, style: .cancel, handler: handler))
            if let action = action {
                alert.addAction(action)
            }
            self.present(alert, animated: true)
        }
    }
}

//
//  HomeViewController.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/15.
//

import UIKit
import SnapKit
import RxSwift
import DeviceManager

extension HomeViewController {
    private var containerBackgroundColor: UIColor { .white }
    private var powerUiMargin: CGFloat { 8 }
}

// MARK: - 主页设备控制器
class HomeViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let viewModel = SharedViewModel.shared  // 全局共享VM
    
    private var powerUI: PowerUI!
    private var noDeviceImageView: NoManagedDeviceView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = containerBackgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "items"), style: .plain, target: self, action: #selector(openDeviceInfoView))
        
        powerUI = .init()
        powerUI.leftSideImage = UIImage(named: "earbuds_left")
        powerUI.rightSideImage = UIImage(named: "earbuds_right")
        powerUI.caseImage = UIImage(named: "earbuds_case")
        view.addSubview(powerUI)
        powerUI.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide).inset(powerUiMargin)
        }
        
        noDeviceImageView = NoManagedDeviceView()
        view.addSubview(noDeviceImageView)
        noDeviceImageView.snp.makeConstraints { make in
            make.edges.equalTo(powerUI)
        }
        
        viewModel.devicePower.subscribeOnNext { [unowned self] in
            if let devicePower = $0 {
                self.powerUI.leftBatteryLevel = devicePower.leftSidePower?.powerLevel
                self.powerUI.rightBatteryLevel = devicePower.rightSidePower?.powerLevel
                self.powerUI.caseBatteryLevel = devicePower.casePower?.powerLevel
                
                // 展示已经连接的设备
                noDeviceImageView.isHidden = true
                powerUI.alpha = 0
                powerUI.isHidden = false
                UIView.animate(withDuration: 0.5) {
                    self.powerUI.alpha = 1
                }
            } else {
                self.powerUI.leftBatteryLevel = nil
                self.powerUI.rightBatteryLevel = nil
                self.powerUI.caseBatteryLevel = nil
                // Show no connected device
                powerUI.isHidden = true
                noDeviceImageView.isHidden = false
            }
        }.disposed(by: disposeBag)
        
        viewModel.activeDevice.subscribeOnNext { [unowned self] in
            if let _ = $0 {
                self.showDisconnectButton()
                navigationItem.leftBarButtonItem?.isEnabled = true
            } else {
                self.showScanButton()
                navigationItem.leftBarButtonItem?.isEnabled = false
            }
        }.disposed(by: disposeBag)
    }
    
    // MARK: - 左边打开设备信息页面
    @objc private func openDeviceInfoView() {
        let vc = DeviceViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showScanButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "device_scan".localized, style: .plain, target: self, action: #selector(tapScanButton))
    }
    
    private func showDisconnectButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "device_disconnect".localized, style: .plain, target: self, action: #selector(tapDisconnectButton))
    }
    
    @objc private func tapScanButton() {
        let vc = ScanDeviceViewController()
        vc.delegate = connectDevice
        if let nc = navigationController {
            nc.pushViewController(vc, animated: true)
        } else {
            let navC = UINavigationController(rootViewController: vc)
            present(navC, animated: true, completion: nil)
        }
    }
    
    @objc private func tapDisconnectButton() {
        viewModel.disconnect()
    }
    
    private func connectDevice(_ device: ABDevice) {
        viewModel.connect(device)
    }
}

//
//  ScanDeviceViewController.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/14.
//

import UIKit
import CoreBluetooth
import Then
import SnapKit
import Utils
import RxSwift
import Toaster
import AVFoundation
import DeviceManager

let SCAN_TIMEOUT: TimeInterval = 10

// MARK: - 搜索设备控制器
class ScanDeviceViewController: UIViewController {
    
    func dealloc() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc private func exit() {
        if let nc = navigationController {
            nc.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    private let pairingTimeout: TimeInterval = 10
    private let pairingTimeoutQueue: DispatchQueue = DispatchQueue(label: "PAIRING_TIMEOUT")
    
    private let viewModel = ScannerViewModel.shared
    private let disposeBag = DisposeBag()
    
    private var tableView: UITableView!
    private var refreshControl: UIRefreshControl!       // 表格视图下拉刷新控件
    
    private var timeoutLabel: UILabel!                  // 没有发现任何设备提示视图
    private var discoveredDevices: [ABDevice] = []      // 已经发现的外设
    
    private var startScanButton: UIBarButtonItem!       // 右上角开始暂停扫描按钮
    private var stopScanButton: UIBarButtonItem!
    private var scanIndicator: UIActivityIndicatorView! // 扫描转圈指示器
    private var scanIndicatorItem: UIBarButtonItem!
    
    private var pairingGuideView: UIView!               // 引导配对视图
    
    var delegate: ((ABDevice) -> Void)?
    weak var logger: LoggerDelegate? = DefaultLogger.shared
    private var pairingDevice: ABDevice? = nil
    private var pairingTimeoutHandler: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "scanner_title".localized
        
        if navigationController == nil {
            let leftButton = UIBarButtonItem(title: "quit".localized, style: .plain, target: self, action: #selector(exit))
            navigationItem.leftBarButtonItem = leftButton
        }
        
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .white
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(startScanningDeviceIfNeeded), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        timeoutLabel = UILabel()
        timeoutLabel.sizeToFit()
        timeoutLabel.isHidden = true
        timeoutLabel.textColor = .red
        timeoutLabel.text = "device_not_found".localized
        view.addSubview(timeoutLabel)
        timeoutLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // MARK: - 配置导航栏上功能按钮
        scanIndicator = UIActivityIndicatorView(style: .medium)
        scanIndicator.isHidden = true
        // 如果有navigationController则放到右上角显示没有则放在视图中间
        if let _ = navigationController {
            startScanButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(startScanningDeviceIfNeeded))
            stopScanButton = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(stopScanning))
            scanIndicatorItem = UIBarButtonItem(customView: scanIndicator)
            navigationItem.rightBarButtonItems = [startScanButton, stopScanButton, scanIndicatorItem]
        } else {
            view.addSubview(scanIndicator)
            scanIndicator.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
        
        // 引导配对视图
        self.pairingGuideView = {
            let coverView = UIView(frame: UIScreen.main.bounds)
            coverView.backgroundColor = .black
            
            let guideLabel = UILabel()
            guideLabel.text = "pairing_guide_description".localized
            guideLabel.textColor = .yellow
            guideLabel.numberOfLines = 0
            guideLabel.sizeToFit()
            guideLabel.translatesAutoresizingMaskIntoConstraints = false
            
            coverView.addSubview(guideLabel)
            let xConstraint = NSLayoutConstraint(item: guideLabel, attribute: .centerX, relatedBy: .equal, toItem: coverView, attribute: .centerX, multiplier: 1.0, constant: 0)
            let yConstraint = NSLayoutConstraint(item: guideLabel, attribute: .centerY, relatedBy: .equal, toItem: coverView, attribute: .centerY, multiplier: 1.0, constant: 0)
            let leadingConstrait = NSLayoutConstraint(item: guideLabel, attribute: .leading, relatedBy: .equal, toItem: coverView, attribute: .leadingMargin, multiplier: 1.0, constant: 0)
            let trailingConstrait = NSLayoutConstraint(item: guideLabel, attribute: .trailing, relatedBy: .equal, toItem: coverView, attribute: .trailingMargin, multiplier: 1.0, constant: 0)
            coverView.addConstraints([xConstraint, yConstraint, leadingConstrait, trailingConstrait])
            return coverView
        }()
        
        viewModel.latestDiscoveredPeripheral.subscribeOnNext { [unowned self] in
            if let device = $0 {
                if let pairingDevice = self.pairingDevice {
                    if pairingDevice.peripheral == device.peripheral, device.isConnected {
                        self.stopScanning()
                        self.pairingTimeoutHandler?.cancel()
                        self.pairingTimeoutHandler = nil
                        self.pairingDevice = nil
                        self.hidePairingGuideView()
                        self.delegate?(device)
                        self.exit()
                    }
                } else {
                    // 如果设备已经连上本机则自动连接
                    if let earbuds = device as? ABEarbuds, earbuds.btAddress == Utils.bluetoothAudioDeviceAddress {
                        self.stopScanning()
                        self.delegate?(device)
                        self.exit()
                        return
                    }
                    
                    // 查找设备是否已经在列表中
                    if let index = self.discoveredDevices.firstIndex(of: device) {
                        // 如果设备已经存在于列表更新状态
                        self.discoveredDevices.replaceSubrange(index...index, with: [device])
                        self.tableView.reloadData()
                    } else {
                        // 如果设备不在列表添加到列表
                        self.discoveredDevices.append(device)
                        self.discoveredDevices.sort {
                            if let rssi1 = $0.rssiPercent, let rssi2 = $1.rssiPercent {
                                return rssi1 > rssi2
                            } else {
                                return false
                            }
                        }
                        let index = self.discoveredDevices.firstIndex(of: device)!
                        self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    }
                }
            }
        }.disposed(by: disposeBag)
        
        setupNotifications()
    }
    
    // MARK: - 更新导航栏为扫描下的UI状态
    private func updateUIScanStarted() {
        timeoutLabel.isHidden = true
        scanIndicator.isHidden = false
        scanIndicator.startAnimating()
        
        refreshControl.endRefreshing()
        
        if let _ = navigationController {
            navigationItem.rightBarButtonItems = [stopScanButton, scanIndicatorItem]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanningDeviceIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopScanning()
    }
    
    // MARK: - 刷新控件以及
    @objc private func startScanningDeviceIfNeeded() {
//        guard let deviceName = Utils.currentAudioOutputDeviceName, deviceName.hasPrefix(Utils.DEVICE_NAME_PREFIX) else {
//            // 提示需要先连接设备
//            noticeLabel.isHidden = false
//            tableView.isHidden = true
//            scanIndicator.stopAnimating()
//            return
//        }
        
        tableView.isHidden = false
        startScanning()
    }
    
    // MARK: - 开始扫描
    private func startScanning() {
        discoveredDevices.removeAll()
        tableView.reloadData()
        viewModel.startScanning()
        updateUIScanStarted()
    }
    
    // MARK: - 结束扫描
    @objc private func stopScanning() {
        viewModel.stopScanning()
        scanIndicator.stopAnimating()
        timeoutLabel.isHidden = discoveredDevices.count != 0
        
        if let _ = navigationController {
            navigationItem.rightBarButtonItems = [startScanButton, scanIndicatorItem]
        }

        #if DEBUG
            for device in discoveredDevices {
                logger?.v(.scannerVC, "Device: \(device)")
            }
        #endif
    }
    
    // MARK: - 通知以及通知回调
    private func setupNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        nc.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    // MARK: - 音频切换事件响应
    @objc private func handleRouteChange(notification: UIKit.Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        switch reason {
        case .newDeviceAvailable:
            // 如果刚连接的音频设备是当前蓝牙设备，则直接退出（因为BLE已经连接）
            // 如果还没有则自动开启扫描扫描程序会判断广播的BLE设备是否是已经连接的音频设备
            if let earbuds = viewModel.activeDevice.value as? ABEarbuds,
               earbuds.btAddress == Utils.bluetoothAudioDeviceAddress {
                DispatchQueue.main.async { self.exit() }
            } else {
                DispatchQueue.main.async { self.startScanningDeviceIfNeeded() }
            }
        default: ()
        }
    }
    
    // MARK: - 进入前台事件响应
    @objc private func willEnterForeground() {
        if let _ = pairingDevice {
            viewModel.startScanning()
            updateUIScanStarted()
            startPairingTimeout()
        } else {
            startScanningDeviceIfNeeded()
        }
    }
    
    // MARK: - 进入后台事件响应
    @objc private func didEnterBackground() {
        stopScanning()
        // 如果现在在配对过程中先取消超时待重新进入App之后再重新计时
        if let pairingTimeoutHandler = pairingTimeoutHandler {
            pairingTimeoutHandler.cancel()
            self.pairingTimeoutHandler = nil
        }
    }
}

private extension ScanDeviceViewController {
    private func getSignalText(from device: ABDevice) -> String? {
        var signalText: String? = nil
        if let rssiPercent = device.rssiPercent {
            if rssiPercent > 65 {
                signalText = "🀡"
            } else if rssiPercent > 45 {
                signalText = "🀟"
            } else if rssiPercent > 28 {
                signalText = "🀝"
            } else if rssiPercent > 10 {
                signalText = "🀛"
            } else {
                signalText = "🀙"
            }
        }
        return signalText
    }
}

// MARK: - 表格数据源与委托
extension ScanDeviceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell")
        }
        
        let device = discoveredDevices[indexPath.row]
        var title = device.name!
        if let earbuds = device as? ABEarbuds {
            title = "\(title) " + (earbuds.isConnected ? "☑️" : "🔘")
        }
        if let signalText = getSignalText(from: device) {
            cell.accessoryView = {
                let label = UILabel()
                label.text = signalText
                label.sizeToFit()
                return label
            }()
        } else {
            cell.accessoryView = nil
        }
        cell.textLabel?.text = title
        
        // For ABEarbuds
        if let earbuds = device as? ABEarbuds {
            cell.detailTextLabel?.text = "\(earbuds.btAddress)"
        } else {
            // For iOS Bluetooth peripheral
            cell.detailTextLabel?.text = "\(device.peripheral.identifier)"
        }
        return cell!
    }
}

extension ScanDeviceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        stopScanning()
        let device = self.discoveredDevices[indexPath.row]
        // Only ABEarbuds for now
        if let earbuds = device as? ABEarbuds {
            if earbuds.isConnected {
                // 理论上不会进到这里来因为连接到本机的会自动连接，未连接到本机的不会添加到设备列表
                self.delegate?(device)
                exit()
            } else {
                if #available(iOS 13.2, *), device.supportCTKD {
                    // 监听连接状态连接后退出
                    // 使用registerForConnectionEvents（需要把代理接口拉出来）
                    // 或者监听蓝牙音频连接事件（目前使用这种）
                    // 直接连接下一层会处理CTKD
                    viewModel.sharedDeviceRepo.connect(device)
                } else {
                    startPairingGuide(device: device)
                }
            }
        }
    }
    
    private func startPairingGuide(device: ABDevice) {
        let alertController = UIAlertController(title: "goto_system_settings".localized, message: "pairing_guide_description".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "ok".localized, style: .default, handler: { action in
            self.pairingDevice = device
            self.showPairingGuideView()
            self.startPairingTimeout()
            // 跳转到系统设置
            #if DEBUG
                // App Store 不可用非公开API
                UIApplication.shared.open(URL(string: "App-Prefs:root")!)
            #endif
        }));
        alertController.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
        present(alertController, animated: true)
    }
    
    private func showPairingGuideView() {
        if let keyWindow = UIWindow.key {
            self.pairingGuideView.alpha = 0
            keyWindow.addSubview(self.pairingGuideView)
            UIView.animate(withDuration: 0.5) {
                self.pairingGuideView.alpha = 0.3
            }
        }
    }
    
    // MARK: - 重新设定配对超时操作
    private func startPairingTimeout() {
        pairingTimeoutHandler = DispatchWorkItem(block: handlePairingTimeout)
        pairingTimeoutQueue.asyncAfter(deadline: .now() + pairingTimeout, execute: pairingTimeoutHandler!)
    }
    
    // MARK: - 配对超时操作
    private func handlePairingTimeout() {
        pairingTimeoutHandler = nil
        pairingDevice = nil
        DispatchQueue.main.async {
            self.stopScanning()
            self.hidePairingGuideView()
            let alertController = UIAlertController(title: nil, message: "pairing_timeout".localized, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "ok".localized, style: .default, handler: { _ in
                // FIXME: 是否需要重新开始扫描呢？
                // self.startScanningDeviceIfNeeded()
            }))
            self.present(alertController, animated: true)
        }
    }
    
    private func hidePairingGuideView() {
        UIView.animate(withDuration: 0.5) {
            self.pairingGuideView.alpha = 0
        } completion: { _ in
            self.pairingGuideView.removeFromSuperview()
        }
    }
}

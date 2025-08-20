//
//  OtaViewController.swift
//  ABMateDemo
//
//  Created by Bluetrum.
//  

import UIKit
import CoreBluetooth
import RxSwift
import FOTA
import DeviceManager

let OTA_FILE_CHECKSUM_POSITION: Int = 56

class OtaViewController: UIViewController {
    
    var progressView: UIProgressView!
    var progressLabel: UILabel!
    var updateButton: UIButton!
    var statusLabel: UILabel!
    
    var fwVersionLabel: UILabel!
    var twsStaticLabel: UILabel!
    var twsConnectionLabel: UILabel!
    var fileChecksumLabel: UILabel!
    var fwChecksumLabel: UILabel!
    var noNeedToUpdateLabel: UILabel!
    
    private let viewModel = SharedViewModel.shared
    
    private let disposeBag = DisposeBag()
    
    private var otaManager: OtaManager = OtaManager()
    
    private var fileChecksum: Data?
    private var fwChecksum: Data?
    
    private var isTwsDevice: Bool?
    private var isTwsConnected: Bool?
    
    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "fota_title".localized

        setupViews()
        setupDeviceInfo()
        
        otaManager.delegate = self
        otaManager.requestDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.deviceCommManager.registerNotificationCallback(OtaRequest.COMMAND_OTA_STATE, callableType: OtaStateNotificationCallable.self, callback: { [unowned self] notification in
            guard let state = notification as? UInt8 else {
                return
            }
            self.otaManager.updateOTAState(state: state)
        })
        viewModel.deviceCommManager.registerResponseCallable(command: OtaRequest.COMMAND_OTA_GET_INFO, callableType: OtaInfoResponseCallable.self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        viewModel.deviceCommManager.unregisterResponseCallable(command: OtaRequest.COMMAND_OTA_GET_INFO)
        viewModel.deviceCommManager.unregisterDeviceInfoCallback(OtaRequest.COMMAND_OTA_STATE)
    }
    
    @objc
    func selectOtaFile(_ sender: Any) {
        guard let fotUrls = Utils.fotFileList() else {
            // File isn't exist, quit
            let title = "fota_file_not_exist_title".localized
            let message = String(format: "fota_file_not_exist_message".localized)
            presentAlert(title: title,
                         message: message,
                         cancelable: false,
                         option: nil) { _ in
                self.navigationController?.popViewController(animated: true)
            }
            return
        }
        
        let title = "fota_select_file".localized
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        // 添加文件名
        for fotUrl in fotUrls {
            // 只显示文件名
            let fileName = (fotUrl as NSURL).lastPathComponent
            
            alert.addAction(UIAlertAction(title: fileName, style: .default, handler: { action in
                // 读取选择的文件
                if let otaData = try? Data(contentsOf: fotUrl) {
                    if let checksum = otaData.checksum {
                        self.fileChecksum = checksum
                        self.fileChecksumLabel.text = checksum.hex
                        print("Current File Checksum：\(checksum.hex)")
                    }
                    // Check if it's the same firmware
                    if !self.checkFWChecksum() {
                        // 准备升级数据
                        self.otaManager.setOtaData(otaData)
                        self.otaManager.initialize()
                        self.otaManager.prepareToUpdate()
                    }
                } else {
                    // Read file error
                    let title = "fota_read_file_error".localized
                    let message = "ok".localized
                    self.presentAlert(title: title,
                                      message: message,
                                      cancelable: false,
                                      option: nil) { _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }))
        }
        // 添加取消
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @objc
    private func doUpdate(_ sender: Any) {
        if otaManager.isReadyToUpdate() {
            otaManager.startOTA()
        }
    }

    private func setupDeviceInfo() {
        
        viewModel.deviceFirmwareVersion.subscribeOnNext { [unowned self] in
            if let deviceFirmwareVersion = $0 {
                self.onReceiveVersion(deviceFirmwareVersion)
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceFwChecksum.subscribeOnNext { [unowned self] in
            if let deviceFwChecksum = $0 {
                self.fwChecksum = deviceFwChecksum
                self.fwChecksumLabel.text = deviceFwChecksum.hex
                print("Current FW Checksum：\(deviceFwChecksum.hex)")
                self.checkFWChecksum()
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceIsTws.subscribeOnNext { [unowned self] in
            if let deviceIsTws = $0 {
                self.isTwsDevice = deviceIsTws
                self.onReceiveIsTWS(deviceIsTws)
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceTwsConnected.subscribeOnNext { [unowned self] in
            if let deviceTwsConnected = $0 {
                self.isTwsConnected = deviceTwsConnected
                self.onReceiveTWSConnected(deviceTwsConnected)
            }
        }.disposed(by: disposeBag)
    }
    
    // MARK: -

    private func showErrorDescription(error: OTAError) {
        let errorDescription = String(format: "fota_error_desc".localized, error.errorDescription!)
        statusLabel.text = errorDescription
    }

    private func showProgress(_ progress: Float) {
        let normalizedProgress = progress / 100.0
        progressView.progress = normalizedProgress
        progressLabel.text = String(format: "%d%%", UInt(progress))
    }

    private func refreshUpdateStatus() {
        // Pop back isn't allowed when it's in progress
        navigationItem.hidesBackButton = otaManager.isUpdating
        // Keep screen on
        UIApplication.shared.isIdleTimerDisabled = otaManager.isUpdating
    }

    // Info: tws disconnected, and device info

    func onReceiveVersion(_ version: UInt32) {
        let versionString = "\(version)"
        print("Device firmware version: \(versionString)");
        fwVersionLabel.text = versionString
    }

    func onReceiveIsTWS(_ isTWS: Bool) {
        handleTWSMessage()
    }

    func onReceiveTWSConnected(_ connected: Bool) {
        if !connected {
            statusLabel.text = "fota_tws_disconnected_tip".localized
            refreshUpdateStatus()
            updateButton.isEnabled = false
        }
        handleTWSMessage()
    }

    private func handleTWSMessage() {
        if case true? = isTwsDevice {
            twsStaticLabel.isHidden = false
            twsConnectionLabel.isHidden = false

            if case true? = isTwsConnected {
                twsConnectionLabel.text = "fota_tws_state_connected".localized
            } else {
                twsConnectionLabel.text = "fota_tws_state_disconnected".localized
                updateButton.isEnabled = false
            }
        }
    }
    
}

extension OtaViewController {
    
    @discardableResult
    func checkFWChecksum() -> Bool {
        
        if let fwChecksum = fwChecksum, let fileChecksum = fileChecksum {
            let b = fwChecksum == fileChecksum
            noNeedToUpdateLabel.isHidden = !b
            updateButton.isEnabled = !b
            return b
        }
        
        return false
    }
    
    func checkIfDeviceReady() -> Bool {
        // TODO: Check Device
        
        if case true? = isTwsDevice {
            if let isTwsConnected = isTwsConnected {
                return isTwsConnected
            }
        }
        
        return true
    }
    
}

extension OtaViewController: OtaRequestDelegate {
    
    func sendRequest(_ request: Request, requestCompletion: RequestCompletion?) {
        viewModel.deviceCommManager.sendRequest(request, completion: requestCompletion)
    }
    
}

// MARK: - OTAManagerDelegate

extension OtaViewController: OtaManagerDelegate {
    
    func onOtaAllowUpdate(_ allowed: Bool) {
        if allowed {
            otaManager.packetSize = UInt16(viewModel.deviceCommManager.maxPacketSize)
            statusLabel.text = "fota_update_ready".localized
            updateButton.isEnabled = true
        } else {
            statusLabel.text = "fota_udpate_refused".localized
        }
    }
    
    func onReady() {
        statusLabel.text = "fota_update_ready".localized
        updateButton.isEnabled = true
    }

    func onOtaStart() {
        statusLabel.text = "fota_updating".localized
        updateButton.isEnabled = false
        refreshUpdateStatus()
        updateButton.backgroundColor = .yellow
    }

    func onOtaProgress(_ progress: Float) {
        showProgress(progress)
    }

    func onOtaStop() {
        statusLabel.text = "fota_bluetooth_disconnected".localized
        updateButton.isEnabled = false
        refreshUpdateStatus()
        updateButton.backgroundColor = .blue
    }

    func onOtaFinish() {
        statusLabel.text = "fota_update_finish".localized
        refreshUpdateStatus()
    }

    func onOtaPause() {
        statusLabel.text = "fota_update_pause".localized
    }

    func onOtaContinue() {
        statusLabel.text = "fota_updating".localized
    }

    func onOtaError(_ error: OTAError) {
        refreshUpdateStatus()
        
        if case .deviceReport(let code) = error {
            var errorReason: String = error.localizedDescription
            switch code {
            case OtaManager.ERROR_CODE_SAME_FIRMWARE:
                errorReason = "fota_error_same_firmware".localized
            case OtaManager.ERROR_CODE_KEY_MISMATCH:
                errorReason = "fota_error_key_mismatch".localized
            case OtaManager.ERROR_CODE_CRC_ERROR:
                errorReason = "fota_error_crc_error".localized
            case OtaManager.ERROR_CODE_SEQ_ERROR:
                errorReason = "fota_error_seq_error".localized
            case OtaManager.ERROR_CODE_DATA_LEN_ERROR:
                errorReason = "fota_error_data_len_error".localized
            default:
                break
            }
            statusLabel.text = String(format: "fota_error_desc".localized, errorReason)
        } else {
            statusLabel.text = String(format: "fota_error_desc".localized, error.localizedDescription)
        }
        
        updateButton.backgroundColor = .red
    }

}

// MARK: - Setup Views & Layout

fileprivate extension OtaViewController {
    
    private func setupViews() {
        
        // TODO: NavigationBar Views, right button
        let barButton = UIBarButtonItem(title: "fota_select_file_button_title".localized,
                                        style: .plain,
                                        target: self,
                                        action: #selector(selectOtaFile(_:)))
        navigationItem.rightBarButtonItem = barButton
        
        
        // MARK: - Center Views
        
        progressView = {
            let progressView = UIProgressView(progressViewStyle: .default)
            view.addSubview(progressView)
            // Put in center
            progressView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.left.right.equalTo(view.layoutMarginsGuide)
            }
            return progressView
        }()
        
        progressLabel = {
            let label = UILabel()
            label.text = " "
            label.sizeToFit()
            view.addSubview(label)
            // Below progressView
            label.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(progressView.snp.bottom).offset(4)
            }
            return label
        }()
        
        updateButton = {
            let button = UIButton(type: .system)
            button.setTitle("fota_update_button_title".localized, for: .normal)
            button.addTarget(self, action: #selector(doUpdate), for: .touchUpInside)
            view.addSubview(button)
            button.isEnabled = false
            // Below progressLabel
            button.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(progressLabel.snp.bottom).offset(4)
            }
            return button
        }()
        
        // MARK: - Bottom Views
        
        statusLabel = {
            let label = UILabel()
            view.addSubview(label)
            // At bottom of super view
            label.snp.makeConstraints { make in
                make.bottom.left.right.equalTo(view.layoutMarginsGuide)
            }
            return label
        }()
        
        // MARK: - Top Views
        
        let fwVersionStaticLabel: UILabel = {
            let label = UILabel()
            label.text = "fota_firmware_version".localized
            label.sizeToFit()
            view.addSubview(label)
            // At top of super view
            label.snp.makeConstraints { make in
                make.top.equalTo(view.layoutMarginsGuide.snp.top)
                make.left.equalTo(view.layoutMarginsGuide.snp.left).priority(.high)
            }
            return label
        }()
        
        fwVersionLabel = {
            let label = UILabel()
            label.textAlignment = .left
            view.addSubview(label)
            // At the right side of fwVersionStaticLabel
            label.snp.makeConstraints { make in
                make.left.equalTo(fwVersionStaticLabel.snp.right).offset(4)
                make.right.equalTo(view.layoutMarginsGuide.snp.right).priority(.low)
                make.centerY.equalTo(fwVersionStaticLabel)
            }
            return label
        }()
        
        twsStaticLabel = {
            let label = UILabel()
            label.text = "fota_tws".localized
            view.addSubview(label)
            label.isHidden = true
            // Below fwVersionLabel
            label.snp.makeConstraints { make in
                make.top.equalTo(fwVersionStaticLabel.snp.bottom)
                make.left.equalTo(view.layoutMarginsGuide.snp.left).priority(.high)
            }
            return label
        }()
        
        twsConnectionLabel = {
            let label = UILabel()
            view.addSubview(label)
            // At the right side of twsLabel
            label.snp.makeConstraints { make in
                make.left.equalTo(twsStaticLabel.snp.right).offset(4)
                make.right.equalTo(view.layoutMarginsGuide.snp.right).priority(.low)
                make.centerY.equalTo(twsStaticLabel)
            }
            return label
        }()
        
        let fileChecksumStaticLabel: UILabel = {
            let label = UILabel()
            label.text = "fota_file_checksum".localized
            view.addSubview(label)
            // Below twsLabel
            label.snp.makeConstraints { make in
                make.top.equalTo(twsStaticLabel.snp.bottom)
                make.left.equalTo(view.layoutMarginsGuide.snp.left).priority(.high)
            }
            return label
        }()
        
        fileChecksumLabel = {
            let label = UILabel()
            view.addSubview(label)
            // At the right side of fileChecksumStaticLabel
            label.snp.makeConstraints { make in
                make.left.equalTo(fileChecksumStaticLabel.snp.right).offset(4)
                make.right.equalTo(view.layoutMarginsGuide.snp.right).priority(.low)
                make.centerY.equalTo(fileChecksumStaticLabel)
            }
            return label
        }()
        
        let fwChecksumStaticLabel: UILabel = {
            let label = UILabel()
            label.text = "fota_firmware_checksum".localized
            view.addSubview(label)
            // Below fileChecksumStaticLabel
            label.snp.makeConstraints { make in
                make.top.equalTo(fileChecksumStaticLabel.snp.bottom)
                make.left.equalTo(view.layoutMarginsGuide.snp.left).priority(.high)
            }
            return label
        }()
        
        fwChecksumLabel = {
            let label = UILabel()
            view.addSubview(label)
            // At the right of fwChecksumStaticLabel
            label.snp.makeConstraints { make in
                make.left.equalTo(fwChecksumStaticLabel.snp.right).offset(4)
                make.right.equalTo(view.layoutMarginsGuide.snp.right).priority(.low)
                make.centerY.equalTo(fwChecksumStaticLabel)
            }
            return label
        }()
        
        noNeedToUpdateLabel = {
            let label = UILabel()
            label.text = "fota_checksum_tip".localized
            view.addSubview(label)
            label.isHidden = true
            // Below fwChecksumStaticLabel
            label.snp.makeConstraints { make in
                make.top.equalTo(fwChecksumStaticLabel.snp.bottom)
                make.left.equalTo(view.layoutMarginsGuide.snp.left)
            }
            return label
        }()
    }
    
}

fileprivate extension Data {
    
    /// 用于OTA的校验值
    var checksum: Data? {
        
        // 大小不会小于固件的校验位置+长度
        if self.count >= OTA_FILE_CHECKSUM_POSITION + 4 {
            // Big endian to little endian
            var checksum = Data(count: 4)
            checksum[0] = self[OTA_FILE_CHECKSUM_POSITION + 3]
            checksum[1] = self[OTA_FILE_CHECKSUM_POSITION + 2]
            checksum[2] = self[OTA_FILE_CHECKSUM_POSITION + 1]
            checksum[3] = self[OTA_FILE_CHECKSUM_POSITION + 0]
            return checksum
        }
        return nil
    }
    
}

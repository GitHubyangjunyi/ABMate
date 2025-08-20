//
//  FunctionViewController.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/15.
//

import UIKit
import SnapKit
import RxSwift
import Toaster
import Utils
import DeviceManager

// MARK: - 功能视图控制器
class FunctionViewController: UIViewController {
    
    weak var logger: LoggerDelegate? = DefaultLogger.shared
    
    private let viewModel = SharedViewModel.shared
    private let disposeBag = DisposeBag()
    
    private var sendingIndicator: UIActivityIndicatorView!
    
    private var ancModeSegmentedControl: UISegmentedControl!
    private var ancSettingsButton: UIButton!
    
    private var eqLabel: UILabel!
    private var spatialAudioSwitch: UISwitch!
    private var bassEngineSwitch: UISwitch!
    private var bassEngineValueSlider: UISlider!
    private var antiWindNoiseSwitch: UISwitch!
    
    private var leftKeyViews: [UIView]!
    private var rightKeyViews: [UIView]!
    
    private var tapKeyLabels: [UILabel]!
    
    private var leftSingleTapLabel: UILabel!
    private var leftDoubleTapLabel: UILabel!
    private var leftTripleTapLabel: UILabel!
    private var rightSingleTapLabel: UILabel!
    private var rightDoubleTapLabel: UILabel!
    private var rightTripleTapLabel: UILabel!
    private var leftLongPressLabel: UILabel!
    private var rightLongPressLabel: UILabel!
    
    private var multipointLabel: UILabel!
    private var renameDeviceLabel: UILabel!
    private var workModeLabel: UILabel!
    private var ledSwitch: UISwitch!
    private var findDeviceSwitch: UISwitch!
    
    // 用来控制支持功能的显示
    private var ancLayout: UIView!
    private var bassEngineLayout: UIView! // TODO: 和bassEngineValueSlider合并
    private var spatialAudioLayout: UIView!
    private var antiWindNoiseLayout: UIView!
    
    private let ancModeStrings = [
        "anc_transparency".localized,
        "anc_off".localized,
        "anc_on".localized
    ]
    
    private let keySettingStrings: [String] = [
        "key_function_none".localized,
        "key_function_recall".localized,
        "key_function_voice_assistant".localized,
        "key_function_previous".localized,
        "key_function_next".localized,
        "key_function_volume_up".localized,
        "key_function_volume_down".localized,
        "key_function_play_pause".localized,
        "key_function_game_mode".localized,
        "key_function_anc_control".localized,
    ]
    
    private let workModeStrings: [String] = [
        "work_mode_normal".localized,
        "work_mode_game".localized,
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupFunctionGroups()
        setupObserver()
        sendingIndicator = UIActivityIndicatorView(style: .medium)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sendingIndicator)
    }
    
    // MARK: - Observer
    private func setupObserver() {
        // MARK: ANC
        viewModel.deviceAncMode.subscribeOnNext { [unowned self] in
            if let ancMode = $0, let mode = AncMode(rawValue: ancMode) {
                let selectedIndex: Int
                let enableAncButton: Bool
                
                switch mode {
                case .off:
                    selectedIndex = 1
                    enableAncButton = false
                case .on:
                    selectedIndex = 2
                    enableAncButton = true
                case .transparency:
                    selectedIndex = 0
                    enableAncButton = true
                }
                
                self.ancModeSegmentedControl.selectedSegmentIndex = selectedIndex
                self.ancSettingsButton.isEnabled = enableAncButton
                self.ancModeSegmentedControl.isEnabled = true
            } else {
                self.ancModeSegmentedControl.isEnabled = false
                self.ancSettingsButton.isEnabled = false
            }
        }.disposed(by: disposeBag)
        
//        viewModel.deviceAncGainNum.subscribeOnNext { [unowned self] in
//            self.ancSettingsButton.isEnabled = !($0 == nil && self.viewModel.deviceTransparencyGainNum.value == nil)
//        }.disposed(by: disposeBag)
//
//        viewModel.deviceTransparencyGainNum.subscribeOnNext { [unowned self] in
//            self.ancSettingsButton.isEnabled = !($0 == nil && self.viewModel.deviceAncGainNum.value == nil)
//        }.disposed(by: disposeBag)
        
        viewModel.deviceKeySettings.subscribeOnNext { [unowned self] in
            if let keySettings = $0 {
                for (type, function) in keySettings {
                    let functionName = self.keySettingStrings[Int(function.rawValue)]
                    
                    switch type {
                    case .leftSingleTap:    self.leftSingleTapLabel.text = functionName
                    case .rightSingleTap:   self.rightSingleTapLabel.text = functionName
                    case .leftDoubleTap:    self.leftDoubleTapLabel.text = functionName
                    case .rightDoubleTap:   self.rightDoubleTapLabel.text = functionName
                    case .leftTripleTap:    self.leftTripleTapLabel.text = functionName
                    case .rightTripleTap:   self.rightTripleTapLabel.text = functionName
                    case .leftLongPress:    self.leftLongPressLabel.text = functionName
                    case .rightLongPress:   self.rightLongPressLabel.text = functionName
                    }
                }
            } else {
                self.leftSingleTapLabel.text = nil
                self.rightSingleTapLabel.text = nil
                self.leftDoubleTapLabel.text = nil
                self.rightDoubleTapLabel.text = nil
                self.leftTripleTapLabel.text = nil
                self.rightTripleTapLabel.text = nil
                self.leftLongPressLabel.text = nil
                self.rightLongPressLabel.text = nil
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceName.subscribeOnNext { [unowned self] in
            self.renameDeviceLabel.text = $0
        }.disposed(by: disposeBag)
        
        viewModel.deviceWorkMode.subscribeOnNext { [unowned self] in
            if let workMode = $0 {
                self.workModeLabel.text = self.workModeStrings[Int(workMode)]
            } else {
                self.workModeLabel.text = nil
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceLedSwitch.subscribeOnNext { [unowned self] in
            if let isOn = $0 {
                self.ledSwitch.isOn = isOn
                self.ledSwitch.isEnabled = true
            } else {
                self.ledSwitch.isEnabled = false
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceTwsConnected.subscribeOnNext { [unowned self] twsConnected in
            let leftIsMainSide = self.viewModel.deviceLeftIsMainSide.value
            self.updateDeviceKeyStatus(twsConnected: twsConnected, leftIsMainSide: leftIsMainSide)
        }.disposed(by: disposeBag)
        
        viewModel.deviceLeftIsMainSide.subscribeOnNext { [unowned self] leftIsMainSide in
            let twsConnected = self.viewModel.deviceTwsConnected.value
            self.updateDeviceKeyStatus(twsConnected: twsConnected, leftIsMainSide: leftIsMainSide)
        }.disposed(by: disposeBag)
        
        viewModel.deviceCapacities.subscribeOnNext { [unowned self] in
            if let deviceCapacities = $0 {
                self.ancLayout.isHidden = !deviceCapacities.supportAnc
                self.bassEngineLayout.isHidden = !deviceCapacities.supportBassEngine
                self.spatialAudioLayout.isHidden = !deviceCapacities.supportSpatialAudio
                self.antiWindNoiseLayout.isHidden = !deviceCapacities.supportAntiWindNoise
            } else {
                self.ancLayout.isHidden = true
                self.bassEngineLayout.isHidden = true
                self.spatialAudioLayout.isHidden = true
                self.antiWindNoiseLayout.isHidden = true
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceSpatialAudioMode.subscribeOnNext { [unowned self] in
            if let mode = $0 {
                self.spatialAudioSwitch.isOn = mode.isOn
                self.spatialAudioSwitch.isEnabled = true
            } else {
                self.spatialAudioSwitch.isEnabled = false
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceBassEngineStatus.subscribeOnNext { [unowned self] in
            if let isOn = $0 {
                self.bassEngineSwitch.isOn = isOn
                self.bassEngineSwitch.isEnabled = true
                self.bassEngineValueSlider.isHidden = !isOn
            } else {
                self.bassEngineSwitch.isEnabled = false
                self.bassEngineValueSlider.isHidden = true
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceBassEngineValue.subscribeOnNext { [unowned self] in
            updateBassEngine(range: viewModel.deviceBassEngineRange.value, value: $0)
        }.disposed(by: disposeBag)
        
        viewModel.deviceBassEngineRange.subscribeOnNext { [unowned self] in
            updateBassEngine(range: $0, value: viewModel.deviceBassEngineValue.value)
        }.disposed(by: disposeBag)
        
        viewModel.deviceAntiWindNoise.subscribeOnNext { [unowned self] in
            if let isOn = $0 {
                self.antiWindNoiseSwitch.isOn = isOn
                self.antiWindNoiseSwitch.isEnabled = true
            } else {
                self.antiWindNoiseSwitch.isEnabled = false
            }
        }.disposed(by: disposeBag)
    }
    
    private func updateBassEngine(range: BassEngineRange?, value: Int8?) {
        if let range, let value {
            self.bassEngineValueSlider.minimumValue = Float(range.minValue)
            self.bassEngineValueSlider.maximumValue = Float(range.maxValue)
            self.bassEngineValueSlider.value = Float(value)
        }
    }
    
    private func updateDeviceKeyStatus(twsConnected: Bool?, leftIsMainSide: Bool?) {
        let leftKeyLabels = [leftSingleTapLabel, leftDoubleTapLabel, leftTripleTapLabel, leftLongPressLabel]
        let rightKeyLabels = [rightSingleTapLabel, rightDoubleTapLabel, rightTripleTapLabel, rightLongPressLabel]
        
        let leftEnable: Bool
        let rightEnable: Bool
        
        if let twsConnected = twsConnected {
            if twsConnected {
                leftEnable = true
                rightEnable = true
            } else {
                if let leftIsMainSide = leftIsMainSide {
                    leftEnable = leftIsMainSide
                    rightEnable = !leftIsMainSide
                } else {
                    leftEnable = true
                    rightEnable = true
                }
            }
        } else {
            leftEnable = false
            rightEnable = false
        }
        
        // Enable/Disable KeyViews
        for view in leftKeyViews {
            view.isUserInteractionEnabled = leftEnable
        }
        for view in rightKeyViews {
            view.isUserInteractionEnabled = rightEnable
        }
        
        // Gray labels
        for label in leftKeyLabels {
            label?.isEnabled = leftEnable
        }
        for label in rightKeyLabels {
            label?.isEnabled = rightEnable
        }
    }
    
    // MARK: - Request
    // MARK: ANC
    @objc private func onAncModeChanged(_ segmentedControl: UISegmentedControl) {
        let request: AncRequest? = {
            let index = segmentedControl.selectedSegmentIndex
            if let ancMode = AncRequest.AncMode(rawValue: UInt8(index)) {
                return .modeRequest(ancMode: ancMode)
            }
            return nil
        }()
        if let request {
            sendRequestAndWaitSuccess(request, completion: nil)
        }
    }
    
    @objc private func clickAncSettings() {
        let vc = AncSettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: EQ
    @objc private func clickEqualizer() {
        // 如果RemoteEqSettings为空，使用APP本地EQ设置
        // If RemoteEqSettings is nil, use App local EQ Settings
        if viewModel.deviceRemoteEqSettings.value == nil {
            let vc = EqualizerViewController()
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = RemoteEqViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: Key
    @objc  private func clickKeyFunction(_ sender: UITapGestureRecognizer) {
        let gestureRecognizer = sender as! KeyTapGestureRecognizer
        let titleLabel = gestureRecognizer.associatedObject as! UILabel
        
        let title = "key_function_select".localized
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        // Add options
        for (index, title) in keySettingStrings.enumerated() {
            
            alertController.addAction(UIAlertAction(title: title, style: .default, handler: { action in
                
                let type = self.tapKeyLabels.firstIndex(of: titleLabel)! + 1 // Type from 1
                let keyType = KeyType(rawValue: UInt8(type))!
                let keyFunction = KeyFunction(rawValue: UInt8(index))!
                
                self.viewModel.setKeySetting(keyType: keyType, keyFunction: keyFunction) {
                    [weak self] result, timeout in
                    if timeout {
                        self?.logger?.d(.functionVC, "Request timeout")
                        Toast(text: "request_timeout".localized).show()
                    } else if let result = result {
                        if result {
                            self?.logger?.d(.functionVC, "Request succeeded")
                            Toast(text: "request_succeeded".localized).show()
                        } else {
                            self?.logger?.d(.functionVC, "Request failed")
                            Toast(text: "request_failed".localized).show()
                        }
                    }
                }
            }))
        }
        alertController.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Rename Device
    @objc private func clickRenameDevice() {
        // 显示改名弹框
        let title = "device_name".localized
        let message = "device_rename_tip".localized
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { deviceNameTextField in
            deviceNameTextField.text = self.viewModel.deviceName.value
        }
        let okAction = UIAlertAction(title: "ok".localized, style: .default, handler: { action in
            let deviceName = alertController.textFields![0].text!
            if deviceName.isEmpty {
                self.presentAlert(title: nil, message: "device_name_empty_alert".localized)
            } else {
                // 发送改名命令
                let request = BluetoothNameRequest(deviceName)
                self.sendRequestAndWaitSuccess(request) { [weak self] result, timeout in
                    if !timeout, result! {
                        self?.presentAlert(title: nil, message: "device_rename_complete_tip".localized)
                    }
                }
            }
        })
        alertController.addAction(okAction)
        alertController.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Earbuds
    @objc private func clickMultipoint() {
        let vc = MultipointViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func clickWorkMode() {
        let title = "work_mode_select".localized
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for (index, title) in workModeStrings.enumerated() {
            alertController.addAction(UIAlertAction(title: title, style: .default, handler: { action in
                let request = WorkModeRequest(.init(rawValue: UInt8(index))!)
                self.sendRequestAndWaitSuccess(request, completion: nil)
            }))
        }
        alertController.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func clickLedSwitch(_ `switch`: UISwitch) {
        let request = LedSwitchRequest(`switch`.isOn)
        self.sendRequestAndWaitSuccess(request, completion: nil)
    }
    
    @objc private func clickSpatialAudio(_ `switch`: UISwitch) {
        let request = SpatialAudioModeRequest(on: `switch`.isOn)
        self.sendRequestAndWaitSuccess(request, completion: nil)
    }
    
    @objc private func clickBassEngine(_ `switch`: UISwitch) {
        let request = BassEngineRequest.enableRequest(enable: `switch`.isOn)
        self.sendRequestAndWaitSuccess(request, completion: nil)
    }
    
    @objc private func clickBassEngineSlider(_ slider: UISlider) {
        let value = Int8(slider.value)
        let request = BassEngineRequest.valueRequest(value: value)
        self.sendRequestAndWaitSuccess(request, completion: nil)
    }
    
    @objc private func clickAntiWindNoise(_ `switch`: UISwitch) {
        let request = AntiWindNoiseRequest(`switch`.isOn)
        self.sendRequestAndWaitSuccess(request, completion: nil)
    }
    
    @objc private func clickFindDevice(_ `switch`: UISwitch) {
        let request = FindDeviceRequest(`switch`.isOn)
        self.sendRequestAndWaitSuccess(request, completion: nil)
    }
    
    // MARK: Device
    @objc private func clickUpdateFirmware() {
        let vc = OtaViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func clickRestoreSettings() {
        let restoreAction = UIAlertAction(title: "ok".localized, style: .default) { action in
            let request = FactoryResetRequest()
            self.sendRequestAndWaitSuccess(request, completion: nil)
        }
        presentAlert(title: nil,
                     message: "factory_reset_alert".localized,
                     cancelable: true,
                     option: restoreAction,
                     handler: nil)
    }
    
    @objc private func clickClearPairRecord() {
        let clearRecordAction = UIAlertAction(title: "ok".localized, style: .default) { action in
            let request = ClearPairRecordRequest()
            self.sendRequestAndWaitSuccess(request, completion: nil)
        }
        presentAlert(title: nil, message: "clear_pair_record_alert".localized, cancelable: true, option: clearRecordAction, handler: nil)
    }
}

// MARK: - Layout Views
extension Array<UIView> {
    /// 生成功能组
    var functionGroup: UIView {
        let stackView = UIStackView(arrangedSubviews: self)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 4
        return stackView
    }
}

extension FunctionViewController {
    
    // |------------------------------------|
    // |GroupTitle                          |
    // | |--------------------------------| |
    // | |SubView                         | |
    // | | |----------------------------| | |
    // | | |FunctionItem                | | |
    // | | |----------------------------| | |
    // | | |----------------------------| | |
    // | | |FunctionItem                | | |
    // | | |----------------------------| | |
    // | | |----------------------------| | |
    // | | |KeyFunctionItem             | | |
    // | | |Title | Action1  |  Action2 | | |
    // | | |Title | Action1  |  Action2 | | |
    // | | |----------------------------| | |
    // | |--------------------------------| |
    // |------------------------------------|
    
    private var arrowColor: UIColor { .blue.withAlphaComponent(0.3) }
    
    private var keyContainerBackgroundColor: UIColor { .clear }
    
    private var containerBackgroundColor: UIColor { UIColor(white: 0.9, alpha: 1.0) }
    private var groupBackgroundColor: UIColor { .white }
    
    private var functionItemBackgroundColor: UIColor { .blue.withAlphaComponent(0.05) }
    private var keyFunctionItemBackgroundColor: UIColor { .blue.withAlphaComponent(0.05) }
    
    private var functionRoundCornerRadius: CGFloat { 4 }
    private var groupRoundCornerRadius: CGFloat { 8 }
    
    /// 生成箭头
    private func newArrowLabel() -> UILabel {
        let label = UILabel()
        label.text = ">" // ">" or Image
        label.font = UIFont(descriptor: label.font.fontDescriptor.withSymbolicTraits(.traitBold)!, size: 0)
        label.textColor = arrowColor
        return label
    }
    
    /// 在View中放置箭头
    private func layoutArrowInView(_ view: UIView) {
        let label = newArrowLabel()
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(view.layoutMarginsGuide.snp.right).offset(-8)
        }
    }
    
    /// 按键功能单个条目视图
    /// 输出大小确定的视图
    private func newKeyActionView(nameLabel functionNameLabel: UILabel, indicatorView: UIView?) -> UIView {
        functionNameLabel.textAlignment = .center
        functionNameLabel.font = functionNameLabel.font.withSize(15)
        
        let containerView = UIView()
        let subcontainerView = UIView()
        containerView.addSubview(subcontainerView)
        containerView.backgroundColor = keyContainerBackgroundColor
        
        if let indicatorView = indicatorView {
            subcontainerView.addSubview(functionNameLabel)
            subcontainerView.addSubview(indicatorView)
            functionNameLabel.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8)
                make.left.equalToSuperview().inset(8).priority(.low)
            }
            indicatorView.snp.makeConstraints { make in
                make.left.equalTo(functionNameLabel.snp.right).offset(4)
                make.centerY.equalTo(functionNameLabel)
                make.right.equalToSuperview().inset(8).priority(.high)
            }
        } else {
            subcontainerView.addSubview(functionNameLabel)
            functionNameLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(8)
            }
        }
        
        subcontainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.edges.equalTo(subcontainerView)
        }
        
        return containerView
    }
    
    /// 按键功能单个类型视图
    private func newKeyFunctionItem(
        title: String?,
        actionView1 keyActionView1: UIView,
        actionView2 keyActionView2: UIView
    ) -> UIView {
        let containerView = UIView()
        containerView.roundCorners(radius: functionRoundCornerRadius)
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = titleLabel.font.withSize(15)
        titleLabel.text = title
        containerView.addSubview(titleLabel)
        containerView.addSubview(keyActionView1)
        containerView.addSubview(keyActionView2)
        
        containerView.backgroundColor = keyFunctionItemBackgroundColor
//        keyActionView1.backgroundColor = keyFunctionItemBackgroundColor
//        keyActionView2.backgroundColor = keyFunctionItemBackgroundColor
        
        // title, 1/6
        titleLabel.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(1.0/5.0)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        // action1, 2.5/6
        keyActionView1.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(2.0/5.0)
            make.top.equalTo(containerView)
            make.bottom.equalTo(containerView)
            make.left.equalTo(titleLabel.snp.right)
        }
        // action2, 2.5/6
        keyActionView2.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(2.0/5.0)
            make.top.equalTo(containerView)
            make.bottom.equalTo(containerView)
            make.left.equalTo(keyActionView1.snp.right)
            make.right.equalTo(containerView)
        }
        
        containerView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.right.equalTo(keyActionView2)
            make.top.equalTo(titleLabel).offset(-8)
            make.bottom.equalTo(titleLabel).offset(8)
        }
        
        return containerView
    }
    
    /// 功能条目，传入UILabel
    private func newFunctionItem(title: String, actionView: UIView?, label descriptionLabel: UILabel?) -> UIView {
        let containerView = UIView()
        containerView.roundCorners(radius: functionRoundCornerRadius)
        containerView.backgroundColor = functionItemBackgroundColor
        
        let titleLabel = UILabel()
        titleLabel.font = titleLabel.font.withSize(14)
        titleLabel.text = title
        containerView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView).inset(12)
            make.left.equalTo(containerView).inset(8)
        }
        
        var rightView: UIView
        if let actionView = actionView {
            containerView.addSubview(actionView)
            rightView = actionView
            
            actionView.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.right.equalTo(containerView.layoutMarginsGuide.snp.right)
            }
        } else {
            let label = newArrowLabel()
            containerView.addSubview(label)
            rightView = label
            
            label.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.right.equalTo(containerView.layoutMarginsGuide.snp.right).offset(-8)
            }
        }
        
        if let descriptionLabel = descriptionLabel {
            descriptionLabel.font = descriptionLabel.font.withSize(12)
            containerView.addSubview(descriptionLabel)
            
            descriptionLabel.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.right.equalTo(rightView.snp.left).offset(-8)
            }
        }
        
        containerView.snp.makeConstraints { make in
            make.bottom.equalTo(titleLabel.snp.bottom).offset(12)
        }
        
        return containerView
    }
    
    /// 功能条目，传入String
    private func newFunctionItem(title: String, actionView: UIView?, description: String?) -> UIView {
        var descriptionLabel: UILabel!
        
        if let description = description {
            descriptionLabel = UILabel()
            descriptionLabel.text = description
        }
        
        return newFunctionItem(title: title, actionView: actionView, label: descriptionLabel)
    }
    
    /// 整个组布局
    private func newFunctionGroup(title: String?, subView: UIView?) -> UIView {
        let containerView = UIView()
        containerView.roundCorners(radius: groupRoundCornerRadius)
        containerView.backgroundColor = groupBackgroundColor
        
        var subViewTopConstraintItem: ConstraintItem = containerView.snp.top
        var containerViewBottomConstraintItem: ConstraintItem = containerView.snp.top
        
        if let title = title {
            let titleLabel = UILabel()
            titleLabel.text = title
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.top.left.equalTo(containerView).inset(8)
            }
            subViewTopConstraintItem = titleLabel.snp.bottom
            containerViewBottomConstraintItem = titleLabel.snp.bottom
        }
        
        if let subView = subView {
            containerView.addSubview(subView)
            subView.snp.makeConstraints { make in
                make.top.equalTo(subViewTopConstraintItem).offset(8)
                make.left.right.equalTo(containerView).inset(8)
            }
            containerViewBottomConstraintItem = subView.snp.bottom
        }
        
        // Constraint containerView's bottom
        containerView.snp.makeConstraints { make in
            make.bottom.equalTo(containerViewBottomConstraintItem).offset(8)
        }
        
        return containerView
    }
    
    private func setupFunctionGroups() {
        
        // MARK: scrollView & containerView
        
        let scrollView = UIScrollView()
        scrollView.backgroundColor = containerBackgroundColor
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let containerView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.distribution = .fill
            stackView.spacing = UIStackView.spacingUseSystem
            stackView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            stackView.isLayoutMarginsRelativeArrangement = true
            return stackView
        }()
        scrollView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // MARK: ANC
        
        ancModeSegmentedControl = {
            let ancSegmentedControl = UISegmentedControl(items: ancModeStrings)
            ancSegmentedControl.selectedSegmentIndex = 1 // Default is Off
            ancSegmentedControl.addTarget(self, action: #selector(onAncModeChanged), for: .valueChanged)
            return ancSegmentedControl
        }()
        
        ancSettingsButton = {
            let button = UIButton(type: .system)
            button.setTitle("anc_settings".localized, for: .normal)
            button.addTarget(self, action: #selector(clickAncSettings), for: .touchUpInside)
            return button
        }()
        
        let ancStackView = [ancModeSegmentedControl, ancSettingsButton].functionGroup
        let ancContainerView = newFunctionGroup(title: "anc".localized, subView: ancStackView)
        containerView.addArrangedSubview(ancContainerView)
            
        
        // MARK: Sound Effect
        
        eqLabel = UILabel()
        let eqFunctionView = newFunctionItem(title: "equalizer".localized, actionView: nil, label: eqLabel)
        eqFunctionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickEqualizer)))
        
        bassEngineSwitch = UISwitch()
        bassEngineSwitch.addTarget(self, action: #selector(clickBassEngine(_:)), for: .valueChanged)
        let bassEngineFunctionView = newFunctionItem(title: "bass_engine_switch_title".localized, actionView: bassEngineSwitch, description: nil)
        
        bassEngineValueSlider = UISlider()
        bassEngineValueSlider.addTarget(self, action: #selector(clickBassEngineSlider(_:)), for: .touchUpInside)
        
        spatialAudioSwitch = UISwitch()
        spatialAudioSwitch.addTarget(self, action: #selector(clickSpatialAudio(_:)), for: .valueChanged)
        let spatialAudioFunctionView = newFunctionItem(title: "spatial_audio_switch_title".localized, actionView: spatialAudioSwitch, description: nil)
        
        antiWindNoiseSwitch = UISwitch()
        antiWindNoiseSwitch.addTarget(self, action: #selector(clickAntiWindNoise(_:)), for: .valueChanged)
        let antiWindNoiseFunctionView = newFunctionItem(title: "anti_wind_noise_switch_title".localized, actionView: antiWindNoiseSwitch, description: nil)
        
        let soundEffectStackView = [eqFunctionView, bassEngineFunctionView, bassEngineValueSlider, spatialAudioFunctionView, antiWindNoiseFunctionView].functionGroup
        
        let soundEffectContainerView = newFunctionGroup(title: "sound_effect_title".localized, subView: soundEffectStackView)
        containerView.addArrangedSubview(soundEffectContainerView)
        
        // MARK: Key
        
        // 位置
        let leftLabel = UILabel()
        leftLabel.textAlignment = .center
        leftLabel.text = "key_function_left".localized
        let leftLabelView = newKeyActionView(nameLabel: leftLabel, indicatorView: nil)
        
        let rightLabel = UILabel()
        rightLabel.textAlignment = .center
        rightLabel.text = "key_function_right".localized
        let rightLabelView = newKeyActionView(nameLabel: rightLabel, indicatorView: nil)
        
        let keyTitleView = newKeyFunctionItem(title: nil, actionView1: leftLabelView, actionView2: rightLabelView)
        
        // Single
        leftSingleTapLabel = UILabel()
        let leftSingleTapLabelView = newKeyActionView(nameLabel: leftSingleTapLabel, indicatorView: newArrowLabel())
        let leftSingleTapGesture = KeyTapGestureRecognizer(target: self, action: #selector(clickKeyFunction))
        leftSingleTapGesture.associatedObject = leftSingleTapLabel
        leftSingleTapLabelView.addGestureRecognizer(leftSingleTapGesture)
        
        rightSingleTapLabel = UILabel()
        let rightSingleTapLabelView = newKeyActionView(nameLabel: rightSingleTapLabel, indicatorView: newArrowLabel())
        let rightSingleTapLabelGesture = KeyTapGestureRecognizer(target: self, action: #selector(clickKeyFunction))
        rightSingleTapLabelGesture.associatedObject = rightSingleTapLabel
        rightSingleTapLabelView.addGestureRecognizer(rightSingleTapLabelGesture)
        
        let singleTapFunctionView = newKeyFunctionItem(title: "key_function_single_tap".localized, actionView1: leftSingleTapLabelView, actionView2: rightSingleTapLabelView)
        
        // Double
        leftDoubleTapLabel = UILabel()
        let leftDoubleTapLabelView = newKeyActionView(nameLabel: leftDoubleTapLabel, indicatorView: newArrowLabel())
        let leftDoubleTapGesture = KeyTapGestureRecognizer(target: self, action: #selector(clickKeyFunction))
        leftDoubleTapGesture.associatedObject = leftDoubleTapLabel
        leftDoubleTapLabelView.addGestureRecognizer(leftDoubleTapGesture)
        
        rightDoubleTapLabel = UILabel()
        let rightDoubleTapLabelView = newKeyActionView(nameLabel: rightDoubleTapLabel, indicatorView: newArrowLabel())
        let rightDoubleTapGesture = KeyTapGestureRecognizer(target: self, action: #selector(clickKeyFunction))
        rightDoubleTapGesture.associatedObject = rightDoubleTapLabel
        rightDoubleTapLabelView.addGestureRecognizer(rightDoubleTapGesture)
        
        let doubleTapFunctionView = newKeyFunctionItem(title: "key_function_double_tap".localized, actionView1: leftDoubleTapLabelView, actionView2: rightDoubleTapLabelView)
        
        // Triple
        leftTripleTapLabel = UILabel()
        let leftTripleTapLabelView = newKeyActionView(nameLabel: leftTripleTapLabel, indicatorView: newArrowLabel())
        let leftTripleTapGesture = KeyTapGestureRecognizer(target: self, action: #selector(clickKeyFunction))
        leftTripleTapGesture.associatedObject = leftTripleTapLabel
        leftTripleTapLabelView.addGestureRecognizer(leftTripleTapGesture)
        
        rightTripleTapLabel = UILabel()
        let rightTripleTapLabelView = newKeyActionView(nameLabel: rightTripleTapLabel, indicatorView: newArrowLabel())
        let rightTripleTapGesture = KeyTapGestureRecognizer(target: self, action: #selector(clickKeyFunction))
        rightTripleTapGesture.associatedObject = rightTripleTapLabel
        rightTripleTapLabelView.addGestureRecognizer(rightTripleTapGesture)
        
        let tripleTapFunctionView = newKeyFunctionItem(title: "key_function_triple_tap".localized, actionView1: leftTripleTapLabelView, actionView2: rightTripleTapLabelView)
        
        // Long Press
        leftLongPressLabel = UILabel()
        let leftLongPressLabelView = newKeyActionView(nameLabel: leftLongPressLabel, indicatorView: newArrowLabel())
        let leftLongPressGesture = KeyTapGestureRecognizer(target: self, action: #selector(clickKeyFunction))
        leftLongPressGesture.associatedObject = leftLongPressLabel
        leftLongPressLabelView.addGestureRecognizer(leftLongPressGesture)
        
        rightLongPressLabel = UILabel()
        let rightLongPressLabelView = newKeyActionView(nameLabel: rightLongPressLabel, indicatorView: newArrowLabel())
        let rightLongPressGesture = KeyTapGestureRecognizer(target: self, action: #selector(clickKeyFunction))
        rightLongPressGesture.associatedObject = rightLongPressLabel
        rightLongPressLabelView.addGestureRecognizer(rightLongPressGesture)
        
        let longPressFunctionView = newKeyFunctionItem(title: "key_function_long_press".localized, actionView1: leftLongPressLabelView, actionView2: rightLongPressLabelView)
        
        let keyStackView = [keyTitleView, singleTapFunctionView, doubleTapFunctionView, tripleTapFunctionView, longPressFunctionView].functionGroup
        
        let keyContainerView = newFunctionGroup(title: "key_function_title".localized, subView: keyStackView)
        containerView.addArrangedSubview(keyContainerView)
        
        leftKeyViews = [ leftSingleTapLabelView, leftDoubleTapLabelView, leftTripleTapLabelView, leftLongPressLabelView ]
        rightKeyViews = [ rightSingleTapLabelView, rightDoubleTapLabelView, rightTripleTapLabelView, rightLongPressLabelView ]
        
        tapKeyLabels = [
            leftSingleTapLabel, rightSingleTapLabel,
            leftDoubleTapLabel, rightDoubleTapLabel,
            leftTripleTapLabel, rightTripleTapLabel,
            leftLongPressLabel, rightLongPressLabel,
        ]
        
        // MARK: Earbuds
        
        multipointLabel = UILabel()
        let multipointFunctionView = newFunctionItem(title: "multipoint".localized, actionView: nil, label: multipointLabel)
        multipointFunctionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickMultipoint)))
        
        renameDeviceLabel = UILabel()
        let renameDeviceFunctionView = newFunctionItem(title: "device_rename_title".localized, actionView: nil, label: renameDeviceLabel)
        renameDeviceFunctionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickRenameDevice)))
        
        workModeLabel = UILabel()
        let workModeFunctionView = newFunctionItem(title: "work_mode_title".localized, actionView: nil, label: workModeLabel)
        workModeFunctionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickWorkMode)))
        
        ledSwitch = UISwitch()
        ledSwitch.addTarget(self, action: #selector(clickLedSwitch(_:)), for: .valueChanged)
        let ledSwitchFunctionView = newFunctionItem(title: "led_switch_title".localized, actionView: ledSwitch, description: nil)
        
        findDeviceSwitch = UISwitch()
        findDeviceSwitch.addTarget(self, action: #selector(clickFindDevice(_:)), for: .valueChanged)
        let findDeviceFunctionView = newFunctionItem(title: "find_device_title".localized, actionView: findDeviceSwitch, description: "find_device_tip".localized)
        
        let earbudsStackView = [multipointFunctionView, renameDeviceFunctionView, workModeFunctionView, ledSwitchFunctionView, findDeviceFunctionView].functionGroup
        
        let earbudsContainerView = newFunctionGroup(title: "earbuds_functions_title".localized, subView: earbudsStackView)
        containerView.addArrangedSubview(earbudsContainerView)
        
        // MARK: Device
        
        let updateFirmwareFunctionView = newFunctionItem(title: "update_firmware_title".localized, actionView: nil, description: nil)
        updateFirmwareFunctionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickUpdateFirmware)))
        
        let restoreSettingsFunctionView = newFunctionItem(title: "factory_reset_title".localized, actionView: nil, description: nil)
        restoreSettingsFunctionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickRestoreSettings)))
        
        let clearRecordFunctionView = newFunctionItem(title: "clear_pair_record_title".localized, actionView: nil, description: nil)
        clearRecordFunctionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickClearPairRecord)))
        
        let deviceStackView = [updateFirmwareFunctionView, restoreSettingsFunctionView, clearRecordFunctionView].functionGroup
        
        let deviceContainerView = newFunctionGroup(title: nil, subView: deviceStackView)
        containerView.addArrangedSubview(deviceContainerView)
        
        // 用来控制支持功能的显示
        ancLayout = ancContainerView
        bassEngineLayout = bassEngineFunctionView
        spatialAudioLayout = spatialAudioFunctionView
        antiWindNoiseLayout = antiWindNoiseFunctionView
    }
    
}

// MARK: - Request
fileprivate extension FunctionViewController {
    
    private func startWaitingResponse() {
        sendingIndicator.startAnimating()
    }
    
    private func stopWaitingResponse() {
        sendingIndicator.stopAnimating()
    }
    
    private func sendRequestAndWaitSuccess(_ request: Request, completion: SimpleRequestCompletion?) {
        
        // Check if device is connected
        guard viewModel.activeDevice.value != nil else {
            return
        }
        
        // TODO: 加上发送等待画面
        startWaitingResponse()
        
        viewModel.sendRequest(request) { [weak self] result, timeout in
            
            // todo: 解除发送等待
            self?.stopWaitingResponse()
            
            if timeout {
                self?.logger?.d(.functionVC, "Request timeout")
                Toast(text: "request_timeout".localized).show()
            } else if let result = result {
                if result {
                    self?.logger?.d(.functionVC, "Request succeeded")
                    Toast(text: "request_succeeded".localized).show()
                } else {
                    self?.logger?.d(.functionVC, "Request failed")
                    Toast(text: "request_failed".localized).show()
                }
            }
            
            completion?(result, timeout)
        }
    }
}

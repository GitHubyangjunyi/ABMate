//
//  AncSettingsViewController.swift
//  ABMate
//
//  Created by Bluetrum on 2022/3/5.
//

import UIKit
import SnapKit
import RxSwift
import Utils
import DeviceManager
import Toaster

class AncSettingsViewController: UIViewController {
    
    weak var logger: LoggerDelegate? = DefaultLogger.shared
    
    private let viewModel = SharedViewModel.shared
    private let disposeBag = DisposeBag()
    
    private var sendingIndicator: UIActivityIndicatorView!
    
    private var ancGainView: UIView!
    private var ancGainSlider: UISlider!
    private var ancGainLabel: UILabel!
    private var transparencyGainView: UIView!
    private var transparencyGainSlider: UISlider!
    private var transparencyGainLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "anc_settings_title".localized

        setupViews()
        setupObserver()
        
        // Sending Indicator
        if #available(iOS 13, *) {
            sendingIndicator = UIActivityIndicatorView(style: .medium)
        } else {
            sendingIndicator = UIActivityIndicatorView(style: .white)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sendingIndicator)
        
        // Update ANC & Transparency Gain
        let request = DeviceInfoRequest(Command.INFO_ANC_GAIN)
            .requireInfo(Command.INFO_TRANSPARENCY_GAIN)
        viewModel.sendRequest(request)
    }
    
    private func setupViews() {
        let containerView = view!
        
        ancGainView = {
            let containerView = UIView();
            
            ancGainSlider = {
                let slider = UISlider()
                slider.minimumValue = 0.0
                slider.maximumValue = 1.0
                slider.addTarget(self, action: #selector(ancGainSliderTouchUpInside(_:)), for: .touchUpInside)
                return slider
            }()
            containerView.addSubview(ancGainSlider)
            
            ancGainLabel = {
                let label = UILabel()
                label.text = "anc_gain_level".localized
                return label
            }()
            containerView.addSubview(ancGainLabel)
            
            ancGainSlider.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview().inset(8)
            }
            ancGainLabel.snp.makeConstraints { make in
                make.top.equalTo(ancGainSlider.snp.bottom).offset(8)
                make.centerX.equalToSuperview()
            }
            
            return containerView
        }()
        
        transparencyGainView = {
            let containerView = UIView()
            
            transparencyGainSlider = {
                let slider = UISlider()
                slider.minimumValue = 0.0
                slider.maximumValue = 1.0
                slider.addTarget(self, action: #selector(transparencyGainSliderTouchUpInside(_:)), for: .touchUpInside)
                return slider
            }()
            containerView.addSubview(transparencyGainSlider)
            
            transparencyGainLabel = {
                let label = UILabel()
                label.text = "anc_transparency_level".localized
                return label
            }()
            containerView.addSubview(transparencyGainLabel)
            
            transparencyGainSlider.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview().inset(8)
            }
            transparencyGainLabel.snp.makeConstraints { make in
                make.top.equalTo(transparencyGainSlider.snp.bottom).offset(8)
                make.centerX.equalToSuperview()
            }
            
            return containerView
        }()
        
        containerView.addSubview(ancGainView)
        containerView.addSubview(transparencyGainView)
        
        ancGainView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top).inset(8)
            make.bottom.equalTo(ancGainLabel).offset(8)
        }
        transparencyGainView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.top.equalTo(ancGainView.snp.bottom).offset(8)
            make.bottom.equalTo(transparencyGainLabel).offset(8)
        }
    }
    
    private func setupObserver() {
        viewModel.deviceAncMode.subscribeOnNext { [unowned self] in
            if let ancMode = $0, let mode = AncMode(rawValue: ancMode){
                switch mode {
                case .off:
                    self.ancGainSlider.isEnabled = false
                    self.transparencyGainSlider.isEnabled = false
                    self.ancGainLabel.isEnabled = false
                    self.transparencyGainLabel.isEnabled = false
                case .on:
                    self.ancGainSlider.isEnabled = true
                    self.ancGainLabel.isEnabled = true
                    self.ancGainView.isHidden = false
                    self.transparencyGainView.isHidden = true
                case .transparency:
                    self.transparencyGainSlider.isEnabled = true
                    self.transparencyGainLabel.isEnabled = true
                    self.ancGainView.isHidden = true
                    self.transparencyGainView.isHidden = false
                }
            }
            // ANC not support, or ANC mode not support
            else {
                self.ancGainSlider.isEnabled = false
                self.transparencyGainSlider.isEnabled = false
                self.ancGainLabel.isEnabled = false
                self.transparencyGainLabel.isEnabled = false
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceAncGainNum.subscribeOnNext { [unowned self] in
            self.logger?.v(.ancSettingsVC, "ANC Gain Num: \(String(describing: $0))")
            if let ancGainNum = $0 {
                self.ancGainSlider.maximumValue = Float(ancGainNum)
            }
            self.ancGainSlider.isHidden = $0 == nil
        }.disposed(by: disposeBag)
        
        viewModel.deviceTransparencyGainNum.subscribeOnNext { [unowned self] in
            self.logger?.v(.ancSettingsVC, "Transparency Gain Num: \(String(describing: $0))")
            if let transparencyGainNum = $0 {
                self.transparencyGainSlider.maximumValue = Float(transparencyGainNum)
            }
            self.transparencyGainSlider.isHidden = $0 == nil
        }.disposed(by: disposeBag)
        
        viewModel.deviceAncGain.subscribeOnNext { [unowned self] in
            self.logger?.v(.ancSettingsVC, "ANC Gain: \(String(describing: $0))")
            if let ancGain = $0 {
                self.ancGainSlider.setValue(Float(ancGain), animated: true)
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceTransparencyGain.subscribeOnNext { [unowned self] in
            self.logger?.v(.ancSettingsVC, "Transparency Gain: \(String(describing: $0))")
            if let transparencyGain = $0 {
                self.transparencyGainSlider.setValue(Float(transparencyGain), animated: true)
            }
        }.disposed(by: disposeBag)
    }
    
    private func sliderRoundedValue(_ slider: UISlider) -> Int {
        return lroundf(slider.value)
    }
    
    @objc
    private func ancGainSliderTouchUpInside(_ slider: UISlider) {
        
        let roundValue = sliderRoundedValue(slider)
        slider.setValue(Float(roundValue), animated: true)
        
        let request = AncRequest.ncLevelRequest(ncLevel: UInt8(roundValue))
        sendRequestAndWaitSuccess(request, completion: nil)
    }
    
    @objc
    private func transparencyGainSliderTouchUpInside(_ slider: UISlider) {
        
        let roundValue = sliderRoundedValue(slider)
        slider.setValue(Float(roundValue), animated: true)
        
        let request = AncRequest.transparencyLevelRequest(transparencyLevel: UInt8(roundValue))
        sendRequestAndWaitSuccess(request, completion: nil)
    }
    
}

// MARK: - Request

fileprivate extension AncSettingsViewController {
    
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

//
//  RemoteEqViewController.swift
//  ABMate
//
//  Created by Bluetrum on 2022/3/5.
//

import UIKit
import DeviceManager
import RxSwift
import SnapKit
import Utils

/// EQ设置存储在耳机的时候使用
/// Use this when EQ settings are stored in earbuds
class RemoteEqViewController: UIViewController {
    
    weak var logger: LoggerDelegate? = DefaultLogger.shared
    
    private let viewModel = SharedViewModel.shared
    private let disposeBag = DisposeBag()
    
    private var eqView: EqualizerView!
    private var collectionView: UICollectionView!
    
    private var eqPresetSettings: [RemoteEqSetting]!
    private var eqCustomSettings: [RemoteEqSetting]!
    
    private var currentEqMode: UInt8?
    private var currentEqGains: [Int8]?
    
    private let presetEqName: [String] = [
        // Index <-> eqMode
        "eq_setting_default".localized,
        "eq_setting_pop".localized,
        "eq_setting_rock".localized,
        "eq_setting_jazz".localized,
        "eq_setting_classic".localized,
        "eq_setting_country".localized,
        // More...
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "equalizer_title".localized
        
        // 进来这个VC说明RemoteEqSettings有值，直接解包
        // Enter here indicates RemoteEqSettings isn't nil, unwrap it directly
        eqPresetSettings = viewModel.deviceRemoteEqSettings.value!.preset
        eqCustomSettings = viewModel.deviceRemoteEqSettings.value!.custom
        
        setupEqualizerView()
        setupCollectionView()
        
        setupDeviceInfo()
        
        // 获取最新EQ配置
        let request = DeviceInfoRequest(Command.INFO_EQ_SETTING)
            .requireInfo(Command.INFO_ALL_EQ_SETTINGS)
        viewModel.sendRequest(request)
    }
    
    private func setupEqualizerView() {
        self.eqView = {
            let bands = [8, 31, 62, 125, 250, 500, 1000, 2000, 4000, 16000]
            let eqView = EqualizerView(gains: bands)
            eqView.maxValue =  RemoteEqSetting.EQUALIZER_VIEW_MAX_VALUE
            eqView.minValue = -RemoteEqSetting.EQUALIZER_VIEW_MAX_VALUE
            eqView.delegate = self
            view.addSubview(eqView)
            eqView.snp.makeConstraints { make in
                make.top.equalTo(view.layoutMarginsGuide.snp.top)
                make.left.right.equalTo(view.safeAreaLayoutGuide)
                make.height.equalTo(240)
            }
            return eqView
        }()
    }
    
    private func setupCollectionView() {
        collectionView = {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(EQSettingCell.self, forCellWithReuseIdentifier: "EQSettingCell")
            #if DEBUG
                collectionView.backgroundColor = .blue.withAlphaComponent(0.3)
            #endif
            view.addSubview(collectionView)
            collectionView.snp.makeConstraints { make in
                make.top.equalTo(eqView.snp.bottom)
                make.bottom.left.right.equalTo(view.safeAreaLayoutGuide)
            }
            return collectionView
        }()
    }
    
    private func setupDeviceInfo() {
        
        viewModel.deviceEqSetting.subscribeOnNext { [unowned self] in
            if let deviceEqSetting = $0 {
                self.logger?.v(.equalizerVC, "deviceEqSetting: \(deviceEqSetting)")
                
                self.eqView.isEnabled = deviceEqSetting.isCustom
                self.eqView.setValues(deviceEqSetting.gains)
                
                self.currentEqMode = deviceEqSetting.mode
                self.currentEqGains = deviceEqSetting.gains
                self.collectionView.reloadData()
            }
        }.disposed(by: disposeBag)
        
        viewModel.deviceRemoteEqSettings.subscribeOnNext { [unowned self] in
            if let deviceRemoteEqSettings = $0 {
                self.eqPresetSettings = deviceRemoteEqSettings.preset
                self.eqCustomSettings = deviceRemoteEqSettings.custom
                self.collectionView.reloadData()
            }
        }.disposed(by: disposeBag)
    }
}

extension RemoteEqViewController: EqualizerViewDelegate {
    
    func onBandLevelChanged(bandId: Int, progress: Int) {
//        logger?.v(.equalizerVC, "onBandLevelChanged: \(bandId) \(progress)")
    }
    
    func onStart(bandId: Int) {
//        logger?.v(.equalizerVC, "onStart: \(bandId)")
    }
    
    func onStop(bandId: Int) {
//        logger?.v(.equalizerVC, "onStop: \(bandId)")
    }
    
    func onAllStop() {
        let gains = eqView.gains
        currentEqGains = gains

        logger?.v(.equalizerVC, "onAllStop: \(gains)")

        if let currentEqMode = currentEqMode {
            
            let eqRequest = EqRequest(eqMode: currentEqMode, gains: gains)
            viewModel.sendEqRequest(eqRequest) { [weak self] result, timeout in
                self?.logger?.v(.equalizerVC, "EQ, result: \(String(describing: result)), timeout: \(timeout)")
                if !timeout {
                    self?.currentEqMode = currentEqMode
                    self?.currentEqGains = gains
                    
                    let eqSetting = RemoteEqSetting(mode: currentEqMode, gains: gains)
                    if let index = self?.eqCustomSettings.firstIndex(where: { setting in
                        setting.mode == currentEqMode
                    }) {
                        self?.eqCustomSettings[index] = eqSetting
                    }
                    
                    self?.collectionView.reloadData()
                }
            }
        }
        collectionView.reloadData()
    }
    
}

extension RemoteEqViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allEQSettings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EQSettingCell", for: indexPath) as! EQSettingCell
        
        let eqSetting = allEQSettings[indexPath.row]
        if eqSetting.isPreset {
            cell.title = presetEqName[Int(eqSetting.mode)]
        } else {
            cell.title = "\("equalizer_eq_custom".localized) \(eqSetting.customIndex + 1)"
        }
        
        // 显示目前匹配的EQ
        if let currentEqMode = currentEqMode, let currentEqGains = currentEqGains {
            cell.isSelected = currentEqMode == eqSetting.mode && currentEqGains == eqSetting.gains
        } else {
            cell.isSelected = false
        }
        
        return cell
    }
    
}

extension RemoteEqViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let eqSetting = allEQSettings[indexPath.row]
        
        currentEqMode = eqSetting.mode
        
        let gains = eqSetting.gains
        eqView.setValues(gains)
        currentEqGains = gains
        
        eqView.isEnabled = eqSetting.isCustom
        
        // 发送设置请求
        let request = EqRequest(eqMode: eqSetting.mode, gains: eqSetting.gains)
        viewModel.sendEqRequest(request) { [weak self] result, timeout in
            if timeout {
                self?.logger?.v(.equalizerVC, "Send request timeout")
            } else {
                self?.logger?.v(.equalizerVC, "Send request \(result! ? "OK" : "failed")")
            }
            self?.currentEqMode = eqSetting.mode
            self?.currentEqGains = eqSetting.gains
            self?.collectionView.reloadData()
        }
    }
    
}

fileprivate extension RemoteEqViewController {
    
    var allEQSettings: [RemoteEqSetting] {
        return eqPresetSettings + eqCustomSettings
    }
    
}

//
//  EqualizerViewController.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/22.
//

import UIKit
import DeviceManager
import RxSwift
import SnapKit
import Utils
import CoreData

/// EQ设置存储在App的时候使用
/// Use this when EQ settings are stored in App
class EqualizerViewController: UIViewController {
    
    static let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var context: NSManagedObjectContext { EqualizerViewController.context }
    
    weak var logger: LoggerDelegate? = DefaultLogger.shared
    
    private let viewModel = SharedViewModel.shared
    private let disposeBag = DisposeBag()
    
    private var eqView: EqualizerView!
    private var collectionView: UICollectionView!
    
    private var editButton: UIBarButtonItem!
    
    private var eqSettingsList: [EqSetting]!
    private var customEqSettings: [EqSetting] = []
    private var eqSavedSettings: [EqSavedSetting]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "equalizer_title".localized
        
        setupEqualizerView()
        setupCollectionView()
        setupBarButtons()
        
        setupDeviceInfo()
        
        loadCustomEqSettings()
        eqSettingsList = allEQSettings
        
        // 获取最新EQ配置
        viewModel.sendRequest(DeviceInfoRequest(Command.INFO_EQ_SETTING))
    }
    
    private func setupEqualizerView() {
        self.eqView = {
            let bands = [8, 31, 62, 125, 250, 500, 1000, 2000, 4000, 16000]
            let eqView = EqualizerView(gains: bands)
            eqView.maxValue =  EqSetting.EQUALIZER_VIEW_MAX_VALUE
            eqView.minValue = -EqSetting.EQUALIZER_VIEW_MAX_VALUE
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
    
    @objc
    private func tapEditButton(_ button: UIBarButtonItem) {
        isEditing = !isEditing
        if isEditing {
            button.title = "cancel".localized
        } else {
            button.title = "edit".localized
        }
        
        // TODO: Freeze eqView
        eqSettingsList = allEQSettings
        collectionView.reloadData()
    }
    
    private func setupBarButtons() {
        editButton = {
            let barButton = UIBarButtonItem(title: "edit".localized, style: .plain, target: self, action: #selector(tapEditButton))
            navigationItem.rightBarButtonItem = barButton
            return barButton
        }()
    }
    
    private func setupDeviceInfo() {
        
        viewModel.deviceEqSetting.subscribeOnNext { [unowned self] in
            if let deviceEqSetting = $0 {
                self.logger?.v(.equalizerVC, "deviceEqSetting: \(deviceEqSetting)")
                
                self.eqView.setValues(deviceEqSetting.gains)
                
                self.eqSettingsList = self.allEQSettings
                self.collectionView.reloadData()
            }
        }.disposed(by: disposeBag)
    }
    
}

extension EqualizerViewController: EqualizerViewDelegate {
    
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
        let gainLevels = eqView.gains
        
        logger?.v(.equalizerVC, "onAllStop: \(gainLevels)")
        
        let eqRequest = EqRequest.CustomEqRequest(eqMode: 0, gains: gainLevels)
        viewModel.sendEqRequest(eqRequest) { [weak self] result, timeout in
            self?.logger?.v(.equalizerVC, "EQ, result: \(String(describing: result)), timeout: \(timeout)")
            if !timeout {
                self?.collectionView.reloadData()
            }
        }
        eqSettingsList = allEQSettings
        collectionView.reloadData()
    }
    
}

extension EqualizerViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return eqSettingsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EQSettingCell", for: indexPath) as! EQSettingCell
        
        let eqSetting = eqSettingsList[indexPath.row]
        cell.title = eqSetting.name
        cell.isEditing = eqSetting.isCustom && isEditing
        
        if eqSetting != PresetEqSetting.eqSettingAdd {
            // 配置删除按键
            if let eqSavedSettings = eqSavedSettings, eqSetting.isCustom {
                let indexOfCustom = indexPath.row - PresetEqSetting.allPresetEqSettings.count
                cell.deleteButton.associatedEntity = eqSavedSettings[indexOfCustom]
            }
            cell.deleteButton.addTarget(self, action: #selector(deleteEQSetting(_:)), for: .touchUpInside)
            // 显示目前匹配的EQ
            cell.isSelected = eqView.gains == eqSetting.gains
        }
        
        return cell
    }
    
}

extension EqualizerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard isEditing == false else {
            return
        }
        
        // 设置选择的EQ
        let eqSetting = eqSettingsList[indexPath.row]
        if eqSetting == PresetEqSetting.eqSettingAdd {
            // 存储到永久存储
            let title = "equalizer_eq_name".localized
            let message = "equalizer_eq_name_tip".localized
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addTextField { eqNameTextField in
                eqNameTextField.text = "equalizer_eq_custom".localized
            }
            let okAction = UIAlertAction(title: "ok", style: .default, handler: { action in
                let eqName = alertController.textFields![0].text!
                if eqName.isEmpty {
                    self.presentAlert(title: nil, message: "equalizer_eq_name_empty_alert".localized)
                } else {
                    let setting = EqSetting(name: eqName, gains: self.eqView.gains)
                    self.saveCustomEqSetting(setting)
                }
            })
            alertController.addAction(okAction)
            alertController.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            let gainLevels = eqSetting.gains
            eqView.setValues(gainLevels)
            
            // 发送设置请求
            let request: EqRequest
            if eqSetting.isCustom {
                let customModeIndex = UInt8(indexPath.row - PresetEqSetting.allPresetEqSettings.count)
                request = EqRequest.CustomEqRequest(eqMode: customModeIndex, gains: gainLevels)
            } else {
                let presetModeIndex = UInt8(indexPath.row)
                request = EqRequest.PresetEqRequest(eqMode: presetModeIndex, gains: gainLevels)
            }
            viewModel.sendEqRequest(request) { [weak self] result, timeout in
                if !timeout {
                    self?.collectionView.reloadData()
                }
            }
        }
        eqSettingsList = allEQSettings
        collectionView.reloadData()
    }
    
}

// MARK: - Custom EQ, persistant storage

fileprivate extension UIButton {
    
    private struct AssociatedKeys {
        static var eqEntity = "eq_entity"
    }
    
    var associatedEntity: EqSavedSetting? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.eqEntity) as? EqSavedSetting
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.eqEntity, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}

extension EqualizerViewController {
    
    func loadCustomEqSettings() {
        let request: NSFetchRequest<EqSavedSetting> = EqSavedSetting.fetchRequest()
        do {
            eqSavedSettings = try context.fetch(request)
            customEqSettings = eqSavedSettings!.convertToEqSettings()
        }
        catch {
            logger?.w(.equalizerVC, "Error loading EqSavedSetting: \(error)")
        }
        eqSettingsList = allEQSettings
        collectionView?.reloadData()
    }
    
    func convertToSaved(_ setting: EqSetting) -> EqSavedSetting {
        let name = setting.name
        let gains = setting.gains.map { UInt8(bitPattern: $0) }
        
        let entity = NSEntityDescription.entity(forEntityName: "EqSavedSetting", in: context)!
        let eqSavedSetting = EqSavedSetting(entity: entity, insertInto: context)
        eqSavedSetting.name = name
        eqSavedSetting.gains = Data(gains)
        return eqSavedSetting
    }
    
    func saveCustomEqSetting(_ setting: EqSetting) {
        let eqSavedSetting = convertToSaved(setting)
        context.insert(eqSavedSetting)
        
        do {
            try context.save()
        } catch {
            logger?.w(.equalizerVC, "Failed to save custom EQ Setting: \(error)")
        }
        loadCustomEqSettings()
    }
    
    func deleteCustomEqSetting(_ eqSavedSetting: EqSavedSetting) {
        
        context.delete(eqSavedSetting)
        
        do {
            try context.save()
        } catch {
            logger?.w(.equalizerVC, "Failed to delete custom EQ Setting: \(error)")
        }
        loadCustomEqSettings()
    }
    
    @objc
    func deleteEQSetting(_ sender: UIButton) {
        
        if let eqSavedSetting = sender.associatedEntity {
            let title = String(format: "equalizer_delete_alert".localized, eqSavedSetting.name!)
            let message = "equalizer_delete_confirm".localized
            let okAction = UIAlertAction(title: "ok".localized, style: .default, handler: { action in
                // Execute delete
                self.deleteCustomEqSetting(eqSavedSetting)
            })
            presentAlert(title: title, message: message, cancelable: true, option: okAction, handler: nil)
        }
    }
    
}

// MARK: - EQ List

fileprivate extension EqualizerViewController {
    
    /// 所有Preset和Custom的EQSetting，和ADD
    var allEQSettings: [EqSetting] {
        var settings = allPresetAndCustomEQSettings
        if indexOfEQSetting(eqView.gains) == nil && !isEditing {
            settings.append(PresetEqSetting.eqSettingAdd)
        }
        return settings
    }
    
    /// 所有Preset和Custom的EQSetting
    var allPresetAndCustomEQSettings: [EqSetting] {
        return PresetEqSetting.allPresetEqSettings + allCustomEQSettings
    }
    
    /// 所有Custom的EQSetting
    var allCustomEQSettings: [EqSetting] {
        return customEqSettings
    }
    
    func indexOfEQSetting(_ gainLevels: [Int8]) -> Int? {
        
        for (index, eqSetting) in allPresetAndCustomEQSettings.enumerated() {
            if eqSetting.gains == gainLevels {
                return index
            }
        }
        return nil
    }
    
}

//
//  EQEqualizerCoreData.swift
//  ABMate
//
//  Created by 杨俊艺 on 2025/8/15.
//

import UIKit
import CoreData

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
    
    @objc func deleteEQSetting(_ sender: UIButton) {
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

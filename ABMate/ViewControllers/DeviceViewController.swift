//
//  DeviceViewController.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/23.
//

import UIKit
import RxSwift
import Utils

class DeviceViewController: UIViewController {
    
    weak var logger: LoggerDelegate? = DefaultLogger.shared
    
    private let viewModel = SharedViewModel.shared
    private let disposeBag = DisposeBag()
    
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupTableView()
        
        setupDeviceInfo()
        
        viewModel.activeDevice.subscribeOnNext { [unowned self] in
            if let activeDevice = $0 {
                self.title = activeDevice.peripheral.name
            } else {
                self.title = "device_disconnected".localized
                // Disconnected -> Exit
                navigationController?.popViewController(animated: true)
            }
        }.disposed(by: disposeBag)
    }
    
    private func setupTableView() {
        tableView = UITableView()
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Device Info

    private func setupDeviceInfo() {
        
        viewModel.devicePower.subscribeOnNext { [unowned self] in
            if let devicePower = $0 {
                print("devicePower: \(String(describing: devicePower))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceFirmwareVersion.subscribeOnNext { [unowned self] in
            if let deviceFirmwareVersion = $0 {
                print("deviceFirmwareVersion: \(String(describing: deviceFirmwareVersion))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceName.subscribeOnNext { [unowned self] in
            if let deviceName = $0 {
                print("deviceName: \(String(describing: deviceName))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceEqSetting.subscribeOnNext { [unowned self] in
            if let deviceEqSetting = $0 {
                print("deviceEqSetting: \(String(describing: deviceEqSetting))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceKeySettings.subscribeOnNext { [unowned self] in
            if let deviceKeySettings = $0 {
                print("deviceKeySettings: \(String(describing: deviceKeySettings))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceVolume.subscribeOnNext { [unowned self] in
            if let deviceVolume = $0 {
                print("deviceVolume: \(String(describing: deviceVolume))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.devicePlayState.subscribeOnNext { [unowned self] in
            if let devicePlayState = $0 {
                print("devicePlayState: \(String(describing: devicePlayState))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceWorkMode.subscribeOnNext { [unowned self] in
            if let deviceWorkMode = $0 {
                print("deviceWorkMode: \(String(describing: deviceWorkMode))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceInEarStatus.subscribeOnNext { [unowned self] in
            if let deviceInEarStatus = $0 {
                print("deviceInEarStatus: \(String(describing: deviceInEarStatus))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceLanguageSetting.subscribeOnNext { [unowned self] in
            if let deviceLanguageSetting = $0 {
                print("deviceLanguageSetting: \(String(describing: deviceLanguageSetting))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceAutoAnswer.subscribeOnNext { [unowned self] in
            if let deviceAutoAnswer = $0 {
                print("deviceAutoAnswer: \(String(describing: deviceAutoAnswer))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceAncMode.subscribeOnNext { [unowned self] in
            if let deviceAncMode = $0 {
                print("deviceAncMode: \(String(describing: deviceAncMode))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceIsTws.subscribeOnNext { [unowned self] in
            if let deviceIsTws = $0 {
                print("deviceIsTws: \(String(describing: deviceIsTws))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceTwsConnected.subscribeOnNext { [unowned self] in
            if let deviceTwsConnected = $0 {
                print("deviceTwsConnected: \(String(describing: deviceTwsConnected))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceLedSwitch.subscribeOnNext { [unowned self] in
            if let deviceLedSwitch = $0 {
                print("deviceLedSwitch: \(String(describing: deviceLedSwitch))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceFwChecksum.subscribeOnNext { [unowned self] in
            if let deviceFwChecksum = $0 {
                print("deviceFwChecksum: \(String(describing: deviceFwChecksum.hex))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceAncGain.subscribeOnNext { [unowned self] in
            if let deviceAncGain = $0 {
                print("deviceAncGain: \(String(describing: deviceAncGain))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceTransparencyGain.subscribeOnNext { [unowned self] in
            if let deviceTransparencyGain = $0 {
                print("deviceTransparencyGain: \(String(describing: deviceTransparencyGain))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceAncGainNum.subscribeOnNext { [unowned self] in
            if let deviceAncGainNum = $0 {
                print("deviceAncGainNum: \(String(describing: deviceAncGainNum))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceTransparencyGainNum.subscribeOnNext { [unowned self] in
            if let deviceTransparencyGainNum = $0 {
                print("deviceTransparencyGainNum: \(String(describing: deviceTransparencyGainNum))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceMaxPacketSize.subscribeOnNext { [unowned self] in
            if let deviceMaxPacketSize = $0 {
                print("deviceMaxPacketSize: \(String(describing: deviceMaxPacketSize))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.deviceLeftIsMainSide.subscribeOnNext { [unowned self] in
            if let deviceLeftIsMainSide = $0 {
                print("deviceLeftIsMainSide: \(String(describing: deviceLeftIsMainSide))")
            }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
    }

}

extension DeviceViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 22
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell")
        }
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13)
        
        switch indexPath.row {
        case 0: cell.textLabel?.text = "devicePower: \(String(describing: viewModel.devicePower.value))"
        case 1: cell.textLabel?.text = "deviceFirmwareVersion: \(String(describing: viewModel.deviceFirmwareVersion.value))"
        case 2: cell.textLabel?.text = "deviceName: \(String(describing: viewModel.deviceName.value))"
        case 3: cell.textLabel?.text = "deviceEqSetting: \(String(describing: viewModel.deviceEqSetting.value))"
        case 4: cell.textLabel?.text = "deviceKeySettings: \(String(describing: viewModel.deviceKeySettings.value))"
        case 5: cell.textLabel?.text = "deviceVolume: \(String(describing: viewModel.deviceVolume.value))"
        case 6: cell.textLabel?.text = "devicePlayState: \(String(describing: viewModel.devicePlayState.value))"
        case 7: cell.textLabel?.text = "deviceWorkMode: \(String(describing: viewModel.deviceWorkMode.value))"
        case 8: cell.textLabel?.text = "deviceInEarStatus: \(String(describing: viewModel.deviceInEarStatus.value))"
        case 9: cell.textLabel?.text = "deviceLanguageSetting: \(String(describing: viewModel.deviceLanguageSetting.value))"
        case 10: cell.textLabel?.text = "deviceAutoAnswer: \(String(describing: viewModel.deviceAutoAnswer.value))"
        case 11: cell.textLabel?.text = "deviceAncMode: \(String(describing: viewModel.deviceAncMode.value))"
        case 12: cell.textLabel?.text = "deviceIsTws: \(String(describing: viewModel.deviceIsTws.value))"
        case 13: cell.textLabel?.text = "deviceTwsConnected: \(String(describing: viewModel.deviceTwsConnected.value))"
        case 14: cell.textLabel?.text = "deviceLedSwitch: \(String(describing: viewModel.deviceLedSwitch.value))"
        case 15: cell.textLabel?.text = "deviceAncGain: \(String(describing: viewModel.deviceAncGain.value))"
        case 16: cell.textLabel?.text = "deviceTransparencyGain: \(String(describing: viewModel.deviceTransparencyGain.value))"
        case 17: cell.textLabel?.text = "deviceAncGainNum: \(String(describing: viewModel.deviceAncGainNum.value))"
        case 18: cell.textLabel?.text = "deviceTransparencyGainNum: \(String(describing: viewModel.deviceTransparencyGainNum.value))"
        case 19: cell.textLabel?.text = "deviceFwChecksum: \(String(describing: viewModel.deviceFwChecksum.value?.hex ?? nil))"
        case 20: cell.textLabel?.text = "deviceMaxPacketSize: \(String(describing: viewModel.deviceMaxPacketSize.value))"
        case 21: cell.textLabel?.text = "deviceLeftIsMainSide: \(String(describing: viewModel.deviceLeftIsMainSide.value))"
        default: cell.textLabel?.text = "No Content"
        }

        return cell
    }

}

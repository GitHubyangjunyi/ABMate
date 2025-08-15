//
//  EqualizerView.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/21.
//

import UIKit
import SnapKit

@objc protocol EqualizerViewDelegate: NSObjectProtocol {
    @objc optional func onBandLevelChanged(bandId: Int, progress: Int)
    @objc optional func onStart(bandId: Int)
    @objc optional func onStop(bandId: Int)
    @objc optional func onAllStop()
}

class EqualizerView: UIView {
    
    public weak var delegate: EqualizerViewDelegate?
    
    private var bandLabels: [UILabel] = []
    private var valueLabels: [UILabel] = []
    private var sliders: [UISlider] = []
    
    private var touched: [Bool] = []
    
    public var maxValue: Int =  1 {
        didSet {
            for slider in sliders {
                slider.maximumValue = Float(maxValue)
            }
        }
    }
    public var minValue: Int = -1 {
        didSet {
            for slider in sliders {
                slider.minimumValue = Float(minValue)
            }
        }
    }
    
    public var isEnabled: Bool = true {
        didSet {
            sliders.forEach { $0.isEnabled = isEnabled }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("Use other initializers")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(gains: [Int8]) {
        let levels = gains.map { Int($0) }
        self.init(gains: levels)
    }
    
    convenience init(gains: [Int8], frame: CGRect) {
        let levels = gains.map { Int($0) }
        self.init(gains: levels, frame: frame)
    }
    
    convenience init(gains: [Int]) {
        self.init(gains: gains, frame: .zero)
    }
    
    convenience init(gains: [Int], frame: CGRect) {
        self.init(frame: frame)
        #if DEBUG
            backgroundColor = .gray.withAlphaComponent(0.3)
        #endif
        setupViews(gains: gains)
    }
    
    private func setupViews(gains: [Int]) {
        
        let bandCount = gains.count
        
        for (index, bandNum) in gains.enumerated() {
            // 频率标签
            let bandLabel = UILabel()
            #if DEBUG
                bandLabel.backgroundColor = .blue.withAlphaComponent(0.3)
            #endif
            bandLabel.text = formatBandNumber(bandNum)
            bandLabel.textAlignment = .center
            bandLabel.sizeToFit()
            addSubview(bandLabel)
            bandLabels.append(bandLabel)
            bandLabel.snp.makeConstraints { make in
                let mul = CGFloat(index * 2 + 1) / CGFloat(bandCount)
                make.centerX.equalTo(self.snp.centerX).multipliedBy(mul)
                make.top.equalToSuperview()
            }
            
            // 滑动条
            let bandSlider = UISlider()
            #if DEBUG
                bandSlider.backgroundColor = .green.withAlphaComponent(0.3)
            #endif
            addSubview(bandSlider)
            sliders.append(bandSlider)
            bandSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
            bandSlider.addTarget(self, action: #selector(sliderTouchDown(_:)), for: .touchDown)
            bandSlider.addTarget(self, action: #selector(sliderTouchUp(_:)), for: .touchUpInside)
            bandSlider.addTarget(self, action: #selector(sliderTouchUp(_:)), for: .touchUpOutside)
            bandSlider.addTarget(self, action: #selector(sliderTouchCancel(_:)), for: .touchCancel)
            bandSlider.snp.makeConstraints { make in
                make.width.equalTo(self.snp.height).offset(-2 * bandLabel.frame.size.height)
                let mul = CGFloat(index * 2 + 1) / CGFloat(bandCount)
                make.centerX.equalTo(self.snp.centerX).multipliedBy(mul)
                make.height.equalTo(bandLabel.snp.width)
                make.centerY.equalToSuperview()
            }
            bandSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
            
            // 值标签
            let valueLabel = UILabel()
            #if DEBUG
                valueLabel.backgroundColor = .red.withAlphaComponent(0.3)
            #endif
            valueLabel.text = "\(sliderRoundedValue(bandSlider))"
            valueLabel.textAlignment = .center
            addSubview(valueLabel)
            valueLabels.append(valueLabel)
            valueLabel.snp.makeConstraints { make in
                let mul = CGFloat(index * 2 + 1) / CGFloat(bandCount)
                make.centerX.equalTo(self.snp.centerX).multipliedBy(mul)
                make.bottom.equalToSuperview()
            }
            
            touched.append(false)
        }
    }
    
    private func formatBandNumber(_ bandNum: Int) -> String {
        var num = bandNum
        var sign = ""
        var unit = ""
        
        if num < 0 {
            num = -num
            sign = "-"
        }
        
        if num >= 1000 {
            num = num / 1000
            unit = "K"
        }
        
        let formattedString = "\(sign)\(num)\(unit)"
        return formattedString
    }
    
    // MARK: - Slider
    
    private func indexOfSlider(_ slider: UISlider) -> Int {
        return sliders.firstIndex(of: slider)!
    }
    
    private func sliderRoundedValue(_ slider: UISlider) -> Int {
        return lroundf(slider.value)
    }
    
    @objc
    private func sliderValueChanged(_ slider: UISlider) {
        
        let index = indexOfSlider(slider)
        let valueLabel = valueLabels[index]
        let roundValue = sliderRoundedValue(slider)
        valueLabel.text = "\(roundValue)"
        delegate?.onBandLevelChanged?(bandId: index, progress: roundValue)
    }
    
    @objc
    private func sliderTouchDown(_ slider: UISlider) {
        
        let index = indexOfSlider(slider)
        touched[index] = true
        delegate?.onStart?(bandId: index)
    }
    
    @objc
    private func sliderTouchUp(_ slider: UISlider) {
        
        let index = indexOfSlider(slider)
        let valueLabel = valueLabels[index]
        let roundValue = sliderRoundedValue(slider)
        valueLabel.text = "\(roundValue)"
        slider.setValue(Float(roundValue), animated: true)
        
        touched[index] = false
        
        delegate?.onStop?(bandId: index)
        
        checkIfAllStopped()
    }
    
    @objc
    private func sliderTouchCancel(_ slider: UISlider) {
        
        let index = indexOfSlider(slider)
        delegate?.onStop?(bandId: index)
        
        touched[index] = false
        
        // FIXME: 恢复touch之前的所有值?
        
        checkIfAllStopped()
    }
    
    private func checkIfAllStopped() {
        if sliders.allSatisfy({ !touched[indexOfSlider($0)] }) {
            delegate?.onAllStop?()
        }
    }
    
    // MARK: - Public API
    public var gains: [Int8] {
        return sliders.map { Int8(sliderRoundedValue($0)) }
    }
    
    public func setValue(_ value: Int8, atIndex index: Int) {
        setValue(Int(value), atIndex: index)
    }
    
    public func setValues(_ values: [Int8]) {
        let values = values.map{ Int($0) }
        setValues(values)
    }
    
    public func setValue(_ value: Int, atIndex index: Int) {
        guard value >= minValue && value <= maxValue && index < sliders.count else { return }
        
        let slider = sliders[index]
        slider.setValue(Float(value), animated: true)
        valueLabels[index].text = "\(sliderRoundedValue(slider))"
    }
    
    public func setValues(_ values: [Int]) {
        guard values.count == sliders.count else { return }
        
        for (index, value) in values.enumerated() {
            if value >= minValue && value <= maxValue {
                let slider = sliders[index]
                slider.setValue(Float(value), animated: true)
                valueLabels[index].text = "\(sliderRoundedValue(slider))"
            }
        }
    }
    
}

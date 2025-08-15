//
//  PowerUI.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/21.
//

import UIKit
import SnapKit

private let MARGIN: CGFloat = 8

extension PowerUI {
    private var containerBackgroundColor: UIColor { UIColor(white: 0.9, alpha: 1.0) }
    private var roundCornerRadius: CGFloat { 8 }
}

class PowerUI: UIView {
    
    private var leftSideImageView: UIImageView!
    private var leftSideLabel: UILabel!
    
    private var rightSideImageView: UIImageView!
    private var rightSideLabel: UILabel!
    
    private var caseImageView: UIImageView!
    private var caseLabel: UILabel!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = containerBackgroundColor
        roundCorners(radius: roundCornerRadius)
        
        // Everything is based on caseImageView
        
        let imageContainerView = UIView()
        addSubview(imageContainerView)
        
        leftSideLabel = UILabel()
        rightSideLabel = UILabel()
        caseLabel = UILabel()
        
        addSubview(leftSideLabel)
        addSubview(rightSideLabel)
        addSubview(caseLabel)
        
        
        leftBatteryLevel    = nil
        rightBatteryLevel   = nil
        caseBatteryLevel    = nil
        
        leftSideLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(0.25)
            make.bottom.equalToSuperview().offset(-MARGIN)
        }
        rightSideLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(0.75)
            make.bottom.equalToSuperview().offset(-MARGIN)
        }
        caseLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(1.5)
            make.top.equalTo(imageContainerView.snp.bottom).offset(MARGIN)
        }
        
        leftSideImageView = UIImageView()
        leftSideImageView.contentMode = .scaleAspectFit
        
        rightSideImageView = UIImageView()
        rightSideImageView.contentMode = .scaleAspectFit
        
        caseImageView = UIImageView()
        caseImageView.contentMode = .scaleAspectFit
        
        imageContainerView.addSubview(leftSideImageView)
        imageContainerView.addSubview(rightSideImageView)
        imageContainerView.addSubview(caseImageView)
        
        leftSideImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(MARGIN)
            make.right.equalTo(imageContainerView.snp.centerX).dividedBy(2).offset(-MARGIN)
            make.centerY.equalTo(caseImageView)
        }
        
        rightSideImageView.snp.makeConstraints { make in
            make.left.equalTo(imageContainerView.snp.centerX).dividedBy(2).offset(MARGIN)
            make.right.equalTo(imageContainerView.snp.centerX).offset(-MARGIN)
            make.centerY.equalTo(caseImageView)
        }
        
        caseImageView.snp.makeConstraints { make in
            make.left.equalTo(imageContainerView.snp.centerX).offset(MARGIN)
            make.right.equalToSuperview().offset(-MARGIN)
        }
        
        // MARK: Image Container View
        
        imageContainerView.snp.makeConstraints { make in
            make.height.equalTo(caseImageView).offset(MARGIN * 2)
            make.top.equalToSuperview().offset(MARGIN)
            make.left.equalToSuperview().offset(MARGIN)
            make.right.equalToSuperview().offset(-MARGIN)
        }
        
        snp.makeConstraints { make in
            make.bottom.equalTo(caseLabel).offset(MARGIN)
        }
    }
    
    // MARK: - Public API
    public var leftSideImage: UIImage? = nil {
        didSet {
            leftSideImageView.image = leftSideImage
        }
    }
    
    public var rightSideImage: UIImage? = nil {
        didSet {
            rightSideImageView.image = rightSideImage
        }
    }
    
    public var caseImage: UIImage? = nil {
        didSet {
            caseImageView.image = caseImage
        }
    }
    
    public var leftBatteryLevel: Int? = nil {
        didSet {
            if let leftBatteryLevel = leftBatteryLevel {
                leftSideLabel.text = "\(leftBatteryLevel)%"
            } else {
                leftSideLabel.text = "?"
            }
        }
    }
    
    public var rightBatteryLevel: Int? = nil {
        didSet {
            if let rightBatteryLevel = rightBatteryLevel {
                rightSideLabel.text = "\(rightBatteryLevel)%"
            } else {
                rightSideLabel.text = "?"
            }
        }
    }
    
    public var caseBatteryLevel: Int? = nil {
        didSet {
            if let caseBatteryLevel = caseBatteryLevel {
                caseLabel.text = "\(caseBatteryLevel)%"
            } else {
                caseLabel.text = "?"
            }
        }
    }
}

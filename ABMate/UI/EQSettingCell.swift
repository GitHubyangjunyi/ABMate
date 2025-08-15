//
//  EQSettingCell.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/26.
//

import UIKit
import SnapKit

class EQSettingCell: UICollectionViewCell {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private(set) var titleLabel: UILabel!
    private(set) var deleteButton: UIButton!
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var isEditing: Bool = false {
        didSet {
            deleteButton.isHidden = !isEditing
        }
    }
    
    override var isSelected: Bool {
        didSet {
            guard isEditing == false else {
                return
            }
            contentView.backgroundColor = isSelected ? .green : .green.withAlphaComponent(0.3)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .green.withAlphaComponent(0.3)
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        setupViews()
    }
    
    private func setupViews() {
        titleLabel = {
            let label = UILabel()
            contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            return label
        }()
        
        deleteButton = {
            let button = UIButton()
            button.setTitle("X", for: .normal)
            button.setTitleColor(.red, for: .normal)
            #if DEBUG
                button.backgroundColor = .gray.withAlphaComponent(0.3)
            #endif
            button.isHidden = true
            contentView.addSubview(button)
            button.snp.makeConstraints { make in
                make.top.right.equalToSuperview().inset(4)
            }
            return button
        }()
    }
}

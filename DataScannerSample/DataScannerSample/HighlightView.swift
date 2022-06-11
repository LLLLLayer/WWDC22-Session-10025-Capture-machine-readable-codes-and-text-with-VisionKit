//
//  HighlightView.swift
//  DataScannerSample
//
//  Created by Layer on 2022/6/11.
//

import UIKit

class HighlightView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.blue.withAlphaComponent(0.4)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

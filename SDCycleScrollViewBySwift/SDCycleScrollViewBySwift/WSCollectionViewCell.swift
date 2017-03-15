//
//  WSCollectionViewCell.swift
//  SDCycleScrollViewBySwift
//
//  Created by WangS on 17/3/13.
//  Copyright © 2017年 WangS. All rights reserved.
//

import UIKit

class WSCollectionViewCell: UICollectionViewCell {

    var imageView: UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
        
    }
    
    func setupImageView()  {
        let imageView = UIImageView.init()
        self.contentView.addSubview(imageView)
        self.imageView = imageView;
    }
    
    override func layoutSubviews(){
        super.layoutSubviews()
            self.imageView?.frame = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

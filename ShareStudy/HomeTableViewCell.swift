//
//  HomeTableViewCell.swift
//  ShareStudy
//
//  Created by 神林沙希 on 13/6/23.
//

import UIKit

class HomeTableViewCell: UITableViewCell {
    
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var onGoingImage: UIImageView!
    @IBOutlet var studyImage: UIImageView!
    @IBOutlet var studyTimeLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var userIdLabel: UILabel!
    @IBOutlet var postTimeLabel: UILabel!
    @IBOutlet var onGoingLabel: UILabel!
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

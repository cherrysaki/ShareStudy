//
//  HomeTableViewCell.swift
//  ShareStudy
//
//  Created by 神林沙希 on 13/6/23.
//

import UIKit

class HomeTableViewCell: UITableViewCell {
    
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var ongoingImage: UIImageView!
    @IBOutlet var studyImage: UIImageView!
    @IBOutlet var studytimeLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var useridLabel: UILabel!
    @IBOutlet var posttimeLabel: UILabel!
    @IBOutlet var ongoingLabel: UILabel!
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

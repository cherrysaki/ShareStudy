//
//  SearchTableViewCell.swift
//  ShareStudy
//
//  Created by 神林沙希 on 19/7/23.
//

import UIKit

class SearchTableViewCell: UITableViewCell {
    
    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var idLabel: UILabel!
    @IBOutlet var addButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
//        iconImage.layer.cornerRadius = 23
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}

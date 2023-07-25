//
//  SearchTableViewCell.swift
//  ShareStudy
//
//  Created by 神林沙希 on 19/7/23.
//

import UIKit
import Firebase

class SearchTableViewCell: UITableViewCell {
    
    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var idLabel: UILabel!
    @IBOutlet var addButton: UIButton!
    
    weak var delegate: FriendSearchViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        addButton.isEnabled = false
//        iconImage.layer.cornerRadius = 23
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func addButtonTapped(){
        delegate?.addFriend(cell: self)
    }
    
}

protocol FriendSearchViewDelegate: AnyObject{
    func addFriend(cell: SearchTableViewCell)
}

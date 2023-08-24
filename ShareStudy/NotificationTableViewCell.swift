//
//  NotificationTableViewCell.swift
//  ShareStudy
//
//  Created by 神林沙希 on 24/8/23.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userIdLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var approvalButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    
    weak var delegate: NotificationViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func approveButtonTapped(_ sender: UIButton) {
        delegate?.approveButtonTapped(cell: self)
        }

    
}

protocol NotificationViewDelegate: AnyObject{
    func approveButtonTapped(cell: NotificationTableViewCell)
}

//
//  HomeTableViewCell.swift
//  ShareStudy
//
//  Created by 神林沙希 on 13/6/23.
//

import UIKit

class HomeTableViewCell: UITableViewCell {
    
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var statusImageView: UIImageView!
    @IBOutlet var studyImageView: UIImageView!
    @IBOutlet var studyTimeLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var userIdLabel: UILabel!
    @IBOutlet var postTimeLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var backView: UIView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        setupIcon()
        setupPostImageView()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupPostImageView(){
        studyImageView.frame = CGRect(x: 25, y: 67, width: 280, height: 340) // サイズを指定
        studyImageView.contentMode = .scaleAspectFill
        studyImageView.clipsToBounds = true
    }
    
    func setupIcon(){
        iconImageView.layer.cornerRadius = 30
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
    }
    
    func setupLine(){
        backView.layer.borderWidth = 1.0 //枠線の太さを指定
        backView.layer.borderColor = UIColor.lightGray.cgColor //枠線の色を指定
    }
    
    func progressCheck(){
        
    }
    
    
    
}

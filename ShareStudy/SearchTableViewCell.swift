//
//  SearchTableViewCell.swift
//  ShareStudy
//
//  Created by 神林沙希 on 19/7/23.
//

import UIKit
import Firebase

class SearchTableViewCell: UITableViewCell {
    
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var idLabel: UILabel!
    @IBOutlet var friendButton: UIButton!
    
    weak var delegate: FriendSearchViewDelegate?
    
    enum ButtonState {
        case requestSent
        case isFriend
        case addFriend
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        friendButton.isEnabled = false
        iconImageView.layer.cornerRadius = 30
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func addButtonTapped(){
        delegate?.addFriend(cell: self)
    }
    
    // ボタンの状態を設定するメソッド
       func setButtonState(_ state: ButtonState) {
           switch state {
           case .requestSent:
               // フレンド申請が送信された状態の処理
               friendButton.setTitle("申請中", for: .normal)
               friendButton.isEnabled = false
           case .isFriend:
               // フレンド関係が成立した状態の処理
               friendButton.isHidden = true
               friendButton.isEnabled = false
           case .addFriend:
               // フレンド申請を送ることができる状態の処理
               friendButton.setTitle("友達申請", for: .normal)
               friendButton.isEnabled = true
           }
       }
}

protocol FriendSearchViewDelegate: AnyObject{
    func addFriend(cell: SearchTableViewCell)
}


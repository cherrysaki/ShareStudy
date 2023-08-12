//
//  ProfileViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 23/5/23.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {

    @IBOutlet var userNameLabel:UILabel!
    @IBOutlet var userIdlabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchMyProfile()
    }
    
   

    func fetchMyProfile(){
        // ログインしているユーザーのUIDを取得
        if let currentUserID = Auth.auth().currentUser?.uid {
            // ユーザーのドキュメント参照を作成
            let userDocRef = db.collection("user").document(currentUserID)
            
            // ユーザーのデータを取得
            userDocRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    // ドキュメントが存在する場合、データを取得
                    if let data = document.data(),
                       let userName = data["userName"] as? String,
                       let userId = data["userId"] as? String,
                       let iconImageURL = URL(string: data["profileImageName"] as! String){
                        print("名前: \(userName)")
                        print("id: \(userId)")
                        
                        self.userNameLabel.text = userName
                        self.userIdlabel.text = userId
                        
                        let iconData = NSData(contentsOf: iconImageURL)
                        let iconImage = UIImage(data: iconData! as Data)!
                        self.iconImageView.image = iconImage
                        
                    }
                } else {
                    print("ユーザーのドキュメントが存在しないかエラーが発生しました")
                }
            }
        }
        
    }

}

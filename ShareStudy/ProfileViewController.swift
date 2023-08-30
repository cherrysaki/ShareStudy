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
    @IBOutlet var introLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        introLabel.contentMode = .top

    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchMyProfile()
        fetchMyStudy()
        
    }
    
    
    
    func fetchMyProfile(){
//        let loadingView = createLoadingView()
//        UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.addSubview(loadingView)
//
        // ログインしているユーザーのUIDを取得
        if let currentUserID = Auth.auth().currentUser?.uid {
            // ユーザーのドキュメント参照を作成
            let userDocRef = db.collection("user").document(currentUserID).collection("profile")
            
            // ユーザーのデータを取得
            userDocRef.getDocuments { (querySnapshot, error) in
//                loadingView.removeFromSuperview() // まずローディングビューを非表示に
                if let error = error {
                    print("データ取得エラー: \(error.localizedDescription)")
                    return
                }
                
                if let documents = querySnapshot?.documents{
                    for document in documents {
                        let data = document.data()
                        if let userName = data["userName"] as? String{
                           let userId = data["userID"] as? String
                           let introduction = data["selfIntroduction"] as?String
                            print("名前: \(userName)")
                            
                            self.userNameLabel.text = userName
                            self.userIdlabel.text = userId
                            self.introLabel.text = introduction
                            DispatchQueue.global().async {
                                if let iconImageURL = URL(string: data["profileImageName"] as! String),
                                   let iconImageData = try? Data(contentsOf: iconImageURL),
                                   let iconImage = UIImage(data: iconImageData) {
                                    DispatchQueue.main.async {
                                        self.iconImageView.image = iconImage
                                    }
                                } else {
                                    self.showAlert(message: "アイコン画像の読み込みに失敗しました")
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
        func fetchMyStudy(){
            // ログインしているユーザーのUIDを取得
            if let currentUserID = Auth.auth().currentUser?.uid {
                // ユーザーのドキュメント参照を作成
                let userDocRef = db.collection("user").document(currentUserID).collection("study")
    
                // ユーザーのデータを取得
                userDocRef.getDocuments { (querySnapshot, error) in
                    if let error = error {
                        self.showAlert(message: "データ取得エラー: \(error.localizedDescription)")
                                    return
                                }
    
                    if let documents = querySnapshot?.documents{
                        for document in documents {
                            let data = document.data()
                            if let userName = data["userName"] as? String,
                               let userId = data["userID"] as? String,
                               let introduction = data["selfIntroduction"] as?String,
                               let iconImageURL = URL(string: data["profileImageName"] as! String){
                                print("名前: \(userName)")
                                print("id: \(userId)")
    
                                self.userNameLabel.text = userName
                                self.userIdlabel.text = userId
                                self.introLabel.text = introduction
                                let iconData = NSData(contentsOf: iconImageURL)
                                let iconImage = UIImage(data: iconData! as Data)!
                                self.iconImageView.image = iconImage
    
    
                            }
                        }
                    }
                    }
                }
    
        }
    
    func showAlert(message: String) {
            let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    
    func showCreateStudyAlert() {
        let alert = UIAlertController(
            title: "勉強記録が存在しません",
            message: "新しい勉強記録を作成しますか？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "はい", style: .default) { _ in
            // 新しい勉強記録を作成する処理をここに追加する
        })
        
        alert.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}






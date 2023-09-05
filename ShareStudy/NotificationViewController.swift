//
//  NotificationViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 19/7/23.
//

import UIKit
import Firebase

class NotificationViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,NotificationViewDelegate{
    
    @IBOutlet var tableView: UITableView!
    var friendRequests: [Profile] = [] // 申請された友達のプロフィール情報を格納する配列
    var friendRequestsUid: [String] = [] //申請された友達のユニークなIDを格納する配列
    private let imageCache = NSCache<NSString, UIImage>()  // 画像をキャッシュするためのNSCache
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "NotificationTableViewCell", bundle: nil), forCellReuseIdentifier: "friendRequestCell")
        
        fetchFriendRequests() // 申請された友達のプロフィール情報を取得
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendRequestCell", for: indexPath) as! NotificationTableViewCell
        cell.delegate = self
        let friendRequest = friendRequests[indexPath.row]
        cell.userNameLabel.text = friendRequest.userName
        cell.userIdLabel.text = friendRequest.userID
        
        // キャッシュに画像が存在する場合はそれを使用
           if let cachedImage = imageCache.object(forKey: friendRequest.profileImage as NSString) {
               cell.iconImageView.image = cachedImage
           } else {
               // キャッシュに画像が存在しない場合、非同期でダウンロード
               DispatchQueue.global().async {
                   if let iconImageURL = URL(string: friendRequest.profileImage),
                      let iconImageData = try? Data(contentsOf: iconImageURL),
                      let iconImage = UIImage(data: iconImageData) {
                       // ダウンロードした画像をキャッシュに保存
                       self.imageCache.setObject(iconImage, forKey: friendRequest.profileImage as NSString)
                       
                       DispatchQueue.main.async {
                           // メインスレッドでUIの更新を行う
                           cell.iconImageView.image = iconImage
                       }
                   }
               }
           }
        
        return cell
    }
    
    // 申請された友達のプロフィール情報を取得して表示するメソッド
    func fetchFriendRequests() {
        friendRequests = []
        friendRequestsUid = []
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        
        // 自分のwaitfollowerコレクションを取得
        let currentUserWaitFollowerCollection = db.collection("user").document(currentUserID).collection("waitfollower")
        
        currentUserWaitFollowerCollection.order(by: "timestamp", descending: true).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching friend requests: \(error.localizedDescription)")
                return
            }
            // 申請されたユーザーIDのプロフィール情報を取得してfriendRequestsに格納
            for document in snapshot?.documents ?? [] {
                let data = document.data()
                if let userID = data["waitFollowerUser"] as? String{
                    self.friendRequestsUid.append(userID)
                    let profileCollection = db.collection("user").document(userID).collection("profile")
                    profileCollection.getDocuments { (profileSnapshot, profileError) in
                        if let profileError = profileError {
                            print("Error fetching profile for user \(userID): \(profileError.localizedDescription)")
                            return
                        }
                        
                        if let profileDocument = profileSnapshot?.documents.first,
                           let userName = profileDocument["userName"] as? String,
                           let userID = profileDocument["userID"] as? String,
                           let profileImage = profileDocument["profileImageName"] as? String {
                            let profile = Profile(userName: userName, userID: userID, profileImage: profileImage)
                            self.friendRequests.append(profile)
                            print(self.friendRequests)
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    // NotificationTableViewCellDelegate メソッドの実装
    func approveButtonTapped(cell: NotificationTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let friendRequestUid = friendRequestsUid[indexPath.row]
        approveFriendRequest(targetUserID: friendRequestUid)
    }
    
    func approveFriendRequest(targetUserID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        
        let batch = db.batch()
        
        let currentUserWaitFollowerRef = db.collection("user").document(currentUserID).collection("waitfollower").document(targetUserID)
        let currentUserFriendRef = db.collection("user").document(currentUserID).collection("friends").document(targetUserID)
        let targetUserFriendRef = db.collection("user").document(targetUserID).collection("friends").document(currentUserID)
        let targetUserWaitFollowRef = db.collection("user").document(targetUserID).collection("waitfollow").document(currentUserID)
        
        // トランザクション内でデータの更新を行う
        batch.deleteDocument(currentUserWaitFollowerRef)
        batch.setData(["friendUser": targetUserID, "timestamp": FieldValue.serverTimestamp()], forDocument: currentUserFriendRef)
        batch.setData(["friendUser": currentUserID, "timestamp": FieldValue.serverTimestamp()], forDocument: targetUserFriendRef)
        batch.deleteDocument(targetUserWaitFollowRef) // 相手のwaitfollowリストから自分のユーザーIDを削除
        
        // トランザクションの実行
        batch.commit { (error) in
            if let error = error {
                print("友達承認中にエラーが発生しました: \(error.localizedDescription)")
                // ユーザーフレンドリーなエラーメッセージを表示するなどの処理を追加することができます
            } else {
                print("友達追加に成功しました")
                // 友達承認が成功した場合の処理を追加することができます
            }
        }
    }
    
    func cancelButtonTapped(cell: NotificationTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let friendRequestUid = friendRequestsUid[indexPath.row]
        cancelFriendRequest(targetUserID: friendRequestUid)
    }
    
    func cancelFriendRequest(targetUserID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        let currentUserWaitFollowerRef = db.collection("user").document(currentUserID).collection("waitfollower").document(targetUserID)
        let targetUserWaitFollowRef = db.collection("user").document(targetUserID).collection("waitfollow").document(currentUserID)
        
        // ドキュメントを削除する関数
        func deleteDocument(_ documentRef: DocumentReference) {
            documentRef.delete { error in
                if let error = error {
                    print("ドキュメントの削除エラー: \(error.localizedDescription)")
                } else {
                    print("ドキュメントが削除されました。")
                }
            }
        }
        
        // ドキュメントを削除
        deleteDocument(currentUserWaitFollowerRef)
        deleteDocument(targetUserWaitFollowRef)
    }

    
    
}

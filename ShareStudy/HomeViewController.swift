//
//  HomeViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 3/2/23.
//

import UIKit
import Firebase

struct StudyPost{
    let studyTime: String
    let studyImage: String
    let isFinished: Bool
    let onGoing: Bool
}

class HomeViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet var tableView:UITableView!
    @IBOutlet var iconBarItem: UIBarItem!
    
    var profilesArray:[Profile] = []
    var postArray:[StudyPost]  = []
    
    var data: Dictionary<String, Any> = [:]
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: "postCell")
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        fetchMyProfile()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //        return postTimeArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! HomeTableViewCell
        
        //        cell.nameLabel.text = nameArray[indexPath.row]
        //        cell.userIdLabel.text = userIdArray[indexPath.row]
        //        cell.postTimeLabel.text = postTimeArray[indexPath.row]
        //        cell.studyTimeLabel.text = studyTimeArray[indexPath.row]
        //        cell.studyImageView.image = studyImageArray[indexPath.row]
        //        cell.iconImageView.image = iconImageArray[indexPath.row]
        
        return cell
    }
    
//    //①自分のプロフィールのデータを取ってくる
//    func fetchMyProfile(){
//        if let currentUserID = Auth.auth().currentUser?.uid {
//            db.collection("user").document(currentUserID).collection("profile").getDocuments { (querySnapshot, error) in
//                if let error = error {
//                    print("データ取得エラー: \(error.localizedDescription)")
//                    return
//                }
//                if let documents = querySnapshot?.documents {
//                    for document in documents {
//                        let data = document.data()
//                        if let name = data["userName"] as? String,
//                           let userID = data["userID"] as? String,
//                           let iconImageURL = data["profileImageName"] as? String
//                        {
//                            let profile = Profile(userName: name, userID: userID, profileImage: iconImageURL)
//                            self.profilesArray.append(profile)
//                            //iconBarItemにアイコンをダウンロードする
//                        }
//                    }
//
//                }
//            }
//        }
//    }
//
//    //②自分の投稿を取ってくる
//    func fetchMyStudy(){
//        if let currentUserID = Auth.auth().currentUser?.uid {
//            db.collection("user").document(currentUserID).collection("study").getDocuments { (querySnapshot, error) in
//                if let error = error {
//                    print("データ取得エラー: \(error.localizedDescription)")
//                    return
//                }
//                if let documents = querySnapshot?.documents {
//                    for document in documents {
//                        let data = document.data()
//                        if let studyTime = data["studyTime"] as? String,
//                           let studyImageURL = data["image"] as? String,
//                           let isFinished = data["isFinished"] as? Bool,
//                           let onGoing = data["onGoing"] as? Bool,
//                           let postTime = data["date"] as? Timestamp
//                        {
//                            let formattedTime = self.formatPostTime(postTime)
//                            let post = StudyPost(studyTime: studyTime, studyImage: studyImageURL, isFinished: isFinished, onGoing: onGoing)
//                            self.postArray.append(post)
//                        }
//                    }
//                }
//                //                // データ取得後にTableViewをリロード
//                //                self.tableView.reloadData()
//            }
//        }
//    }
    
   // ③friendのデータを取ってくる
    func fetchUserProfile(userID: String) {
        db.collection("user").document(userID).collection("profile").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                return
            }
            if let documents = querySnapshot?.documents {
                for document in documents {
                    let data = document.data()
                    if let name = data["userName"] as? String,
                       let userID = data["userID"] as? String,
                       let iconImageURL = data["profileImageName"] as? String
                    {
                        let profile = Profile(userName: name, userID: userID, profileImage: iconImageURL)
                        self.profilesArray.append(profile)
                        // iconBarItemにアイコンをダウンロードする
                    }
                }
            }
        }
    }

    // 他のユーザーの投稿を取ってくる
    func fetchUserStudy(userID: String) {
        db.collection("user").document(userID).collection("study").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                return
            }
            if let documents = querySnapshot?.documents {
                for document in documents {
                    let data = document.data()
                    if let studyTime = data["studyTime"] as? String,
                       let studyImageURL = data["image"] as? String,
                       let isFinished = data["isFinished"] as? Bool,
                       let onGoing = data["onGoing"] as? Bool,
                       let postTime = data["date"] as? Timestamp
                    {
                        let formattedTime = self.formatPostTime(postTime)
                        let post = StudyPost(studyTime: studyTime, studyImage: studyImageURL, isFinished: isFinished, onGoing: onGoing)
                        self.postArray.append(post)
                    }
                }
            }
            // TableViewをリロード
            self.tableView.reloadData()
        }
    }

    
    //  firebaseのfriendコレクションから友達のユーザーIDを取得して、実際にデータをとる
    func fetchFriendUserIDs() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        //自分のデータを取ってくる
        fetchUserProfile(userID: currentUserID)
        fetchUserStudy(userID: currentUserID)
        
        db.collection("user").document(currentUserID).collection("friends").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                return
            }
            if let documents = querySnapshot?.documents {
                let friendUserIDs = documents.compactMap { $0.documentID }
                // 友達のユーザーIDを取得したので、それを使って関数を呼び出す
                for friendUserID in friendUserIDs {
                    self.fetchUserProfile(userID: friendUserID)
                    self.fetchUserStudy(userID: friendUserID)
                }
            }
        }
    }

    //dateをstringに変える関数
    func formatPostTime(_ postTime: Timestamp) -> String {
        let dates: Date = postTime.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm" // 日付と時刻のフォーマットを指定
        return dateFormatter.string(from: dates)
    }
    
    // 画像を非同期でダウンロードする関数
    func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("画像ダウンロードエラー: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    
    
    
    
    
    
}

//
//  HomeViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 3/2/23.
//

import UIKit
import Firebase

struct StudyPost{
    let postTime: Date
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
        fetchAllUsersData()
        
    }
    
    
    // TableViewDataSourceのメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! HomeTableViewCell
        let post = postArray[indexPath.row]
        
        // セルにデータを表示
        cell.studyTimeLabel.text = post.studyTime
        // isFinishedやonGoingに応じてセルの表示を設定
        
        
        
        // プロフィール情報の表示
//        if let profile = profilesArray.first(where: { $0.userID == post.userID }) {
//            cell.nameLabel.text = profile.userName
//            cell.userIdLabel.text = profile.userID
//            // アイコン画像を非同期でダウンロードして表示
//            // 画像をダウンロードして表示する
//            downloadImage(from: profile.profileImage) { image in
//                if let downloadedImage = image {
//                    // ダウンロードした画像を使って何か処理を行う（ここではUIImageViewに設定）
//                    cell.iconImageView.image = downloadedImage
//                } else {
//                    // ダウンロードに失敗した場合の処理
//                    print("画像のダウンロードに失敗しました")
//                }
//            }
//
            return cell
        }
        
         // プロフィールデータを取ってくる
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
        
        // 投稿を取ってくる
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
//                            let formattedTime = self.formatPostTime(postTime)これはcellに表示するときに変換する
                            let postDates: Date = postTime.dateValue()
                            let post = StudyPost(postTime: postDates, studyTime: studyTime, studyImage: studyImageURL, isFinished: isFinished, onGoing: onGoing)
                            self.postArray.append(post)
                        }
                    }
                }
                // TableViewをリロード
                self.tableView.reloadData()
            }
        }
        
        
        //  firebaseのfriendコレクションから友達のユーザーIDを取得して、実際にデータをとる
    func fetchAllUsersData() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }

        let group = DispatchGroup() // DispatchGroupを作成

        // 自分のデータを取得して表示
        fetchUserProfile(userID: currentUserID)
        fetchUserStudy(userID: currentUserID)
        

        db.collection("user").document(currentUserID).collection("friends").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                return
            }
            if let documents = querySnapshot?.documents {
                let friendUserIDs = documents.compactMap { $0.documentID }
                
                group.enter() // グループに非同期処理が開始されたことを通知
                for friendUserID in friendUserIDs {
                    self.fetchUserProfile(userID: friendUserID)
                    self.fetchUserStudy(userID: friendUserID)
                }
                group.leave() // 非同期処理が完了したことを通知
            }
        }

        // すべての非同期処理が完了するまで待つ
        group.notify(queue: .main) {
            // すべてのデータ取得が完了したのでUIを更新する
            self.tableView.reloadData()
        }
    }
    
  
    // 投稿データをソートする関数
    func sortPostArray() {
        postArray.sort { (post1, post2) -> Bool in
            return post1.postTime < post2.postTime
        }
    }

    
//    // プロフィールデータをソートする関数
//    func sortProfilesArray() {
//        var sortedProfilesArray: [Profile] = []
//        for post in postArray {
//            if let profile = profilesArray.first(where: { $0.userID == post.userID }) {
//                sortedProfilesArray.append(profile)
//            }
//        }
//        profilesArray = sortedProfilesArray
//    }

        
        //dateをstringに変える関数
        func formatPostTime(_ postDates: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ja_JP")
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm" // 日付と時刻のフォーマットを指定
            return dateFormatter.string(from: postDates)
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


//
//  HomeViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 3/2/23.
//

import UIKit
import Firebase

struct StudyPost{
    let uid: String
    let postTime: Date
    let studyTime: Int
    let studyImage: String
    let isFinished: Bool
    let onGoing: Bool
}

class HomeViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var iconBarItem: UIBarItem!
    
    var profilesArray:[Profile] = []{
        didSet {
            tableView?.reloadData()
        }
    }
    var postArray:[StudyPost]  = []{
        didSet {
            tableView?.reloadData()
        }
    }
    
    var data: Dictionary<String, Any> = [:]
    
    let db = Firestore.firestore()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: "postCell")
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        fetchAllUsersData()
        print(postArray)
    }
    
    
    // TableViewDataSourceのメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 500
        }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! HomeTableViewCell
        let post = postArray[indexPath.row]
        let profile = profilesArray[indexPath.row]
        
        // セルにデータを表示
//        cell.studyTimeLabel.text = post.studyTime
        cell.nameLabel.text = profile.userName
        cell.userIdLabel.text = profile.userID
        let formattedTime = self.formatPostTime(post.postTime)
        cell.postTimeLabel.text = formattedTime
        
        //画像の表示
        let postImageURLString = post.studyImage
        let profileImageURLString = profile.profileImage
        
        // 画像のダウンロード
        downloadImage(from: postImageURLString) { image in
            self.setImage(image, for: cell.studyImageView)
        }
        
        downloadImage(from: profileImageURLString) { image in
            self.setImage(image, for: cell.iconImageView)
        }
        
        return cell
        
    }
    
//    //    ①自分のプロフィールのデータを取ってくる
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
//                        if let iconImageURL = data["profileImageName"] as? String
//                        {
//                            self.setupIconBarItem(iconImageURL: iconImageURL)
//                        }
//
//                    }
//                }
//            }
//        }
//    }
    
    // studyデータを取ってきて、posttimeによってsortする
    func fetchUserStudy(userID: String) {
        db.collection("user").document(userID).collection("study").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                return
            }
            if let documents = querySnapshot?.documents {
                print(documents)
                for document in documents {
                    let data = document.data()
                    if let uid = data["userUid"] as? String,
                       let studyTime = data["studyTime"] as? Int,
                       let studyImageURL = data["image"] as? String,
                       let isFinished = data["isFinished"] as? Bool,
                       let onGoing = data["onGoing"] as? Bool,
                       let postTime = data["date"] as? Timestamp
                    {
                        let postDates: Date = postTime.dateValue()
                        let post = StudyPost(uid: uid, postTime: postDates, studyTime: studyTime, studyImage: studyImageURL, isFinished: isFinished, onGoing: onGoing)
                        self.postArray.append(post)
                        print("今の",self.postArray)
                    }
                }
            }
        }
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
                        print(userID)
                        let profile = Profile(userName: name, userID: userID, profileImage: iconImageURL)
                        self.profilesArray.append(profile)
                    }
                }
            }
        }
    }
    
    //  firebaseのfriendコレクションから友達のユーザーIDを取得して、実際にデータをとる
    func fetchAllUsersData() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        // 自分のデータを取得
        fetchUserStudy(userID: currentUserID)
        print("自分のデータを取った")
        //友達のデータを取得
        db.collection("user").document(currentUserID).collection("friends").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                return
            }
            if let documents = querySnapshot?.documents {
                let friendUserIDs = documents.compactMap { $0.documentID }
                for friendUserID in friendUserIDs {
                    self.fetchUserStudy(userID: friendUserID)
                }
            }
        }
        print("友達取得後",postArray)
        // すべてのデータ取得が完了したのでsortを行う
        self.sortPostArray()
        print("sort後",postArray)
        //sortが行われた後、postArray.uidを使ってfetchUserProfileを行う
        for post in postArray {
            print(post)
            fetchUserProfile(userID: post.uid)
        }
        print(profilesArray)
        //全てのデータが揃ったらtableViewを更新する
        self.tableView.reloadData()
    }
    
    
    // 投稿データをソートする関数
    func sortPostArray() {
        postArray.sort { (post1, post2) -> Bool in
            return post1.postTime > post2.postTime
        }
        print("sortなう")
    }
    
    
    
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
    
    // ダウンロードした画像をセルに設定する関数
    func setImage(_ image: UIImage?, for imageView: UIImageView) {
        DispatchQueue.main.async {
            imageView.image = image
        }
    }
    
    func setupIconBarItem(iconImageURL: String){
        downloadImage(from: iconImageURL) { image in
            if let downloadedImage = image {
                // 画像がダウンロードされたら、それを使ってBarItemに設定
                self.iconBarItem.image = downloadedImage
            } else {
                self.iconBarItem.image = UIImage(named: "icon")
                print("画像のダウンロードに失敗しました")
            }
        }
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


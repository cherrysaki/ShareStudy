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
    
    var profilesArray:[Profile] = []
    var postArray:[StudyPost]  = []
    
    var data: Dictionary<String, Any> = [:]
    
    let db = Firestore.firestore()
    let dispatchGroup = DispatchGroup()
    let newSize = CGSize(width: 30, height: 30)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: "postCell")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
         profilesArray = []
         postArray = []
        print("viewWillAppear")
        fetchMyIcon()
        fetchAllUsersData()
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
        cell.nameLabel.text = profile.userName
        cell.userIdLabel.text = profile.userID
        let formattedTime = self.formatPostTime(post.postTime)
        cell.postTimeLabel.text = formattedTime
        let studyTime = self.timerUIUpdate(time: post.studyTime)
        cell.studyTimeLabel.text = studyTime
        
        //達成状況の表示
        
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
    

    
    // studyデータを取ってきて、posttimeによってsortする
    func fetchUserStudy(userID: String) {
        db.collection("user").document(userID).collection("study").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                self.dispatchGroup.leave()
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
    
    func fetchUserProfile(userID: String, completion: @escaping (Profile?) -> Void) {
        db.collection("user").document(userID).collection("profile").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                completion(nil)
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
                        completion(profile)
                    }
                }
            }
            completion(nil)
        }
    }
    
    func fetchMyIcon(){
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        db.collection("user").document(currentUserID).collection("profile").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                return
            }
            if let documents = querySnapshot?.documents {
                for document in documents {
                    let data = document.data()
                    if let iconImageURL = data["profileImageName"] as? String
                    {
                        print(iconImageURL)
                        self.setupIconBarItem(iconImageURL: iconImageURL, newSize: self.newSize)
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
        
        self.dispatchGroup.enter()
        // 自分のデータを取得
        fetchUserStudy(userID: currentUserID)
        
        // 友達のデータを取得
        db.collection("user").document(currentUserID).collection("friends").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                self.dispatchGroup.leave()
                return
            }
            if let documents = querySnapshot?.documents {
                let friendUserIDs = documents.compactMap { $0.documentID }
                for friendUserID in friendUserIDs {
                    self.fetchUserStudy(userID: friendUserID)
                }
                self.dispatchGroup.leave()
            }
        }

        self.dispatchGroup.notify(queue: .main) {
            print("友達取得後", self.postArray)
            self.sortPostArray()
            
            // プロフィールデータを取得してprofilesArrayに追加
            self.dispatchGroup.enter()
            var completedProfileCount = 0
            
            for post in self.postArray {
                self.fetchUserProfile(userID: post.uid) { profile in
                    if let profile = profile {
                        self.profilesArray.append(profile)
                    }
                    
                    completedProfileCount += 1
                    if completedProfileCount == self.postArray.count {
                        self.dispatchGroup.leave()
                    }
                }
            }
            
            // プロフィールデータの取得が完了したらtableViewを更新
            self.dispatchGroup.notify(queue: .main) {
                print("全てのデータが揃いました")
                self.tableView.reloadData()
            }
        }
    }
    
    
    // 投稿データをソートする関数
    func sortPostArray() {
        postArray.sort { (post1, post2) -> Bool in
            return post1.postTime > post2.postTime
        }
    }
    
    
    
    //dateをstringに変える関数
    func formatPostTime(_ postDates: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "MM/dd HH:mm" // 日付と時刻のフォーマットを指定
        return dateFormatter.string(from: postDates)
    }
    
    //studyTimeをstringに変える関数
    func timerUIUpdate(time: Int) -> String {
        let hours = Int(time / 3600)
        let resthours = Int(time) % 3600
        let minutes = Int(resthours / 60)
        if hours > 0 {
            return String(format: "%2d時間%2d分", hours, minutes)
        } else {
            return String(format: "%2d分", minutes)
        }
    }
    
    func progressCheck(){
        
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
    func setupIconBarItem(iconImageURL: String, newSize: CGSize) {
        downloadImage(from: iconImageURL) { [weak self] image in
            DispatchQueue.main.async {
                if let originalImage = image {
                    // 画像を指定されたサイズにリサイズ
                    let resizedImage = originalImage.resize(to: newSize)
                    
                    // 画像を丸くクリップする
                    if let clippedImage = resizedImage.circularImage() {
                        // 画像の色空間を sRGB に変更して再設定
                        let srgbImage = clippedImage.withRenderingMode(.alwaysOriginal)
                        self?.iconBarItem.image = srgbImage
                    }
                    
                    print("アイコンが設定されました")
                } else {
                    self?.iconBarItem.image = UIImage(named: "icon")
                    print("画像のダウンロードに失敗しました")
                }
            }
        }
    }
    
    
}

extension UIImage {
    func resize(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension UIImage {
    func circularImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
        context.addPath(path.cgPath)
        context.clip()
        draw(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
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


//
//  ProfileViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 23/5/23.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    
    @IBOutlet var userNameLabel:UILabel!
    @IBOutlet var userIdlabel: UILabel!
    @IBOutlet var introLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var tableView: UITableView!
    
    let db = Firestore.firestore()
    
    var postArray:[StudyPost]  = []

    var userName: String = "さき"
    var userID: String = "saki0402"
    var profileImage: String = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        fetchMyProfile()
        fetchMystudy()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 500
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! HomeTableViewCell
        let post = postArray[indexPath.row]
        
//        let loadingView = createLoadingView()
//        UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.addSubview(loadingView)
//
        let formattedTime = self.formatPostTime(post.postTime)
        cell.postTimeLabel.text = formattedTime
        let studyTime = self.timerUIUpdate(time: post.studyTime)
        cell.studyTimeLabel.text = studyTime
        setStatusForCell(cell, isFinished: post.isFinished, onGoing: post.onGoing)

        cell.nameLabel.text = self.userName
        cell.userIdLabel.text = self.userID
        
        let postImageURLString = post.studyImage
        downloadImage(from: postImageURLString) { image in
            self.setImage(image, for: cell.studyImageView)
        }
        
        downloadImage(from: self.profileImage) { image in
            self.setImage(image, for: cell.iconImageView)
        }
//        loadingView.removeFromSuperview()
        return cell
       
    }
    
    
    
    func fetchMyProfile(){
        if let currentUserID = Auth.auth().currentUser?.uid {
            let userDocRef = db.collection("user").document(currentUserID).collection("profile")
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
                           let introduction = data["selfIntroduction"] as? String,
                           let profileImageName = data["profileImageName"] as? String{
                            print("名前: \(userName)")
                            self.userNameLabel.text = userName
                            self.userIdlabel.text = userId
                            self.introLabel.text = introduction
                           
                            self.userName = userName
                            self.userID = userId
                            self.profileImage = profileImageName
                            
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
    
    func fetchMystudy() {
        if let currentUserID = Auth.auth().currentUser?.uid {
            let userDocRef = db.collection("user").document(currentUserID).collection("study")
            userDocRef.getDocuments { (querySnapshot, error) in
                if let error = error {
                    self.showAlert(message: "データ取得エラー: \(error.localizedDescription)")
                    return
                }
                
                if let documents = querySnapshot?.documents {
                    var fetchedPosts = [StudyPost]() // 取得したデータを一時的に格納する配列
                    
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
                            let post = StudyPost(uid: uid, postTime: postDates, studyTime: Int(studyTime), studyImage: studyImageURL, isFinished: isFinished, onGoing: onGoing)
                            fetchedPosts.append(post)
                        }
                    }
                    
                    // データ取得が完了した後に配列を更新し、tableViewをリロードする
                    self.postArray = fetchedPosts
                    self.tableView.reloadData()
                    
                    print("今の", self.postArray)
                }
            }
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
    
    func setStatusForCell(_ cell: HomeTableViewCell, isFinished: Bool, onGoing: Bool) {
        if !isFinished && !onGoing {
            // 未達成の場合
            cell.statusImageView.image = UIImage(named: "未達成") // 未達成のイメージ
            cell.statusLabel.text = "未達成"
        } else if !isFinished && onGoing {
            // 進行中の場合
            cell.statusImageView.image = UIImage(named: "進行中") // 進行中のイメージ
            cell.statusLabel.text = "進行中"
        } else {
            // 達成済の場合
            cell.statusImageView.image = UIImage(named: "達成") // 達成済のイメージ
            cell.statusLabel.text = "達成済"
        }
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
    
    func setupUI(){
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        //        introLabel.contentMode = .top
    }
    
    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: "postCell")
    }
    
    func createLoadingView() -> UIView {
        //Loading View
        let loadingView = UIView(frame: UIScreen.main.bounds)
        loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        activityIndicator.center = loadingView.center
        activityIndicator.color = UIColor.white
        activityIndicator.style = UIActivityIndicatorView.Style.large
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        loadingView.addSubview(activityIndicator)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 30))
        label.center = CGPoint(x: activityIndicator.frame.origin.x + activityIndicator.frame.size.width / 2, y: activityIndicator.frame.origin.y + 90)
        label.textColor = UIColor.white
        label.textAlignment = .center
        loadingView.addSubview(label)
        
        return loadingView
    }
    
    
}






//
//  FriendSearchViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 19/7/23.
//

import UIKit
import Firebase

// フレンド申請の状態を表す列挙型
enum FriendRequestStatus {
    case requestSent
    case isFriend
    case none
}

struct Profile {
    let userName: String
    let userID: String
    let profileImage: String
}

class FriendSearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, FriendSearchViewDelegate {
    
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    var searchHistory: [String] = []
    var searchResults: [Profile] = [] // 検索結果を格納するための配列
    var keyword: String = ""
    var uid: String = ""
    var status: FriendRequestStatus = .none
    let db = Firestore.firestore()
    let imageCache = NSCache<NSString, UIImage>()
    let dispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        searchHistory = getSearchHistory()// 保存された検索履歴を読み出す
        tableView.reloadData()
    }
    
    // UserDefaultsに検索履歴を保存
    func saveSearchKeyword(keyword: String) {
        // 既存の履歴に追加
        searchHistory.append(keyword)
        // 重複を削除して保存
        let uniqueHistory = Array(Set(searchHistory))
        UserDefaults.standard.set(uniqueHistory, forKey: "SearchHistory")
    }
    
    // UserDefaultsから検索履歴を取得
    func getSearchHistory() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "SearchHistory") ?? []
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return searchResults.count
        }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80
        }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as! SearchTableViewCell
            let profile = searchResults[indexPath.row]
            cell.nameLabel.text = profile.userName
            cell.idLabel.text = profile.userID
            // ダウンロードが失敗した場合はキャッシュから取得
            if let cachedImage = imageCache.object(forKey: profile.profileImage as NSString) {
                cell.iconImageView.image = cachedImage
            } else {
                // ダウンロードが失敗した場合にはデフォルトの画像を表示する
                cell.iconImageView.image = UIImage(named: "icon")
                downloadIcons(for: cell, with: profile)
            }  // プロフィール画像のダウンロードを行う
            cell.delegate = self
            configureButton(for: cell, with: profile) // ボタンの処理を設定
            
            return cell
    }
    
    func downloadIcons(for cell: SearchTableViewCell, with profile: Profile) {
        // キャッシュに画像が存在する場合はそれを使用
        if let cachedImage = imageCache.object(forKey: profile.profileImage as NSString) {
            cell.iconImageView.image = cachedImage
        } else {
            DispatchQueue.global().async {
                if let iconImageURL = URL(string: profile.profileImage),
                   let iconImageData = try? Data(contentsOf: iconImageURL),
                   let iconImage = UIImage(data: iconImageData) {
                    // ダウンロードした画像をキャッシュに保存
                    self.imageCache.setObject(iconImage, forKey: profile.profileImage as NSString)
                    
                    DispatchQueue.main.async {
                        // メインスレッドでUIの更新を行う
                        cell.iconImageView.image = iconImage
                    }
                }
            }
        }
    }
    
    func fetchSearchResults(keyword: String, completion: @escaping (Bool) -> Void) {
            let usersCollection = Firestore.firestore().collection("user")
            
            usersCollection.getDocuments { [weak self] (usersSnapshot, error) in
                if let error = error {
                    print("クエリ実行中にエラーが発生しました: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                self?.searchResults = []

                for userDocument in usersSnapshot!.documents {
                    self?.dispatchGroup.enter()
                    self?.fetchProfile(for: userDocument, keyword: keyword)
                }
                self?.dispatchGroup.notify(queue: .main) {
                    self?.tableView.reloadData()
                    if self?.searchResults.isEmpty ?? true {
                        print("一致するプロフィールが見つかりません")
                        self?.createAlert(title: "検索結果なし", message: "一致するものがありませんでした")
                    }
                    completion(true)
                }
            }
        }

        func fetchProfile(for userDocument: QueryDocumentSnapshot, keyword: String) {
            let profileCollection = userDocument.reference.collection("profile")
            let query = profileCollection.whereField("userID", isEqualTo: keyword)
            
            query.getDocuments { [weak self] (profileSnapshot, error) in
                if let error = error {
                    print("クエリ実行中にエラーが発生しました: \(error.localizedDescription)")
                    self?.dispatchGroup.leave()
                    return
                }
                
                guard let profileDocuments = profileSnapshot?.documents, !profileDocuments.isEmpty else {
                    self?.dispatchGroup.leave()
                    return
                }
                
                for profileDocument in profileDocuments {
                    let data = profileDocument.data()
                    if let name = data["userName"] as? String,
                       let id = data["userID"] as? String,
                       let imageUrl = data["profileImageName"] as? String {
                        let profile = Profile(userName: name, userID: id, profileImage: imageUrl)
                        self?.searchResults.append(profile)
                        //こっちでdocumenIDも取得したい。
                        guard let doc = profileSnapshot?.documents.first else {
                            print("エラー")
                            return
                            }
                        self?.uid = doc.documentID
                        print(self?.uid)
                                
                    }
                }
                
                self?.dispatchGroup.leave()
            }
        }
    

    // 検索ボタンが押された時の処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let keyword = searchBar.text, !keyword.isEmpty {
            self.keyword = keyword
            searchResults = [] // 新たな検索が始まるたびにリセット
            saveSearchKeyword(keyword: keyword)
            
            fetchSearchResults(keyword: keyword) { [weak self] success in
                if success {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                } else {
                    print("検索結果の取得に失敗しました")
                }
            }
        }
        searchBar.resignFirstResponder()
    }
    
    // SearchBarが編集された時の処理
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            if searchText.isEmpty {
                searchResults = searchHistory.map { Profile(userName: $0, userID: "", profileImage: "") }
            } else {
                searchResults = [] // テキストが入力されている場合は検索結果をクリア
            }
            tableView.reloadData()
        }
        
  
    
    func addFriend(cell: SearchTableViewCell) {
        // 1. キーワードを使用して、指定されたユーザーIDの人のコレクションにwaitfollowerを作成する
        if let currentUserID = Auth.auth().currentUser?.uid {
//            fetchUIDByUserID(userID: keyword) { (uid) in
//                if let uid = uid {
            print("Found user with uid: \(uid)")
            let targetUserID = uid // セルに表示されている文字をキーワードとして使用
            let targetUserCollection = self.db.collection("user").document(targetUserID)  // Firestoreの参照を取得
            // waitfollowerコレクションを作成
            targetUserCollection.collection("waitfollower").addDocument(data:[
                "waitFollowerUser": currentUserID,
                "timestamp": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("waitfollower追加エラー: \(error.localizedDescription)")
                    self.createAlert(title: "友達申請エラー", message: "不明なエラーが発生しました")
                } else {
                    print("waitfollowerに追加されました")
                }
            }
            
            // 2. 自分のコレクションの中にwatifollowを作成し、キーワードを追加する
            let currentUserCollection = self.db.collection("user").document(currentUserID)
            // watifollowコレクションを作成
            currentUserCollection.collection("waitfollow").addDocument(data:[
                "waitFollowUser": targetUserID,
                "timestamp": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("watifollow追加エラー: \(error.localizedDescription)")
                    self.createAlert(title: "友達申請エラー", message: "不明なエラーが発生しました")
                } else {
                    print("watifollowに追加されました")
                    self.createAlert(title: "友達申請成功", message: "承認を待ってください")
                    self.status = .requestSent
                }
            }
        }
    }
    
    // フレンド申請の状態を確認してボタンの表示を設定する関数
    func configureButton(for cell: SearchTableViewCell, with profile: Profile) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let targetUserID = self.uid
            
            if currentUserID == targetUserID {
                // 自分自身のIDと一致する場合、ボタンを非表示にする
                cell.setButtonState(.isFriend)
            } else {
                self.checkFriendRequestStatus(currentUserID: currentUserID, targetUserID: targetUserID) { status in
                    self.status = status
                    
                    switch status {
                    case .requestSent:
                        cell.setButtonState(.requestSent)
                    case .isFriend:
                        cell.setButtonState(.isFriend)
                    case .none:
                        cell.setButtonState(.addFriend)
                    }
                    print(status)
                }
            }
    }

    

    
    // 友達関係の状態を確認する関数
    func checkFriendStatus(currentUserID: String, targetUserID: String, completion: @escaping (Bool) -> Void) {
        let currentUserFriendsCollection = db.collection("user").document(currentUserID).collection("friends")
        
        currentUserFriendsCollection.document(targetUserID).getDocument { (document, error) in
            if let document = document, document.exists {
                // 友達関係が存在する場合
                completion(true)
            } else {
                // 友達関係が存在しない場合
                completion(false)
            }
        }
    }
    
    func checkFriendRequestStatus(currentUserID: String, targetUserID: String, completion: @escaping (FriendRequestStatus) -> Void) {
        let currentUserWaitFollowCollection = db.collection("user").document(currentUserID).collection("waitfollow") // 自分のwaitfollowリストを参照
        
        currentUserWaitFollowCollection.document(targetUserID).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                let targetUserWaitFollowerCollection = self!.db.collection("user").document(targetUserID).collection("waitfollower")  // 相手のwaitfollowerリストを参照
                targetUserWaitFollowerCollection.document(currentUserID).getDocument { (targetDocument, targetError) in
                    if let targetDocument = targetDocument, targetDocument.exists {
                        completion(.requestSent)// 自分と相手のwaitリストの両方に存在する場合
                    } else {
                        completion(.none) // 自分のwaitfollowリストには存在するが、相手のwaitfollowerリストには存在しない場合
                    }
                }
            } else { // 自分のwaitfollowリストにも存在しない場合
                // その他の条件を満たすかどうかを確認し、友達関係があるかどうかを判定
                self?.checkFriendStatus(currentUserID: currentUserID, targetUserID: targetUserID) { isFriend in
                    if isFriend {
                        completion(.isFriend)
                    } else {
                        completion(.none)
                    }
                }
            }
        }
    }
    
    
    func createAlert(title: String, message: String){
        // アラートを表示する
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    func createAlert(){
        // アラートを表示する
        let alertController = UIAlertController(title: "検索結果なし", message: "一致するものが見つかりませんでした。", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setupTableView() {
        tableView.register(UINib(nibName: "SearchTableViewCell", bundle: nil), forCellReuseIdentifier: "profileCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func setupSearchBar() {
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.autocapitalizationType = .none
    }
}



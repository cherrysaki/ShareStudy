//
//  FriendSearchViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 19/7/23.
//

import UIKit
import Firebase

class FriendSearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, FriendSearchViewDelegate {
 
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    var searchHistory: [String] = []
    var searchResults: [Profile] = [] // 検索結果を格納するための配列
    var profiles: [Profile] = [] // プロフィール情報を格納するための配列
    var keyword: String = ""
    
    
    struct Profile {
        let userName: String
        let userID: String
        let profileImage: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "SearchTableViewCell", bundle: nil), forCellReuseIdentifier: "profileCell")
        tableView.register(UINib(nibName: "NoResultTableViewCell", bundle: nil), forCellReuseIdentifier: "noResultCell")
        
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.text = "友達ID検索"
        searchBar.showsCancelButton = true
        searchBar.showsSearchResultsButton = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // 保存された検索履歴を読み出す
        searchHistory = getSearchHistory()
        
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // 一致するアカウントがある場合とない場合の2つのセクションを持つ
        return profiles.isEmpty ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && !profiles.isEmpty {
            // セクション0で、かつプロフィール情報がある場合
            return profiles.count
        } else {
            // セクション1またはプロフィール情報がない場合
            return 1 // 特別なセルを1つだけ表示する
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && !profiles.isEmpty {
            // セクション0で、かつプロフィール情報がある場合は通常のプロフィール情報を表示する
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as! SearchTableViewCell
            let profile = profiles[indexPath.row]
            cell.nameLabel.text = profile.userName
            cell.idLabel.text = profile.userID
            cell.delegate = self
            return cell
        } else {
            // セクション1またはプロフィール情報がない場合は特別なセルを表示する
            let cell = tableView.dequeueReusableCell(withIdentifier: "noResultCell", for: indexPath) as! NoResultTableViewCell
            cell.noResultLabel.text = "一致するものがありません"
            return cell
        }
    }
    
    
    // Firestoreで一致するドキュメントを取得して結果を表示
    func fetchSearchResults(keyword: String) {
        searchResults = [] // 検索結果をクリア
        
        let usersCollection = Firestore.firestore().collection("user")
        
        usersCollection.getDocuments { (usersSnapshot, error) in
            if let error = error {
                // エラーハンドリング
                print("クエリ実行中にエラーが発生しました: \(error.localizedDescription)")
                return
            }
            // usersコレクション内のドキュメントを順に処理
            for userDocument in usersSnapshot!.documents {
                let profileCollection = userDocument.reference.collection("profile")
                let query = profileCollection.whereField("userID", isEqualTo: keyword)
//                let query = profileCollection
                query.getDocuments { (profileSnapshot, error) in
                    if let error = error {
                        // エラーハンドリング
                        print("クエリ実行中にエラーが発生しました: \(error.localizedDescription)")
                        return
                    }
                    
                    if let profileDocuments = profileSnapshot?.documents {
                        for profileDocument in profileDocuments {
                            let data = profileDocument.data()
                            // データの処理
                            if let name = data["userName"] as? String,
                               let id = data["userID"] as? String,
                               let imageUrl = data["profileImage"] as? String {
                                let profile = Profile(userName: name, userID: id, profileImage: imageUrl)
                                self.searchResults.append(profile) // 検索結果をsearchResultsに追加
                            }
                        }
                    }
                    self.tableView.reloadData() // テーブルビューをリロード
                }
            }
        }
    }
    
    
    // 検索ボタンが押された時の処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let keyword = searchBar.text, !keyword.isEmpty {
            self.keyword = keyword
            searchResults = [] // 新たな検索が始まるたびにリセット
            // 検索キーワードを保存
            saveSearchKeyword(keyword: keyword)
            
            // Firestoreで一致するドキュメントを取得して結果を表示
            fetchSearchResults(keyword: keyword)
        }
        searchBar.resignFirstResponder()
    }
    
    
    // SearchBarが編集された時の処理
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // SearchBarのテキストが空の場合は履歴を表示
        if searchText.isEmpty {
            tableView.reloadData()
        }
    }
    
    func addFriend(cell: SearchTableViewCell) {
        // 1. キーワードを使用して、指定されたユーザーIDの人のコレクションにwaitfollowerを作成する
        if let currentUserID = Auth.auth().currentUser?.uid {
            let targetUserID = keyword // セルに表示されている文字をキーワードとして使用
            
            // Firestoreの参照を取得
            let db = Firestore.firestore()
            let targetUserCollection = db.collection("user").document(targetUserID)
            
            // waitfollowerコレクションを作成
            targetUserCollection.collection("waitfollower").document(currentUserID).setData([
                "timestamp": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("waitfollower追加エラー: \(error.localizedDescription)")
                } else {
                    print("waitfollowerに追加されました")
                }
            }
            
            // 2. 自分のコレクションの中にwatifollowを作成し、キーワードを追加する
            let currentUserCollection = db.collection("user").document(currentUserID)
            
            // watifollowコレクションを作成
            currentUserCollection.collection("watifollow").document(targetUserID).setData([
                "waitFollowUser": keyword,
                "timestamp": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("watifollow追加エラー: \(error.localizedDescription)")
                } else {
                    print("watifollowに追加されました")
                }
            }
        }
    }
    
    

}

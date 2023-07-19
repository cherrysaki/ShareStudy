//
//  FriendSearchViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 19/7/23.
//

import UIKit
import Firebase

class FriendSearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    var searchHistory: [String] = []
    var searchResults: [String] = []
    var profiles: [Profile] = [] // プロフィール情報を格納するための配列
    
    
    struct Profile {
        let userName: String
        let userID: String
        let profileImage: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let usersCollection = Firestore.firestore().collection("users")
        
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
                
                query.getDocuments { (profileSnapshot, error) in
                    if let error = error {
                        // エラーハンドリング
                        print("クエリ実行中にエラーが発生しました: \(error.localizedDescription)")
                        return
                    }
                    
                    // クエリ結果の処理
                    if let profileDocuments = profileSnapshot?.documents {
                        for profileDocument in profileDocuments {
                            let data = profileDocument.data()
                            // データの処理
                            if let name = data["userName"] as? String,
                               let id = data["userID"] as? String,
                               let imageUrl = data["profileImage"] as? String {
                                let profile = Profile(userName: name, userID: id, profileImage: imageUrl)
                                self.profiles.append(profile)
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 検索ボタンが押された時の処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let keyword = searchBar.text, !keyword.isEmpty {
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
}



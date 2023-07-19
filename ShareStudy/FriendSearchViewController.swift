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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.text = "友達ID検索"
        searchBar.showsCancelButton = true
        searchBar.showsSearchResultsButton = true
        // 保存された検索履歴を読み出す
        searchHistory = getSearchHistory()
        
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
    
    // テーブルビューのセル数を設定
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchBar.text?.isEmpty ?? true ? searchHistory.count : searchResults.count
    }
    
    // テーブルビューのセルを設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if searchBar.text?.isEmpty ?? true {
            cell.textLabel?.text = searchHistory[indexPath.row]
        } else {
            cell.textLabel?.text = searchResults[indexPath.row]
        }
        
        return cell
    }
    
    
    
    // Firestoreで一致するドキュメントを取得して結果を表示
    func fetchSearchResults(keyword: String) {
        searchResults = [] // 検索結果をクリア
        
        let db = Firestore.firestore()
        let collectionRef = db.collection("user") // Firestoreのコレクション名を指定
        
        collectionRef.whereField("userID", isEqualTo: keyword).getDocuments { (snapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error)")
            } else {
                // Firestoreから一致するドキュメントを取得
                if let documents = snapshot?.documents {
                    self.searchResults = documents.compactMap { $0.get("userID") as? String }
                    DispatchQueue.main.async {
                        self.tableView.reloadData() // テーブルビューを更新
                    }
                }
            }
        }
    }
    
    // 検索ボタンが押された時の処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let keyword = searchBar.text, !keyword.isEmpty {
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

//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        // searchTextに入力されたテキストが渡される
//        print("入力されたテキスト: \(searchText)")
//
//        // ここで入力されたテキストを使った処理を行うことができます
//        if let user = Auth.auth().currentUser {
//            searchFirebase(user: user, searchText: searchText)
//        }else{
//            print("ユーザーがログインしていません")
//        }
//        // 例えば、検索結果を表示するなどの処理を行うことができます
//    }
//
//    func searchFirebase(user: User, searchText: String){
//        // Firebaseのクエリを作成して、サブコレクションから一致するデータを取得
//        let db = Firestore.firestore()
//        let subCollectionRef = db.collection("user/\(user.uid)/profile") // サブコレクションのパスを指定
//
//        // 入力されたテキストを使ってクエリを作成
//        let query = subCollectionRef.whereField("userID", isEqualTo: searchText) // field_nameは検索したいフィールド名
//
//        // クエリを実行
//        query.getDocuments { (snapshot: QuerySnapshot?, error: Error?) in
//            if let error = error {
//                print("データ取得エラー: \(error)")
//                self.userLabel.text = "データ取得エラー"
//                return
//            }
//
//            guard let documents = snapshot?.documents else {
//                print("データがありません")
//                self.userLabel.text = "データがありません"
//                return
//            }
//
//            // 取得したデータを利用して何か処理を行う
//            for document in documents {
//                let data = document.data()
//                // dataから必要な情報を取り出し、表示したり処理したりする
//
//                // 例えば、データを配列に格納してテーブルビューに表示するなどの処理を行う
//                //                if let name = data["name"] as? String,
//                //                       let age = data["age"] as? Int {
//                //                        // フィールドの値を使って何らかの処理を行う
//                //                        print("Name: \(name), Age: \(age)")
//                //                    }
//            }
//        }
//    }
//
//





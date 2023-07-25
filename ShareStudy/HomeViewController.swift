//
//  HomeViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 3/2/23.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
//    ,UITableViewDelegate, UITableViewDataSource
    
    @IBOutlet var tableView:UITableView!
    
    var nameArray: [String] = []
    var userIdArray: [String] = []
    var postTimeArray: [Date] = []
    var studyImageArray: [String] = []
    var iconImageArray: [String] = []
    var isFinishedArray: [Bool] = []
    var onGoingArray: [Bool] = []
    
    var data: Dictionary<String, Any> = [:]
    
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.delegate = self
//        tableView.dataSource = self
//
//        tableView.register(UINib(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: "postCell")
    }
    
    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 10
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        return
//    }

    func fetchMyData(){
        // Firestoreからデータを取得
                db.collection("user").getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("データ取得エラー: \(error.localizedDescription)")
                        return
                    }

                    // データ取得成功時の処理
                    if let documents = querySnapshot?.documents {
                        for document in documents {
                            // Firestoreのデータを取得してdata配列に追加
                            if let name = document.data()["name"] as? String {
//                                self.data.append(name)
                            }
                        }

                        // データ取得後にTableViewをリロード
                        self.tableView.reloadData()
                    }
                }
        
    }
}

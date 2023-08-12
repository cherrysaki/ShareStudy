//
//  HomeViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 3/2/23.
//

import UIKit
import Firebase

class HomeViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet var tableView:UITableView!
    @IBOutlet var iconBarItem: UIBarItem!
    
    var nameArray: [String] = []
    var userIdArray: [String] = []
    var postTimeArray: [String] = []
    var studyImageArray: [UIImage] = []
    var studyTimeArray: [String] = []
    var iconImageArray: [UIImage] = []
    var isFinishedArray: [Bool] = []
    var onGoingArray: [Bool] = []
    
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
        fetchMyData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postTimeArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! HomeTableViewCell
        
        cell.nameLabel.text = nameArray[indexPath.row]
        cell.userIdLabel.text = userIdArray[indexPath.row]
        cell.postTimeLabel.text = postTimeArray[indexPath.row]
        cell.studyTimeLabel.text = studyTimeArray[indexPath.row]
        cell.studyImageView.image = studyImageArray[indexPath.row]
        cell.iconImageView.image = iconImageArray[indexPath.row]
        
        return cell
    }
    
    func fetchMyData(){
        
        var nameArray: [String] = []
        var userIdArray: [String] = []
        var postTimeArray: [String] = []
        var studyImageArray: [UIImage] = []
        var studyTimeArray: [String] = []
        var iconImageArray: [UIImage] = []
        //        var isFinishedArray: [Bool] = []
        //        var onGoingArray: [Bool] = []
        
        if let currentUserID = Auth.auth().currentUser?.uid {
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
                        let data = document.data()
                        if let name = data["userName"] as? String,
                           let userID = data["userID"] as? String,
                           let studyTime = data["studyTime"] as? String,
                           let studyImageURL = URL(string: data["image"] as! String),
                           let iconImageURL = URL(string: data["profileImageName"] as! String),
                           let postTime = data["date"] as? Timestamp
                        {
                            nameArray.append(name)
                            userIdArray.append(userID)
                            studyTimeArray.append(studyTime)
                            
                            let studyData = NSData(contentsOf: studyImageURL)
                            let studyImage = UIImage(data: studyData! as Data)!
                            studyImageArray.append(studyImage)
                            
                            let iconData = NSData(contentsOf: iconImageURL)
                            let iconImage = UIImage(data: iconData! as Data)!
                            iconImageArray.append(iconImage)
                            
                            let dates: Date = postTime.dateValue()
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "ja_JP")
                            dateFormatter.dateStyle = .medium
                            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
                            postTimeArray.append(dateFormatter.string(from: dates))
                        }
                    }
                    self.nameArray = nameArray
                    self.userIdArray = userIdArray
                    self.studyImageArray = studyImageArray
                    self.studyTimeArray = studyTimeArray
                    self.iconImageArray = iconImageArray
                    self.postTimeArray = postTimeArray
                    
                }
                
                // データ取得後にTableViewをリロード
                self.tableView.reloadData()
            }
        }
        
    }
}


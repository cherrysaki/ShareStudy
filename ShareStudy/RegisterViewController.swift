//
//  RegisterViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 15/7/23.
//

import UIKit
import Firebase
import FirebaseStorage

class RegisterViewController: UIViewController,UITextFieldDelegate,UIScrollViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet var iconImageButton: UIButton!
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var userIdTextField: UITextField!
    //    @IBOutlet var skipButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    
    let imagePicker = UIImagePickerController()
    
    var screenHeight:CGFloat!
    var screenWidth:CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userIdTextField.delegate = self
        userNameTextField.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        scrollView.delegate = self
        
        setupUI()
        
        // 画面サイズ取得
        let screenSize: CGRect = UIScreen.main.bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
    }
    
    override func didReceiveMemoryWarning() {
           super.didReceiveMemoryWarning()
       }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillHide(_:)) ,
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillShowNotification,
                                                  object: self.view.window)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardDidHideNotification,
                                                  object: self.view.window)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let info = notification.userInfo!
        
        let keyboardFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        // bottom of textField
        let bottomTextField = userIdTextField.frame.origin.y + userIdTextField.frame.height
        // top of keyboard
        let topKeyboard = screenHeight - keyboardFrame.size.height
        // 重なり
        let distance = topKeyboard - bottomTextField
        print(distance)
        
        if distance <= 0 {
            // scrollViewのコンテツを上へオフセット + (追加のオフセット)
            scrollView.contentOffset.y = distance + 150.0
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        scrollView.contentOffset.y = 0
    }
    
    @IBAction func iconImageButtonTapped(_ sender: UIButton){
        present(imagePicker, animated: true, completion: nil)
    }
    
    // 新規登録処理
    @IBAction func nextButtonTapped(_ sender: Any) {
        save()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    //完了ボタンが押された後に呼ばれるメソッド
    func save() {
        if let image = imageView.image, let imageData = image.jpegData(compressionQuality: 0.8) {
            if let user = Auth.auth().currentUser {
                postImage(user: user, image: imageData) { result in
                    switch result {
                    case .success(let urlString):
                        print("ダウンロードURL: \(urlString)")
                        // ここでダウンロードURLを使った処理を行う
                        self.registerNewUser(user: user,profileImageName: urlString)
                        
                        //画面遷移
                        let storyboard: UIStoryboard = self.storyboard!
                        let next = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
                        self.present(next, animated: true, completion: nil)
                        
                    case .failure(let error):
                        print("エラー: \(error)")
                        // エラー発生時の処理を行う
                    }
                }
            }else {
                print("Error: ユーザーがログインしていません。")
                return
            }
        }
    }
    
    func postImage(user: User, image: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let currentTimeStampInSecond = NSDate().timeIntervalSince1970
        let storage = Storage.storage().reference(forURL: "gs://original-app-31d37.appspot.com")
        
        let storageRef = storage.child("ShareStudyImage").child(user.uid).child("\(user.uid)+\(currentTimeStampInSecond).jpg")
        
        let uploadTask = storageRef.putData(image, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Firebase Storageへの画像の保存に失敗")
                print(error.localizedDescription)
                completion(.failure(error))
            } else {
                print("Firebase Storageへの画像の保存に成功")
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Firebase Storageからのダウンロードに失敗しました")
                        print(error.localizedDescription)
                        completion(.failure(error))
                    } else if let urlString = url?.absoluteString {
                        print("Firebase Storageからのダウンロードに成功しました")
                        completion(.success(urlString))
                    }
                }
            }
        }
        
        uploadTask.observe(.success) { snapshot in
            // アップロードが成功した場合の処理
            print("アップロード成功")
        }
        
        uploadTask.observe(.failure) { snapshot in
            // アップロードが失敗した場合の処理
            if let error = snapshot.error {
                print("アップロード失敗")
                print(error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    // 写真を選択した後に呼ばれるメソッド
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            
            // ImageViewに選択した画像を表示
            imageView.image = image
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // 写真選択をキャンセルした後に呼ばれるメソッド
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    func registerNewUser(user: User, profileImageName: String) {
        
        if userIdTextField.text! != "" && userNameTextField.text! != "" {
            if let userID = self.userIdTextField.text,
               let userName = self.userNameTextField.text{
                // Firestoreへの参照を取得
                let db = Firestore.firestore()
                // Firestore.firestore().collection("user/\(user.uid)/study").addDocument(data: [
                // "users"コレクション内でuserIDが一致するドキュメントを検索
                db.collection("user/\(user.uid)/profile").whereField("userID", isEqualTo: userID).getDocuments { (querySnapshot, err) in
                    if let err = err {
                        print("エラー: \(err)")
                    } else {
                        // userIDが既に存在する場合はエラーメッセージを表示
                        if querySnapshot!.documents.count > 0 {
                            print("エラー: このユーザーIDはすでに存在します。")
                            let dialog = UIAlertController(title: "登録失敗", message: "このユーザーIDはすでに存在します", preferredStyle: .alert)
                            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(dialog, animated: true, completion: nil)
                        } else {
                            // userIDが存在しない場合は新規ユーザーを登録
                            var ref: DocumentReference? = nil
                            
                            ref = db.collection("user/\(user.uid)/profile").addDocument(data: [
                                "userID": userID,
                                "userName": userName,
                                "profileImageName": profileImageName
                                
                            ]) { err in
                                if let err = err {
                                    print("エラー: \(err)")
                                } else {
                                    print("新規ユーザーが登録されました。ID: \(ref!.documentID)")
                                }
                            }
                        }
                    }
                }
            }
        }else{
            //アラート
            let dialog = UIAlertController(title: "登録失敗", message: "ユーザーネームとユーザーIDを入力してください", preferredStyle: .alert)
            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(dialog, animated: true, completion: nil)
        }
    }
    
    func setupUI(){
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 75
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.borderWidth  = 0.1
        //        skipButton.layer.cornerRadius = 3
        nextButton.layer.cornerRadius = 3
        
    }
    
}




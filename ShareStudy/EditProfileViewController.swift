//
//  EditProfileViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 22/8/23.
//

import UIKit
import Firebase
import FirebaseStorage

class EditProfileViewController: UIViewController,UITextFieldDelegate,UITextViewDelegate,UIScrollViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var userIdTextField: UITextField!
    @IBOutlet var introTextView: UITextView!
    @IBOutlet var scrollView: UIScrollView!
    
    
    var screenHeight:CGFloat!
    var screenWidth:CGFloat!
    
    let db = Firestore.firestore()
    let imagePicker = UIImagePickerController()
    let placeholder = "自己紹介を記入しよう"
    let maxCharacterCount = 100 // 制限する文字数
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userIdTextField.delegate = self
        userNameTextField.delegate = self
        introTextView.delegate = self
        introTextView.isScrollEnabled = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        scrollView.delegate = self
        
        
        displayMyProfile()
        
        setupTextFieldUI(userNameTextField)
        setupTextFieldUI(userIdTextField)
        setupTextViewUI()
        setupImageViewUI()
        
        // 画面サイズ取得
        let screenSize: CGRect = UIScreen.main.bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
    }
    
    
    //キーボードの設定まわり
    
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
        let bottomTextField = introTextView.frame.origin.y + introTextView.frame.height
        // top of keyboard
        let topKeyboard = screenHeight - keyboardFrame.size.height
        // 重なり
        let distance = topKeyboard - bottomTextField
        print(distance)
        
        if distance <= 0 {
            // scrollViewのコンテツを上へオフセット + (追加のオフセット)
            scrollView.contentOffset.y = distance + 70.0
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        scrollView.contentOffset.y = 0
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.lightGray
        }
    }
    
    //textViewに字数制限をつける
    func textViewDidChange(_ textView: UITextView) {
        limitTextViewCharacterCount()
    }
    
    func limitTextViewCharacterCount() {
        guard let text = introTextView.text else {
            return
        }
        
        // 文字数を制限
        if text.count > maxCharacterCount {
            let index = text.index(text.startIndex, offsetBy: maxCharacterCount)
            let newText = text[text.startIndex..<index]
            introTextView.text = String(newText)
        }
    }
    
    @IBAction func saveProfile(){
        save()
    }
    
    @IBAction func cancelButtonTapped(){
        dismiss(animated: true)
    }
    
    //写真選択まわり
    @IBAction func iconEditButtonTapped(_ sender: UIButton){
        present(imagePicker, animated: true, completion: nil)
    }
    
    // 写真を選択した後に呼ばれるメソッド
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            
            // ImageViewに選択した画像を表示
            iconImageView.image = image
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // 写真選択をキャンセルした後に呼ばれるメソッド
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    func displayMyProfile() {
        let loadingView = createLoadingView()
        UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.addSubview(loadingView)
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        fetchProfileData(for: currentUserID) { [weak self] profileData in
            DispatchQueue.main.async {
                if let profileData = profileData {
                    self?.updateUI(with: profileData)
                }
                loadingView.removeFromSuperview()
            }
        }
    }

    func fetchProfileData(for userID: String, completion: @escaping ([String: Any]?) -> Void) {
        let userDocRef = db.collection("user").document(userID).collection("profile")
        
        userDocRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("データ取得エラー: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let documents = querySnapshot?.documents {
                for document in documents {
                    let data = document.data()
                    if let userName = data["userName"] as? String,
                        let userId = data["userID"] as? String,
                        let introduction = data["selfIntroduction"] as? String,
                        let iconImageURL = URL(string: data["profileImageName"] as! String) {
                        
                        let profileData: [String: Any] = [
                            "userName": userName,
                            "userId": userId,
                            "introduction": introduction,
                            "iconImageURL": iconImageURL
                        ]
                        completion(profileData)
                        return
                    }
                }
            }
            completion(nil)
        }
    }

    func updateUI(with profileData: [String: Any]) {
        userNameTextField.text = profileData["userName"] as? String
        userIdTextField.text = profileData["userId"] as? String
        introTextView.text = profileData["introduction"] as? String
        
        if let iconImageURL = profileData["iconImageURL"] as? URL {
            downloadIconImage(from: iconImageURL) { [weak self] iconImage in
                DispatchQueue.main.async {
                    self?.iconImageView.image = iconImage
                }
            }
        }
    }

    func downloadIconImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            if let iconData = try? Data(contentsOf: url),
                let iconImage = UIImage(data: iconData) {
                completion(iconImage)
            } else {
                completion(nil)
            }
        }
    }
    
    
    //保存
    func save() {
        if let image = iconImageView.image, let imageData = image.jpegData(compressionQuality: 0.8) {
            if let user = Auth.auth().currentUser {
                postImage(user: user, image: imageData) { result in
                    switch result {
                    case .success(let urlString):
                        print("ダウンロードURL: \(urlString)")
                        // ここでダウンロードURLを使った処理を行う
                        self.updateProfile(user: user,profileImageName: urlString)
                        
                        //画面遷移
                        let storyboard: UIStoryboard = self.storyboard!
                        let next = storyboard.instantiateViewController(withIdentifier: "ProfileViewController")
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
        let storage = Storage.storage().reference(forURL: "gs://sharestudy-e58f3.appspot.com")
        
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
    
    
    
    
    func updateProfile(user: User, profileImageName: String) {
        if let userID = self.userIdTextField.text,
           let userName = self.userNameTextField.text,
           let introduction = self.introTextView.text {
            // Firestoreへの参照を取得
            let db = Firestore.firestore()
            let userRef = db.collection("user").document(user.uid).collection("profile").document(user.uid) // ここで既存のドキュメントを指定
            
            // 更新したいデータを指定
            let updatedData: [String: Any] = [
                "userID": userID,
                "userName": userName,
                "profileImageName": profileImageName,
                "selfIntroduction": introduction
            ]
            
            userRef.setData(updatedData, merge: true) { err in
                if let err = err {
                    print("エラー: \(err)")
                } else {
                    print("ユーザープロフィールが更新されました。")
                }
            }
        } else {
            //アラート
            let dialog = UIAlertController(title: "登録失敗", message: "ユーザーネームとユーザーIDを入力してください", preferredStyle: .alert)
            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(dialog, animated: true, completion: nil)
        }
    }

    
//    以下UIのセットアップ
    
    func setupImageViewUI(){
        iconImageView.layer.masksToBounds = true
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        iconImageView.layer.borderColor = UIColor.lightGray.cgColor
        iconImageView.layer.borderWidth  = 0.1
        iconImageView.clipsToBounds = true
    }
    
    func setupTextFieldUI(_ textField: UITextField){
        textField.borderStyle = .none
        // 下部の枠線を設定
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0, y: textField.frame.size.height , width: textField.frame.size.width, height: 1)
        bottomBorder.backgroundColor = UIColor.lightGray.cgColor
        
        // UITextFieldに下部の枠線を追加
        textField.layer.addSublayer(bottomBorder)
        
    }
    
    func setupTextViewUI(){
        
        introTextView.text = self.placeholder
        introTextView.textColor = UIColor.lightGray
        introTextView.layer.borderWidth = 0
        
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0, y: introTextView.frame.size.height - 3, width: introTextView.frame.size.width, height: 1)
        bottomBorder.backgroundColor = UIColor.lightGray.cgColor
        
        // UITextFieldに下部の枠線を追加
        introTextView.layer.addSublayer(bottomBorder)
        
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

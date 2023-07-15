//
//  RegisterViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 15/7/23.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController,UITextFieldDelegate,UIScrollViewDelegate {
    
    @IBOutlet var iconImageButton: UIButton!
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var userIdTextField: UITextField!
    @IBOutlet var skipButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userIdTextField.delegate = self
        userNameTextField.delegate = self
        
    }
    
    @IBAction func iconImageButtonTapped(_ sender: Any){
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    // 新規登録処理
    @IBAction func nextButtonTapped(_ sender: Any) {

        guard let userId = userIdTextField.text,
              let userName = userNameTextField.text
        else { return }

        // FirebaseAuthへ保存
//        signUpModel.createUser(email: email, password: password)
    }
    
    
    
    private func createImageToFirestorage() {
        // プロフィール画像が設定されている場合の処理
        if let image = self.iconImageButton.imageView?.image {
            let uploadImage = image.jpegData(compressionQuality: 0.5)
            let fileName = NSUUID().uuidString
            // FirebaseStorageへ保存
//            signUpModel.creatrImage(fileName: fileName, uploadImage: uploadImage!)
        } else {
            print("プロフィール画像が設定されていないため、デフォルト画像になります。")
            // User情報をFirebaseFirestoreへ保存
//            self.createUserToFirestore(profileImageName: nil)
        }
    }
    
    // User情報をFirebaseFirestoreへ保存する処理
       private func createUserToFirestore(profileImageName: String?) {

           guard let email = Auth.auth().currentUser?.email,
                 let uid = Auth.auth().currentUser?.uid,
                 let userName = self.userNameTextField.text
           else { return }

           // 保存内容を定義する（辞書型）
           let docData = ["email": email,
                          "userName": userName,
                          "profileImageName": profileImageName,
                          "createdAt": Timestamp()] as [String : Any?]

           // FirebaseFirestoreへ保存
//           signUpModel.createUserInfo(uid: uid, docDate: docData as [String : Any])
       }

   

    func setupUI(){
        iconImageButton.layer.masksToBounds = true
        iconImageButton.layer.cornerRadius = 75
        iconImageButton.layer.borderColor = UIColor.lightGray.cgColor
        iconImageButton.layer.borderWidth  = 0.1
        skipButton.layer.cornerRadius = 3
        nextButton.layer.cornerRadius = 3

    }
    
    
}


extension RegisterViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    // 写真が選択された時に呼ばれるメソッド
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            iconImageButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            iconImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        dismiss(animated: true, completion: nil)
    }
    
}

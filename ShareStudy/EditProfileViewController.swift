//
//  EditProfileViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 22/8/23.
//

import UIKit

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
    
    let imagePicker = UIImagePickerController()
    
    let placeholder = "自己紹介"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userIdTextField.delegate = self
        userNameTextField.delegate = self
        introTextView.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        scrollView.delegate = self
        
        
        setupTextFieldUI(userNameTextField)
        setupTextFieldUI(userIdTextField)
        setupTextViewUI()
        setupImageViewUI()
        
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
        
        
    
        @IBAction func iconImageButtonTapped(_ sender: UIButton){
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
        
        
    
    
}

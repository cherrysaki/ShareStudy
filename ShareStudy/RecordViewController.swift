//
//  RecordViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 23/5/23.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseStorage

class RecordViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var cameraView: UIView! // Storyboard上のUIViewに接続するIBOutlet
    @IBOutlet weak var captureButton: UIButton! // Storyboard上のUIButtonに接続するIBOutlet
    @IBOutlet weak var Picker: UIDatePicker!
    @IBOutlet weak var BackButton: UIBarButtonItem!
    
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    
    var ongoing: Bool = false
    var imageView: UIImage! = nil
    
    var studytime: Double = 0
    
    var StatusNumber: Int = 1
    
    let startimage = UIImage(named: "Start")
    let finishimage = UIImage(named: "Finish")
    let state = UIControl.State.normal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        BackButton.isHidden = true
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("カメラデバイスが取得できません")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = cameraView.bounds
            cameraView.layer.addSublayer(videoPreviewLayer)
            
            photoOutput = AVCapturePhotoOutput()
            captureSession.addOutput(photoOutput)
            
            captureSession.startRunning()
        } catch {
            print("カメラのセットアップに失敗しました: \(error.localizedDescription)")
        }
    }
    
    @IBAction func Back(){
        tabBarController?.tabBar.isHidden = false
        let previousViewController = self.tabBarController?.viewControllers?[0]
        self.tabBarController?.selectedViewController = previousViewController
    }
    
    
    
    @IBAction func mainButtonTapped(_ sender: UIButton) {
        switch StatusNumber{
        case 1:
            tabBarController?.tabBar.isHidden = true
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
            StatusNumber = 2
            captureButton.setImage(startimage, for: state)
            BackButton.isHidden = false
        case 2:
            ongoing = true
            save()
            StatusNumber = 3
            captureButton.setImage(finishimage, for: state)
        case 3:
            StatusNumber = 1
            tabBarController?.tabBar.isHidden = false
            let previousViewController = self.tabBarController?.viewControllers?[0]
        default:
            break
        }
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            DispatchQueue.main.async { [weak self] in
                //カメラで撮ったのが出てくる
                let trimImage = self!.trimmingImage(image, trimmingArea: self?.cameraView.frame ?? CGRect.zero)
                print(self?.cameraView.frame.width)
                let takedImageView = UIImageView(image: trimImage)
                //                takedImageView.frame = self?.cameraView.bounds ?? CGRect.zero
                takedImageView.contentMode = .scaleAspectFit
                takedImageView.clipsToBounds = true
                self?.cameraView.addSubview(takedImageView)
                //UIImageViewのサイズ指定。
                
                
                //保存したいのは、image(UIImage(data: imageData)が入ってる)
                self?.imageView = image
            }
        }
    }
    //写真をリサイズ
    func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage {
        let imgRef = image.cgImage?.cropping(to: trimmingArea)
        let trimImage = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        return trimImage
    }
    
    //dataPickerから時間のデータをとる
    func GetDate(_ sender: UIDatePicker) {
        //秒表記されてる
        print(Picker.countDownDuration)
        studytime = Picker.countDownDuration
    }
    
    
    func save(){
        
        // ユーザーがログインしているか確認する
        if let user = Auth.auth().currentUser {
            let image = self.imageView.jpegData(compressionQuality: 0.01)!
            // データを保存
            DispatchQueue(label: "post data", qos: .default).async {
                // 画像のアップロード
                let ref = self.postImage(user: user,image: image)
                // ダウンロードURLの取得
                let url = self.getDownloadUrl(storageRef: ref)
                self.GetDate(self.Picker)
                self.post(user: user, imageUrlString: url)
            }
            print("complete!")
        }else {
            print("Error: ユーザーがログインしていません。")
            return
        }
        
    }
    
    func postImage(user: User,image:Data) -> StorageReference {
        let semaphore = DispatchSemaphore(value: 0)
        
        let currentTimeStampInSecond = NSDate().timeIntervalSince1970
        let storage = Storage.storage().reference(forURL: "gs://original-app-31d37.appspot.com")
        
        // 保存する場所を指定
        let storageRef = storage.child("ShareStudyImage").child(user.uid).child("\(user.uid)+\(currentTimeStampInSecond).jpg")
        
        // ファイルをアップロード
        storageRef.putData(image, metadata: nil) { (metadate, error) in
            //errorがあったら
            if error != nil {
                print("Firestrageへの画像の保存に失敗")
                print(error.debugDescription)
            }else {
                print("Firestrageへの画像の保存に成功")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return storageRef
    }
    
    
    func getDownloadUrl(storageRef: StorageReference) -> String {
        let semaphore = DispatchSemaphore(value: 0)
        
        var imageUrlString = ""
        
        storageRef.downloadURL { (url, error) in
            if error != nil {
                print("Firestorageからのダウンロードに失敗しました")
                print(error.debugDescription)
            } else {
                print("Firestorageからのダウンロードに成功しました")
                //6URLをString型に変更して変数urlStringにdainyuu
                guard let urlString = url?.absoluteString else {
                    return
                }
                imageUrlString = urlString
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return imageUrlString
    }
    
    
    
    func post(user: User, imageUrlString: String) {
        Firestore.firestore().collection("user/\(user.uid)/study").addDocument(data: [
            "date": FieldValue.serverTimestamp(),
            "studytime": studytime,
            "image": imageUrlString,
            "Bool": ongoing
        ]) { error in
            if let error = error {
                // 失敗した場合
                print("投稿失敗: " + error.localizedDescription)
                let dialog = UIAlertController(title: "投稿失敗", message: error.localizedDescription, preferredStyle: .alert)
                dialog.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(dialog, animated: true, completion: nil)
            } else {
                print("投稿成功")
            }
            return
        }
    }
    
    
    
    
    
    
}

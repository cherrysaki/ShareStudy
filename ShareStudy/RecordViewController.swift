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
    
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    
    let ongoing: Bool = false
    var imageView: UIImage! = nil
    
    var studytime: Date!
    
    
    
    let startimage = UIImage(named: "Start")
    let state = UIControl.State.normal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
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
    
    @IBAction func captureButtonTapped(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            DispatchQueue.main.async { [weak self] in
                // 撮影した写真を表示するための処理を追加する
               // self?.imageView = UIImageView(image: image)
                
                //カメラで撮ったのが出てくる
                let takedImageView = UIImageView(image: image)
                takedImageView.frame = self?.cameraView.bounds ?? CGRect.zero
                takedImageView.contentMode = .scaleAspectFit
                takedImageView.clipsToBounds = true
                self?.cameraView.addSubview(takedImageView)
                
                //保存したいのは、image(UIImage(data: imageData)が入ってる)
                self?.imageView = image
            }
            tabBarController?.tabBar.isHidden = true
            //ボタンを切り替える
            captureButton.setImage(startimage, for: state) //開始になる
            post()
            //アラートを出す
            //メソッドでかく
            
        }
    }
    
    //dataPickerから時間のデータをとる
    func GetDate(_ sender: Any) {
        studytime = Picker.date
        }
    
    //投稿
    func post(){
        // ユーザーがログインしているか確認する
        if let user = Auth.auth().currentUser {
            let image = self.imageView.jpegData(compressionQuality: 0.01)!
            // データを保存
            DispatchQueue(label: "post data", qos: .default).async {
                // 画像のアップロード
                let ref = postImage(user: user,image: image)
                // ダウンロードURLの取得
                let url = getDownloadUrl(storageRef: ref)
            }
            print("complete!")
        }else {
            print("Error: ユーザーがログインしていません。")
            return
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
        
    }
    
    
    
    
    
    
    
    
}

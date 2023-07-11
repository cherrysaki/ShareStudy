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
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var Picker: UIDatePicker!
    @IBOutlet weak var BackButton: UIBarButtonItem!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var resetButton:UIButton!
    
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    
   
    var imageView: UIImage! = nil
    
    var ongoing: Bool = false
    var studytime: Double = 0
    
    
    var statusNumber: Int = 0
    var buttonStatus: Int = 0
    var timerTappedNumber: Int = 0
    
    var time: Double = 0.0
    var restTime: Double = 0.0
    var timer: Timer = Timer()
    
    
    let takeImage = UIImage(named: "Take")
    let startImage = UIImage(named: "Start")
    let finishImage = UIImage(named: "Finish")
    let restartImage = UIImage(named: "Restart")
    let pauseImage = UIImage(named: "Pause")
    let state = UIControl.State.normal
    let timerLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Picker.locale = Locale(identifier: "ja-JP")
        self.makeLabel()
        timerLabel.isHidden = true
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        stopButton.setImage(pauseImage, for: state)
        captureButton.setImage(takeImage, for: state)
//        buttonStatus = 1
        BackButton.isHidden = true
        statusChanged()
    }

    
    @IBAction func mainButtonTapped(_ sender: UIButton) {
       statusChanged()
    }
    
    @IBAction func timerControlButtonTapped(){
        if buttonStatus == 0{
            buttonStatus = 1
        }else if buttonStatus == 1{
            buttonStatus = 0
        }
        buttonUIUpdate()

    }
    
//    リセット機能は後で作る
    @IBAction func resetButtonTapped(){
       buttonStatus = 2
       buttonUIUpdate()
        buttonStatus = 1
        
    }
    
    //ホーム画面に戻る
    @IBAction func Back(){
        tabBarController?.tabBar.isHidden = false
        let previousViewController = self.tabBarController?.viewControllers?[0]
        self.tabBarController?.selectedViewController = previousViewController
    }
    
    //タイマーをセットする。時間を表示する
    func timerStart(setTime: Double){
        
        print(setTime)
        
        time = setTime
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [self] _ in
                //1秒ごとに呼ばれる処理
            
            //1. timeの変更
            time -= 1.0

            //2. ラベルの表示
            timerUIUpdate(time: time)
            
            //3. 時間が指定時間になったらの処理
            if time < 0{
                let finishAlert = UIAlertController(title: "タイマーが終了しました", message: nil, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                finishAlert.addAction(okAction)
                present(finishAlert, animated: true)
                
                timer.invalidate()
            }
            
            })
        

    }
    
    //タイマーがストップされた時の残り時間をとってくる
    func timerStop(){
            restTime = time
            self.timer.invalidate()
    }
    
    //タイマーをリセットする
    func timerReset(){
        let resetAlert = UIAlertController(title: "タイマーをリセットしますか？", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default){ _ in
            // OKが選択された場合の処理
            self.getData(self.Picker)
            self.time = self.studytime
            self.timerUIUpdate(time: self.time)
            self.timer.invalidate()
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        resetAlert.addAction(okAction)
        resetAlert.addAction(cancelAction)
        present(resetAlert, animated: true)
    }
    
    func statusChanged(){
        switch statusNumber{
        case 0:
            Picker.isHidden = false
            stopButton.isHidden = true
            resetButton.isHidden = true
            timerLabel.isHidden = true
            
            statusNumber = 1
        case 1:
            tabBarController?.tabBar.isHidden = true
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
            statusNumber = 2
            captureButton.setImage(startImage, for: state)
            BackButton.isHidden = false
        case 2:
            stopButton.isHidden = false
            resetButton.isHidden = false
            Picker.isHidden = true
            timerLabel.isHidden = false
            
            ongoing = true
            getData(Picker)
            timerStart(setTime: studytime)
            buttonStatus = 1
            save()
            statusNumber = 3
            captureButton.setImage(finishImage, for: state)
        case 3:
            tabBarController?.tabBar.isHidden = false
            let previousViewController = self.tabBarController?.viewControllers?[0]
            self.tabBarController?.selectedViewController = previousViewController
            statusNumber = 0
        default:
            break
        }
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
                
                // カメラビューのアスペクト比を4:3に設定する
                let cameraAspectRatio: CGFloat = 3.0 / 4.0
                let cameraWidth = cameraView.frame.width
                let cameraHeight = cameraWidth / cameraAspectRatio

                let x = (cameraView.frame.width - cameraWidth) / 2
                let y = (cameraView.frame.height - cameraHeight) / 2

                let cameraFrame = CGRect(x: x, y: y, width: cameraWidth, height: cameraHeight)

                videoPreviewLayer.frame = cameraFrame
                       
                       cameraView.layer.addSublayer(videoPreviewLayer)
                       
                       photoOutput = AVCapturePhotoOutput()
                       captureSession.addOutput(photoOutput)
                       
                       captureSession.startRunning()
                   } catch {
                       print("カメラのセットアップに失敗しました: \(error.localizedDescription)")
                   }
        }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }

                        let cameraFrame = self.cameraView.frame
                        let cameraBounds = self.cameraView.bounds

                        let trimmingArea = CGRect(x: (cameraBounds.width - cameraBounds.height) / 2.0,
                                                  y: 0,
                                                  width: cameraBounds.height,
                                                  height: cameraBounds.height)

                        let trimmedImage = self.trimmingImage(image, trimmingArea: trimmingArea)

                        let scaledImage = self.resizeImage(trimmedImage, targetSize: cameraFrame.size)

                        let takedImageView = UIImageView(image: scaledImage)
                        takedImageView.contentMode = .scaleAspectFit
                        takedImageView.frame = self.cameraView.bounds
                        takedImageView.clipsToBounds = true
                        self.cameraView.addSubview(takedImageView)

                        // Save the original image
                        self.imageView = image
                    }
                }
        }
    
    //写真をリサイズ

    func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage {
            
            let cropRect = CGRect(x: image.size.width * trimmingArea.origin.x,
                                      y: image.size.height * trimmingArea.origin.y,
                                      width: image.size.width * trimmingArea.size.width,
                                      height: image.size.height * trimmingArea.size.height)

                if let cgImage = image.cgImage?.cropping(to: cropRect) {
                    return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
                }
                return image
        }

        func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let scaledImage = renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            return scaledImage
        }
   
    
    //dataPickerから時間のデータをとる
    func getData(_ sender: UIDatePicker) {
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
                self.getData(self.Picker)
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
    
    func buttonUIUpdate(){
        switch buttonStatus{
        case 0:
            stopButton.setImage(restartImage, for: state)
            timerStop() //一時停止
        case 1:
            stopButton.setImage(pauseImage, for: state)
            timerStart(setTime: restTime) //再開
        case 2:
            stopButton.setImage(pauseImage, for: state)
            timerReset()//リセット
        default:
            break
        }
    }
    
    func timerUIUpdate(time: Double){
        let hours = Int(time / 3600)
        let resthours = Int(time) % 3600
        let minutes = Int(resthours / 60)
        let restminutes = Int(resthours) % 60
        let second = Int(restminutes) % 60
        self.timerLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, second)
    }
    
    
    func makeLabel(){
        timerLabel.frame = CGRect(x: 0, y: 600, width: UIScreen.main.bounds.size.width, height: 44)
        timerLabel.font = UIFont.boldSystemFont(ofSize: 40)
        timerLabel.textAlignment = NSTextAlignment.center
        self.view.addSubview(timerLabel)
    }
    
    
    
    
}

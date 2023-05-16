//
//  CreateRoomViewController.swift
//  ShareStudyUITests
//
//  Created by 神林沙希 on 11/3/23.
//

import UIKit
import Firebase

class CreateRoomViewController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet var GoalTextField: UITextField!
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        GoalTextField.delegate = self
        super.viewDidLoad()
    }
    
    @IBAction func CreateRoom(){
        var ref: DocumentReference? = nil
        if GoalTextField.text! != ""{
            if let goal = GoalTextField.text{
                ref = db.collection("rooms").addDocument(data: [
                    "goal": goal,
                ]) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                        let dialog = UIAlertController(title: "ルーム作成失敗", message: "もう一度やり直してください", preferredStyle: .alert)
                        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(dialog, animated: true, completion: nil)
                    } else {
                        print("Document added with ID: \(ref!.documentID)")
                        self.performSegue(withIdentifier: "toCreateTask", sender: self)
                    }
                }
                
            }
        }else{
            let dialog = UIAlertController(title: "ルーム作成失敗", message: "目標を入力してください", preferredStyle: .alert)
            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(dialog, animated: true, completion: nil)
        }
        
    }
    
    
    
}

//
//  SignInViewController.swift
//  ShareStudy
//
//  Created by 神林沙希 on 17/2/23.
//

import UIKit
import Firebase
import GoogleSignIn

class SignInViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("viewDidAppear")
                if let user = Auth.auth().currentUser {
                    print("user: \(user.uid)")
                    print(user)
                    let storyboard: UIStoryboard = self.storyboard!
                    let next = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
                    self.present(next, animated: true, completion: nil)
        
                }
    }
    
    @IBAction func didTapSignInButton(_ sender: Any) {
        auth()
    }
    
    
    private func auth() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Firebase client ID not found.")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            if let error = error {
                print("GIDSignInError: \(error.localizedDescription)")
                return
            }
            
            if let uid = signInResult?.user.userID,
               let name = signInResult?.user.profile?.name,
               let email = signInResult?.user.profile?.email {
                self.writeUserData(uid: uid, name: name, email: email)
            }
        }
    }
    
    private func writeUserData(uid: String, name: String, email: String) {
        let userCollection = db.collection("user")
        let userDocument = userCollection.document(uid)
        
        userDocument.setData([
            "name": name,
            "email": email
        ]) { error in
            if let error = error {
                print("Firestore 新規登録失敗 " + error.localizedDescription)
            } else {
                print("Firestore 新規登録成功")
                
                //                 成功した場合はRegisterViewに画面遷移を行う
                let storyboard: UIStoryboard = self.storyboard!
                let next = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
                self.present(next, animated: true, completion: nil)
            }
        }
    }


//    private func auth() {
//        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
//        let config = GIDConfiguration(clientID: clientID)
//        GIDSignIn.sharedInstance.configuration = config
//
//        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
//            if let error = error {
//                print("GIDSignInError: \(error.localizedDescription)")
//                return
//            }
//
//            guard let authentication = signInResult?.user,
//                  let idToken = authentication.idToken?.tokenString else { return }
//
//            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken.tokenString)
//
//
//            Auth.auth().signIn(with: credential) { (authResult, error) in
//                if  let user = signInResult?.user {
//                    let name = user.profile!.name
//                    let email = user.profile!.email
//
//
//
//                    self.db.collection("user").document((authResult?.user.uid)!).setData([
//                        "name": name,
//                        "email": email
//                    ],completion: { error in
//                        if let error = error {
//                            // 失敗した場合
//                            print("Firestore 新規登録失敗 " + error.localizedDescription)
//                        } else {
//
//                            print("ログイン完了 name:" + name)
//                            // 成功した場合はRegisterViewに画面遷移を行う
//                            let storyboard: UIStoryboard = self.storyboard!
//                            let next = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
//                            self.present(next, animated: true, completion: nil)
//                        }
//
//                    }
//
//
//                    ) }
//
//                    }
//            self.login(credential: credential)
//
//        }
//    }



//                    let userCollection = db.collection("users") // "users"はコレクション名
//                    let currentUserUID = Auth.auth().currentUser?.uid
//
//                    if let uid = currentUserUID {
//                        let userDocument = userCollection.document(uid) // uidはドキュメントID
//
//                        userDocument.setData([
//                            "name": name,
//                            "email": email
//                        ]) { error in
//                            if let error = error {
//                                // 失敗した場合
//                                print("Firestore 新規登録失敗 " + error.localizedDescription)
//                            } else {
//                                // 成功した場合
//                                print("Firestore 新規登録成功")
//
//                                // 以下の画面遷移コードをここに配置
//                            }
//                        }


//                    self.db.collection("user").document((authResult?.user.uid)!).setData([
//                        "name": name,
//                        "email": email
//                    ],completion: { error in
//                        if let error = error {
//                            // 失敗した場合
//                            print("Firestore 新規登録失敗 " + error.localizedDescription)
//                        } else {
//
//                            print("ログイン完了 name:" + name)
//                            // 成功した場合はRegisterViewに画面遷移を行う
//                            let storyboard: UIStoryboard = self.storyboard!
//                            let next = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
//                            self.present(next, animated: true, completion: nil)
//                        }
//
//                    }
//
//
//                    ) }
//




private func login(credential: AuthCredential) {
    print("ログイン完了",credential)
    let storyboard: UIStoryboard = self.storyboard!
    let next = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
    self.present(next, animated: true, completion: nil)
}


}

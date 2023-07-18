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
            let storyboard: UIStoryboard = self.storyboard!
            let next = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
            self.present(next, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func didTapSignInButton(_ sender: Any) {
        auth()
    }
    
    private func auth() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            if let error = error {
                print("GIDSignInError: \(error.localizedDescription)")
                return
            }
            
            guard let authentication = signInResult?.user,
                  let idToken = authentication.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken.tokenString)
            
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if  let user = signInResult?.user {
                    let name = user.profile!.name
                    let email = user.profile!.email
                    
                    Firestore.firestore().collection("user").document((authResult?.user.uid)!).setData([
                        "name": name,
                        "email": email
                    ],completion: { error in
                        if let error = error {
                            // ②が失敗した場合
                            print("Firestore 新規登録失敗 " + error.localizedDescription)
                            //                        let dialog = UIAlertController(title: "新規登録失敗", message: error.localizedDescription, preferredStyle: .alert)
                            //                        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            //                        self.present(dialog, animated: true, completion: nil)
                        } else {
                            print("ログイン完了 name:" + name)
                            // ③成功した場合はRegisterViewに画面遷移を行う
                            let storyboard: UIStoryboard = self.storyboard!
                            let next = storyboard.instantiateViewController(withIdentifier: "RegisterView")
                            self.present(next, animated: true, completion: nil)
                        }
            
                    }
                                                                                                       
                                                                                                       
                    ) }
                
                
                
                
                self.login(credential: credential)
                
            }
        }
    }
    private func login(credential: AuthCredential) {
        print("ログイン完了",credential)
        let storyboard: UIStoryboard = self.storyboard!
        let next = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
        self.present(next, animated: true, completion: nil)
    }
    
    
}

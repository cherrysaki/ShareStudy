//
//  LoadingView.swift
//  ShareStudy
//
//  Created by 神林沙希 on 13/8/23.
//

import UIKit

extension UIView {
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



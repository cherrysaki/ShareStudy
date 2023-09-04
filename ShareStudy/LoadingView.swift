//
//  LoadingView.swift
//  ShareStudy
//
//  Created by 神林沙希 on 3/9/23.
//

import UIKit

class LoadingView: UIView {
    private let activityIndicator = UIActivityIndicatorView()
    private let label = UILabel()

    init() {
        super.init(frame: UIScreen.main.bounds)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)

        activityIndicator.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        activityIndicator.center = center
        activityIndicator.color = .white
        activityIndicator.style = .large
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        addSubview(activityIndicator)

        label.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        label.center = CGPoint(x: activityIndicator.frame.origin.x + activityIndicator.frame.size.width / 2, y: activityIndicator.frame.origin.y + 90)
        label.textColor = .white
        label.textAlignment = .center
        addSubview(label)
    }

    func setMessage(_ message: String) {
        label.text = message
    }
}


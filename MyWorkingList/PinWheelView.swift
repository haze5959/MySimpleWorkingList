//
//  PinWheelView.swift
//  PinWheelView
//
//  Created by Isuru Nanayakkara on 1/14/15.
//  Copyright (c) 2015 Appex. All rights reserved.
//

import UIKit

open class PinWheelView {
    
    var containerView = UIView()
    var progressView = UIView()
    var labelView = UILabel()
    var activityIndicator = UIActivityIndicatorView()
    
    open class var shared: PinWheelView {
        struct Static {
            static let instance: PinWheelView = PinWheelView()
        }
        return Static.instance
    }
    
    open func showProgressView(_ view: UIView) {
        containerView.frame = view.frame
        containerView.center = view.center
        containerView.backgroundColor = UIColor(hex: 0x000000, alpha: 0.3)
        
        progressView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        progressView.center = view.center
        progressView.backgroundColor = UIColor(hex: 0x444444, alpha: 0.7)
        progressView.clipsToBounds = true
        progressView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.center = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
        
        labelView.text = "iCloud data load...";
        labelView.frame = CGRect(x: view.frame.size.width/2 - 100, y: progressView.frame.origin.y + 85, width: 200, height: 20)
        labelView.textAlignment = .center;
        
        progressView.addSubview(activityIndicator)
        containerView.addSubview(progressView)
        containerView.addSubview(labelView)
        view.addSubview(containerView)
        
        activityIndicator.startAnimating()
    }
    
    open func hideProgressView() {
        activityIndicator.stopAnimating()
        containerView.removeFromSuperview()
    }
}

extension UIColor {
    
    convenience init(hex: UInt32, alpha: CGFloat) {
        let red = CGFloat((hex & 0xFF0000) >> 16)/256.0
        let green = CGFloat((hex & 0xFF00) >> 8)/256.0
        let blue = CGFloat(hex & 0xFF)/256.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

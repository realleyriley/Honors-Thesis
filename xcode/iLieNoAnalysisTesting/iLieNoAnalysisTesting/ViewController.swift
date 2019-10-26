//
//  ViewController.swift
//  iLieTesting
//
//  Created by Communist Hacker on 10/2/19.
//  Copyright © 2019 Tallman. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let url = URL(string: "https://google.com")
        let request = URLRequest(url: url!)
        webView.load(request)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portraitUpsideDown
    }
    
    // does not support upsidedown by default
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        get{
            return .all
        }
    }
}


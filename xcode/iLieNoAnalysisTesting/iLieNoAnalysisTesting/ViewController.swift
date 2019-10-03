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
        let url = URL(string: "https://www.eia.gov/tools/faqs/faq.php?id=427&t=3")
        let request = URLRequest(url: url!)
        webView.load(request)
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
}


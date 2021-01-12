//
//  ViewController.swift
//  LJBannerViewDemo
//
//  Created by 唐星宇 on 2021/1/12.
//

import UIKit

class ViewController: UIViewController, LJBannerViewDelegate {

    var bannerView: LJBannerView = LJBannerView()
    
    var bannerViewReuseIdentifier: String = "bannerView"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        bannerView.delegate = self
        bannerView.frame = CGRect(x: (view.frame.width - 345)/2 , y: (view.frame.height - 195)/2, width: 345, height: 195)
        bannerView.registView(UIImageView.self, forViewWithReuseIdentifier: bannerViewReuseIdentifier)
        bannerView.showIndicator = true
        bannerView.startRollingLoop(withTimeInterval: 2)
        view.addSubview(bannerView)
    }
    
    
    func bannerView(_ bannerView: LJBannerView, viewAt index: Int) -> UIView {
        let view = bannerView.dequeueView(withReuseIdentifier: bannerViewReuseIdentifier) as! UIImageView
        view.image = UIImage(named: "img\(index + 1)")
        return view
    }
    
    func bannerView(numberOfViewsIn bannerView: LJBannerView) -> Int {
        return 5
    }


}


//
//  LJBannerView.swift
//
//
//  Created by 唐星宇 on 2021/1/5.
//  Copyright © 2021 唐星宇. All rights reserved.
//

import UIKit

protocol LJBannerViewDelegate {
    
    func bannerView(_ bannerView: LJBannerView, didSelectItemAt index: Int)
    
    func bannerView(_ bannerView: LJBannerView, viewAt index: Int) -> UIView
    
    func bannerView(numberOfViewsIn bannerView: LJBannerView) -> Int
    
}

extension LJBannerViewDelegate{
    func bannerView(_ bannerView: LJBannerView, didSelectItemAt index: Int){
        
    }
}

class LJBannerCell: UICollectionViewCell{
    
    override func prepareForReuse() {
        super.prepareForReuse()
        for view in self.contentView.subviews {
            view.removeFromSuperview()
        }
    }
    
}

class LJBannerView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    enum LJBannerViewError: Error{
        case Error (String)
    }
    
    var delegate: LJBannerViewDelegate?{
        didSet{
            if delegate != nil{
                reloadData()
            }
        }
    }
    
    private var rollingTimer: Timer?
    
    private var collectionView: UICollectionView!
    
    private var currentPage: Int = 0
    
    private var indicatorV: UIPageControl = UIPageControl()
    
    private var flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    
    var showIndicator: Bool = false{
        didSet{
            indicatorV.isHidden = !showIndicator || dataCount <= 1
        }
    }
    
    var pageIndicatorTintColor: UIColor = .lightGray
    
    var currentPageIndicatorTintColor: UIColor = .darkGray
    
    var reuseQueues: [String: [UIView]] = [:]
    
    var dataCount: Int = 0
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    init(frame: CGRect = .zero, scrollDirection: UICollectionView.ScrollDirection = .horizontal) {
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = scrollDirection
        flowLayout.estimatedItemSize = frame.size
        
        super.init(frame: frame)
        collectionView = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
        addObserver(self, forKeyPath: "frame", options: [.old, .new], context: nil)
        indicatorV.addTarget(self, action: #selector(pageChange), for: .valueChanged)
        collectionView.register(LJBannerCell.self , forCellWithReuseIdentifier: "bannerCell")
        self.addSubview(collectionView)
        self.addSubview(indicatorV)
        setupUI()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("初始化失败")
    }
    
    deinit {
        rollingTimer?.invalidate()
        self.removeObserver(self, forKeyPath: "frame")
    }
    
    private func setupUI(){
        collectionView.frame = self.bounds
        collectionView.contentOffset = flowLayout.scrollDirection == .horizontal ? CGPoint(x: self.frame.width, y: 0) : CGPoint(x: 0, y: self.frame.height)
        indicatorV.frame = CGRect(x: 0, y: self.frame.height - 20, width: self.frame.width, height: 20)
        for queue in reuseQueues.values{
            for view in queue{
                view.frame = self.bounds
            }
        }
    }
    
    func reloadData(){
        if let delegate = delegate {
            dataCount = delegate.bannerView(numberOfViewsIn: self)
            collectionView.isScrollEnabled = dataCount > 1
            indicatorV.isHidden = !showIndicator || dataCount <= 1
            indicatorV.numberOfPages = dataCount
            indicatorV.pageIndicatorTintColor = pageIndicatorTintColor
            indicatorV.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        }
        collectionView.reloadData()
    }
    
    func registView(_ viewClass: AnyClass?, forViewWithReuseIdentifier identifier: String){
        var arr:[UIView] = []
        
        for _ in 0..<4{
            let view = UIView(frame: self.bounds)
            arr.append(view)
        }
        
        if let viewClass = viewClass as? UIView.Type{
            arr.removeAll()
            for _ in 0..<4{
                let view = viewClass.init(frame: self.bounds)
                arr.append(view)
            }
        }
        
        reuseQueues.updateValue(arr, forKey: identifier)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let object = object as? NSObject{
            if object == self{
                if keyPath == "frame"{
                    setupUI()
                }
            }
        }
    }
    
    override func layoutSubviews() {
        setupUI()
        super.layoutSubviews()
    }
    
    
    func dequeueView(withReuseIdentifier identifier: String) -> UIView{
        
        guard let reuseQueue = reuseQueues[identifier] else {
            fatalError("找不到identifier")
        }
        
        for view in reuseQueue {
            if view.superview == nil{
                return view
            }
        }
        return reuseQueue[0]
        
    }
    
    @objc func pageChange(){
        currentPage = indicatorV.currentPage + 1
        collectionView.scrollToItem(at: IndexPath(item: indicatorV.currentPage + 1, section: 0), at: .left, animated: true)
    }
    
    func stopRollingLoop(){
        rollingTimer?.invalidate()
    }
    
    func startRollingLoop(withTimeInterval timeInterval: TimeInterval, scrollPosition: UICollectionView.ScrollPosition = .left){
        guard dataCount > 1 else {
            return
        }
        rollingTimer?.invalidate()
        rollingTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: {[weak self] (timer) in
            if let weakSelf = self{
                if scrollPosition == .left || scrollPosition == .top{
                    weakSelf.collectionView.scrollToItem(at: IndexPath(item: weakSelf.currentPage + 1, section: 0), at: weakSelf.flowLayout.scrollDirection == .horizontal ? .left : .top, animated: true)
                }else{
                    weakSelf.collectionView.scrollToItem(at: IndexPath(item: weakSelf.currentPage - 1, section: 0), at: scrollPosition, animated: true)
                }
            }
        })
    }
    
    //MARK: collectionView 相关代理

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataCount + 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bannerCell", for: indexPath)
        
        guard let delegate = delegate else {
            return cell
        }
        
        var index = 0
        if indexPath.item == 0{
            index = dataCount - 1
        }else if indexPath.item == dataCount + 1{
            index = 0
        }else{
            index = indexPath.item - 1
        }
        let view = delegate.bannerView(self, viewAt: index)
        cell.contentView.addSubview(view)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let delegate = delegate else {
            return
        }
        if indexPath.item == 0{
            delegate.bannerView(self, didSelectItemAt: dataCount - 1)
        }else if indexPath.item == dataCount + 1{
            delegate.bannerView(self, didSelectItemAt: 0)
        }else{
            delegate.bannerView(self, didSelectItemAt: indexPath.item - 1)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = flowLayout.scrollDirection == .horizontal ? Int(scrollView.contentOffset.x / self.frame.width) : Int(scrollView.contentOffset.y / self.frame.height)
        if index == 0{
            indicatorV.currentPage = dataCount - 1
        }else if index == dataCount + 1{
            indicatorV.currentPage = 0
        }else{
            indicatorV.currentPage = index - 1
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        let index = flowLayout.scrollDirection == .horizontal ? Int(scrollView.contentOffset.x / self.frame.width) : Int(scrollView.contentOffset.y / self.frame.height)
        if index == 0{
            indicatorV.currentPage = dataCount - 1
        }else if index == dataCount + 1{
            indicatorV.currentPage = 0
        }else{
            indicatorV.currentPage = index - 1
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        switch flowLayout.scrollDirection {
        case .horizontal:
            if scrollView.contentOffset.x == 0{
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x + (self.frame.width * CGFloat(dataCount)), y: 0)
            }else if scrollView.contentOffset.x == CGFloat(dataCount + 1) * self.frame.width{
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x - (self.frame.width * CGFloat(dataCount)), y: 0)
            }
            currentPage = Int(scrollView.contentOffset.x / self.frame.width)
        case .vertical:
            if scrollView.contentOffset.y == 0{
                scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y + (self.frame.height * CGFloat(dataCount)))
            }else if scrollView.contentOffset.y == CGFloat(dataCount + 1) * self.frame.height{
                scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y - (self.frame.height * CGFloat(dataCount)))
            }
            currentPage = Int(scrollView.contentOffset.y / self.frame.height)
        default:
            break
        }
        
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        switch flowLayout.scrollDirection {
        case .horizontal:
            let roundIndex = Int(roundf(Float(scrollView.contentOffset.x/self.frame.width)))
            if roundIndex == 0{
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x + self.frame.width * CGFloat(dataCount), y: 0)
            }else if roundIndex == dataCount + 1{
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x - self.frame.width * CGFloat(dataCount), y: 0)
            }
        case .vertical:
            let roundIndex = Int(roundf(Float(scrollView.contentOffset.y/self.frame.height)))
            if roundIndex == 0{
                scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y + self.frame.height * CGFloat(dataCount))
            }else if roundIndex == dataCount + 1{
                scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.x - self.frame.height * CGFloat(dataCount))
            }
        default:
            break
        }
        
    }

}

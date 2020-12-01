//
//  SYAutoScrollBanner.swift
//  aeonjftest
//
//  Created by XiaShiyang on 2018/5/15.
//  Copyright © 2018年 wangjin. All rights reserved.
//

import UIKit
import Kingfisher

protocol SYAutoScrollBannerDelegate: class {       // 轮播图点击代理
    
    func scrollBannerDidSelectIndex(index: Int)
}

fileprivate class SYimageViewCell: UICollectionViewCell {
    
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        let layoutLeft = NSLayoutConstraint.init(item: imageView, attribute:NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0.0)
        
        let layoutRight = NSLayoutConstraint.init(item: imageView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0.0)
        
        let layoutTop = NSLayoutConstraint.init(item: imageView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0)
        
        let layoutBottom = NSLayoutConstraint.init(item: imageView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0)
        
        contentView.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SYAutoScrollBanner: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let ReuseId = "ReuseId"
    let PageReuseId = "PageReuseId"
    
    private var pageControll: UICollectionView      // 导航点
    // 导航点相关
    private var pageSize: CGFloat
    private var pageSpace: CGFloat
    private var currentPageWidth: CGFloat
    private var pageColor: UIColor
    private var currentPageColor: UIColor
    
    private var scrollBanner: UICollectionView      // 轮播图
    
    var placeholderImage: UIImage?          // 占位图
    
    weak var delegate: SYAutoScrollBannerDelegate?   // 轮播图点击代理
    
    private var scrollSource: [String] = [] {           // 数据源
        
        didSet {
            
            if scrollSource.count > 1 {
                
                let firstObject = scrollSource.first!
                let lastObject = scrollSource.last!
                
                self.scrollSource.insert(lastObject, at: 0)
                self.scrollSource.append(firstObject)
            }
        }
    }
    
    private var currentItemIndex: Int {         // 当前scrollBanner逻辑上所在Item
        
        get {
            let width = self.frame.size.width
            
            if width <= 0.0 { return 0 }
            
            let offset = self.scrollBanner.contentOffset.x
            
            let index = Int(offset / width)
            
            return (index >= self.scrollSource.count - 1) ? 0 : index     // 解决collectionView调用reloadData方法后contentOffset不刷新bug
        }
    }
    
    private var currentPage = 0                 // 当前轮播图宏观上第几页（从0页开始）
    
    private var timer: Timer?                   // 计时器
    
    private var timeInterval: TimeInterval    // 计时间隔
    
    private var pageLayoutWidth: NSLayoutConstraint!    // 导航点的总宽度约束
    
    init(frame: CGRect = CGRect.zero, timeInterval: TimeInterval = 3.0, pageSize: CGFloat = 6.0, pageSpace: CGFloat = 6.0, currentPageWidth: CGFloat = 14.0, pageColor: UIColor = .lightGray, currentPageColor: UIColor = .red, placeholderImage: UIImage? = nil) {
        
        self.timeInterval = timeInterval
        self.pageSize = pageSize
        self.pageSpace = pageSpace
        self.currentPageWidth = currentPageWidth
        self.pageColor = pageColor
        self.currentPageColor = currentPageColor
        self.placeholderImage = placeholderImage
        
        // 轮播图
        let bannerLayout = UICollectionViewFlowLayout()
        bannerLayout.scrollDirection = .horizontal
        bannerLayout.minimumLineSpacing = 0.0
        bannerLayout.minimumInteritemSpacing = 0.0
        
        self.scrollBanner = UICollectionView(frame: frame, collectionViewLayout: bannerLayout)
        self.scrollBanner.translatesAutoresizingMaskIntoConstraints = false
        self.scrollBanner.backgroundColor = .white
        self.scrollBanner.isPagingEnabled = true
        self.scrollBanner.showsVerticalScrollIndicator = false
        self.scrollBanner.showsHorizontalScrollIndicator = false
        self.scrollBanner.scrollsToTop = false
        self.scrollBanner.register(SYimageViewCell.self, forCellWithReuseIdentifier: ReuseId)
        
        // 导航点
        let pageLayout = UICollectionViewFlowLayout()
        pageLayout.scrollDirection = .horizontal
        pageLayout.minimumLineSpacing = 0.0
        pageLayout.minimumInteritemSpacing = pageSpace
        
        self.pageControll = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: pageLayout)
        self.pageControll.translatesAutoresizingMaskIntoConstraints = false
        self.pageControll.backgroundColor = .clear
        self.pageControll.isScrollEnabled = false
        self.pageControll.showsHorizontalScrollIndicator = false
        self.pageControll.showsVerticalScrollIndicator = false
        self.pageControll.scrollsToTop = false
        self.pageControll.isHidden = true
        self.pageControll.register(SYimageViewCell.self, forCellWithReuseIdentifier: PageReuseId)
        
        super.init(frame: frame)
        
        self.scrollBanner.delegate = self
        self.scrollBanner.dataSource = self
        self.addSubview(self.scrollBanner)
        
        let layoutLeft = NSLayoutConstraint.init(item: self.scrollBanner, attribute:NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0.0)
        let layoutRight = NSLayoutConstraint.init(item: self.scrollBanner, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0.0)
        let layoutTop = NSLayoutConstraint.init(item: self.scrollBanner, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0)
        let layoutBottom = NSLayoutConstraint.init(item: self.scrollBanner, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0)
        
        self.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])
        
        self.pageControll.delegate = self
        self.pageControll.dataSource = self
        self.addSubview(self.pageControll)
        
        let pageLayoutBottom = NSLayoutConstraint.init(item: self.pageControll, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: -5.0)
        let pageLayoutHeight = NSLayoutConstraint.init(item: self.pageControll, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: pageSize)
        let pageLayoutCentreX = NSLayoutConstraint.init(item: self.pageControll, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        self.pageLayoutWidth = NSLayoutConstraint.init(item: self.pageControll, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: pageSize)
        
        self.addConstraints([pageLayoutBottom, pageLayoutHeight, pageLayoutCentreX, self.pageLayoutWidth])
    }
    
    // 销毁timer
    private func deinitTimer() {
        
        timer?.invalidate()
        timer = nil
    }
    
    // 创建timer
    private func initTimer() {
        
        deinitTimer()
        
        timer = Timer.init(timeInterval: self.timeInterval, target: self, selector: #selector(autoScroll), userInfo: nil, repeats: true)
        timer?.tolerance = 0.1 * self.timeInterval
        
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    // 自动轮播
    @objc private func autoScroll() {
        
        self.scrollBanner.scrollToItem(at: IndexPath.init(item: self.currentItemIndex + 1, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    // 计算轮播图当前宏观上第几页
    private func adjustCurrentWithContentOffset(_ contentOffset: CGPoint) {
        
        let adjustPoint = CGPoint(x: contentOffset.x + 0.5 * frame.size.width, y: contentOffset.y)
        
        let indexPath = self.scrollBanner.indexPathForItem(at: adjustPoint)
        
        let currentPage = self.pageWithIndexPath(indexPath!)
        
        if self.currentPage == currentPage {
            
            return
        }
        
        self.currentPage = currentPage
        
        self.pageControll.reloadData()  // 更新导航点
    }
    
    private func pageWithIndexPath(_ indexPath: IndexPath) -> Int {
        
        let index = indexPath.item
        let prefixIndex = 0
        let suffixIndex = self.scrollSource.count - 1
        let firstPage = 0
        let lastPage = suffixIndex - 2
        
        if index == prefixIndex {
            
            return lastPage
            
        }else if index == suffixIndex {
            
            return firstPage
            
        }else {
            
            return index - 1
        }
    }
    
    // 更新轮播图
    func setScrollSource(_ scrollSource: [String]?) {
        
        deinitTimer()   // 暂停定时器
        
        if let source = scrollSource, source.count > 0 {
            
            self.scrollSource = source
            
            var count = self.scrollSource.count - 2
            if count < 0 { count = 1 }  // 处理轮播图只有一张时候的导航点宽度
            let width = (pageSize + pageSpace) * CGFloat(count - 1) + currentPageWidth
            
            self.removeConstraint(self.pageLayoutWidth)
            
            self.pageLayoutWidth = NSLayoutConstraint.init(item: self.pageControll, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: width)
            
            self.addConstraint(self.pageLayoutWidth)
            
            self.setNeedsLayout()
            self.layoutIfNeeded()
            
            self.pageControll.reloadData()
            self.scrollBanner.reloadData()
            
//            print("originalX: \(scrollBanner.contentOffset.x)")
            
            if self.scrollSource.count > 1 {
                
                // 轮播图大于一张时，可以滑动，显示导航点
                if self.currentItemIndex == 0 { // 如果当前为逻辑上的第0页，主动跳到宏观上的第0页

                    self.scrollBanner.scrollToItem(at: IndexPath.init(item: 1, section: 0), at: .centeredHorizontally, animated: false)
                }
                
                self.adjustCurrentWithContentOffset(self.scrollBanner.contentOffset)
                
                self.pageControll.isHidden = false
                
                initTimer() // 开启定时器
                
            }else {
                
                // 轮播图只有一张时，不可滑动，隐藏导航点
                self.currentPage = 0
                
                self.pageControll.isHidden = true
            }
            
        }else {
            
            // 清空数据源
            self.scrollSource.removeAll()
            
            self.currentPage = 0
            
            self.scrollBanner.reloadData()
            
            self.pageControll.reloadData()
            
            self.pageControll.isHidden = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SYAutoScrollBanner {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sourceCount = scrollSource.count
        
        if collectionView == self.pageControll {
            
            return sourceCount <= 1 ? sourceCount : (sourceCount - 2)
            
        }else {
            
            return sourceCount == 0 ? 1 : sourceCount   // 如果没有轮播图，留一张显示占位图
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == self.pageControll {
            
            if self.currentPage == indexPath.row {
                
                return CGSize(width: currentPageWidth, height: pageSize)    // 当前导航点大小
                
            }else {
                
                return CGSize(width: pageSize, height: pageSize)    // 其它导航点大小
            }
            
        }else {
            
            return frame.size   // 轮播图大小
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.pageControll {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageReuseId, for: indexPath) as! SYimageViewCell
            
            return cell
            
        }else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseId, for: indexPath) as! SYimageViewCell
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let displayCell = cell as! SYimageViewCell
        
        if collectionView == self.pageControll {
            
            displayCell.imageView.layer.cornerRadius = pageSize / 2.0
            
            if self.currentPage == indexPath.row {
                
                displayCell.imageView.backgroundColor = self.currentPageColor   // 当前导航点颜色
                
            }else {
                
                displayCell.imageView.backgroundColor = self.pageColor      // 其它导航点颜色
            }
            
        }else {
            
            if scrollSource.count == 0 {
                
                displayCell.imageView.image = self.placeholderImage // 如果没有轮播图，显示占位图
                
            }else {
                
                let imageName = scrollSource[indexPath.row]
                
                if imageName.hasPrefix("http") {
                    
                    // 网络图片
                    displayCell.imageView.kf.setImage(with: URL(string: imageName), placeholder: self.placeholderImage)
                    
                }else {
                    
                    // 本地图片
                    displayCell.imageView.image = UIImage.init(named: imageName)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == self.scrollBanner && self.scrollSource.count > 0 { // 默认只有轮播图可以点击
            
            self.delegate?.scrollBannerDidSelectIndex(index: self.currentPage)
        }
    }
}

extension SYAutoScrollBanner {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        //        print("scrollViewWillBeginDragging")
        
        if scrollView == self.scrollBanner {
            
            deinitTimer()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        //        print("scrollViewDidEndDragging")
        
        if scrollView == self.scrollBanner {
            
            initTimer()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
//        print("scrollViewDidScroll: \(scrollView.contentOffset.x)")
        
        if scrollView == self.scrollBanner && self.scrollSource.count > 1 {     // 增加数据源个数判断，解决collectionView调用reloadData方法时，可能会调用scrollViewDidScroll方法的bug
            
            self.adjustCurrentWithContentOffset(scrollView.contentOffset)
            
            if scrollView.contentOffset.x <= 0 {
                
                let indexPath = IndexPath.init(item: self.scrollSource.count - 2, section: 0)
                
                self.scrollBanner.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                
            }else if scrollView.contentOffset.x >= CGFloat(self.scrollSource.count - 1) * frame.size.width {
                
                self.scrollBanner.scrollToItem(at: IndexPath.init(item: 1, section: 0), at: .centeredHorizontally, animated: false)
            }
        }
    }
}



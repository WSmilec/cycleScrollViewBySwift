//
//  WSCycleScrollView.swift
//  SDCycleScrollViewBySwift
//
//  Created by WangS on 17/3/13.
//  Copyright © 2017年 WangS. All rights reserved.
//

import UIKit


enum SDCycleScrollViewPageContolAliment {
    case SDCycleScrollViewPageContolAlimentRight
    case SDCycleScrollViewPageContolAlimentCenter
}
enum SDCycleScrollViewPageContolStyle {
    case SDCycleScrollViewPageContolStyleClassic  // 系统自带经典样式
    case SDCycleScrollViewPageContolStyleAnimated // 动画效果pagecontrol
    case SDCycleScrollViewPageContolStyleNone     // 不显示pagecontrol
}
@objc protocol WSCycleScrollViewDelegate {
    /** 点击图片回调 */
    @objc optional func cycleScrollViewDidSelectItemAtIndex(cycleScrollView:WSCycleScrollView,index:NSInteger)
    /** 图片滚动回调 */
    @objc optional func cycleScrollViewDidScrollToIndex(cycleScrollView:WSCycleScrollView,index:NSInteger)
}

class WSCycleScrollView: UIView,UICollectionViewDelegate,UICollectionViewDataSource {
    //////////////////////  数据源接口  //////////////////////
    var imageURLStringsGroup:Array<Any>? {
        didSet{
            print("11111111")
            self.imagePathsGroup = imageURLStringsGroup
        }
    }/** 网络图片 url string 数组 */
    var titlesGroup:Array<Any>?/** 每张图片对应要显示的文字数组 */
    var localizationImageNamesGroup:Array<Any>? {
        didSet{
            /*
             self.imagePathsGroup = [localizationImageNamesGroup copy];
             
             */
        }
    }/** 本地图片数组 */
    
    //////////////////////  滚动控制接口 //////////////////////
    var autoScrollTimeInterval:CGFloat = 2

    weak var delegate:WSCycleScrollViewDelegate?
    var clickItemOperationBlock:((_ currentIndex: NSInteger)->())? /** block方式监听点击 */
    var itemDidScrollOperationBlock:((_ currentIndex:NSInteger)->())?/** block方式监听滚动 */
    //////////////////////  自定义样式接口  //////////////////////
    /** 轮播图片的ContentMode，默认为 UIViewContentModeScaleToFill */
    var bannerImageViewContentMode: UIViewContentMode = .scaleToFill
    /** 占位图，用于网络未加载到图片时 */
    var placeholderImage: UIImage?{
        didSet{
            if self.backgroundImageView == nil {
                let bgImageView = UIImageView.init()
                bgImageView.contentMode = UIViewContentMode.scaleAspectFit
                self.insertSubview(bgImageView, belowSubview: self.mainView!)
                self.backgroundImageView = bgImageView
            }
            self.backgroundImageView?.image = placeholderImage;
        }
    }
    /** 是否显示分页控件 */
    var showPageControl: Bool?{
        didSet{
            self.pageControl?.isHidden = !showPageControl!
        }
    }
    /** 是否在只有一张图时隐藏pagecontrol，默认为YES */
    var hidesForSinglePage: Bool = true
    /** 只展示文字轮播 */
    /** pagecontrol 样式，默认为动画样式 */
    var pageControlStyle: SDCycleScrollViewPageContolStyle?{
        didSet{
            setupPageControl()
        }
    }
    /** 分页控件位置 */
    var pageControlAliment: SDCycleScrollViewPageContolAliment?
 
    //////////////////////  清除缓存接口  //////////////////////
    class func clearImagesCache()  {
        
    }
    //////////////////////  私有属性  //////////////////////
    private weak var mainView: UICollectionView?//显示图片的collectionView
    private weak var flowLayout: UICollectionViewFlowLayout?
    private var imagePathsGroup: Array<Any>?{
        didSet{
            invalidateTimer()
            self.totalItemsCount = (self.imagePathsGroup?.count)! * 100
            if imagePathsGroup?.count != 1 {
                self.mainView?.isScrollEnabled = true
                setupTimer()
            }else{
                self.mainView?.isScrollEnabled = false
            }
            setupPageControl()
            self.mainView?.reloadData()
        }
    }
    private weak var timer: Timer?
    private var totalItemsCount: NSInteger?
    private weak var pageControl: UIControl?
    private var backgroundImageView: UIImageView?// 当imageURLs为空时的背景图
    private let kCycleScrollViewInitialPageControlDotSize:CGSize = CGSize(width: 10, height: 10)
    
    /** 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法 */
    class func adjustWhenControllerViewWillAppera()  {
        
    }
    /** 初始轮播图 */
    class func cycleScrollViewWithFrame(frame:CGRect,delegate:WSCycleScrollViewDelegate,placeholderImage:UIImage) -> WSCycleScrollView{
        let cycleScrollView = WSCycleScrollView.init(frame: frame)
        cycleScrollView.delegate = delegate
        cycleScrollView.placeholderImage = placeholderImage
        return cycleScrollView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
        setupMainView()
    }
    
    
    func initialization()  {
        self.pageControlAliment = .SDCycleScrollViewPageContolAlimentCenter
        self.autoScrollTimeInterval = 2.0
        self.showPageControl = true
        self.pageControlStyle = SDCycleScrollViewPageContolStyle.SDCycleScrollViewPageContolStyleClassic
        self.hidesForSinglePage = true
        self.bannerImageViewContentMode = UIViewContentMode.scaleToFill
        self.backgroundColor = UIColor.lightGray
    }
    func setupMainView()  {
        
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
        self.flowLayout = flowLayout
        
        let mainView = UICollectionView.init(frame: self.bounds, collectionViewLayout: flowLayout)
        mainView.backgroundColor = UIColor.clear
        mainView.isPagingEnabled = true
        mainView.showsVerticalScrollIndicator = false
        mainView.showsHorizontalScrollIndicator = false
        mainView.register(WSCollectionViewCell.self, forCellWithReuseIdentifier: "cycleCell")
        mainView.dataSource = self
        mainView.delegate = self
        mainView.scrollsToTop = false
        self.addSubview(mainView)
        self.mainView = mainView
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.totalItemsCount!
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: WSCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cycleCell", for: indexPath) as! WSCollectionViewCell
        let itemIndex = pageControlIndexWithCurrentCellIndex(index: indexPath.item)
        let imagePath = self.imagePathsGroup?[itemIndex]
        if (imagePath is String) {
            if (imagePath as! String).hasPrefix("http") {
                cell.imageView?.sd_setImage(with: NSURL(string:(imagePath as! String)) as URL?, placeholderImage: self.placeholderImage!)
            }else{
                let image = UIImage.init(named: imagePath as! String)
                cell.imageView?.image = image
            }
        }
       
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.cycleScrollViewDidSelectItemAtIndex!(cycleScrollView: self, index: indexPath.item)
        
        if ((self.clickItemOperationBlock) != nil) {
            let item = pageControlIndexWithCurrentCellIndex(index: indexPath.item)
            self.clickItemOperationBlock!(item)
        }
    }
    //pragma mark - actions
    func setupTimer()  {
        let timer:Timer = Timer.scheduledTimer(timeInterval: 2.0, target:self, selector: #selector(automaticScroll), userInfo: nil, repeats: true)
        self.timer = timer
        RunLoop.current.add(timer, forMode:.commonModes)
    }
    func invalidateTimer()  {
        self.timer?.invalidate()
        self.timer = nil
    }
    func setupPageControl()  {
        if (self.pageControl != nil) {
            self.pageControl?.removeFromSuperview()// 重新加载数据时调整
        }
        print("setupPageControl----\(self.imagePathsGroup?.count as Any)")
        if self.imagePathsGroup == nil{
            return
        }
        if self.imagePathsGroup?.count == 0  {
            return
        }
        if self.imagePathsGroup?.count == 1 && self.hidesForSinglePage == true {
            return
        }
        let currentIndex = self.currentIndex()
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index:currentIndex)
        if self.pageControlStyle == .SDCycleScrollViewPageContolStyleAnimated {
            let pageControl = TAPageControl.init()
            pageControl.numberOfPages = (self.imagePathsGroup?.count)!;
            pageControl.isUserInteractionEnabled = false;
            pageControl.currentPage = indexOnPageControl;
            self.addSubview(pageControl)
        }else if self.pageControlStyle == .SDCycleScrollViewPageContolStyleClassic {
            let pageControl = UIPageControl.init()
            pageControl.numberOfPages = (self.imagePathsGroup?.count)!;
            pageControl.isUserInteractionEnabled = false;
            pageControl.currentPage = indexOnPageControl;
            self.addSubview(pageControl)
            self.pageControl = pageControl
        }
    }
    func automaticScroll()  {
        if 0 == self.totalItemsCount {
            return
        }
        let curtIndex = currentIndex()
        let targetIndex = curtIndex + 1
        scrollToIndex(targetIndex: targetIndex)
    }
    func scrollToIndex(targetIndex:NSInteger)  {
        if targetIndex >= self.totalItemsCount! {
                let targetIndexVar = NSInteger(self.totalItemsCount! / 2)
                self.mainView?.scrollToItem(at: NSIndexPath.init(item: targetIndexVar, section: 0) as IndexPath, at: .centeredHorizontally, animated: false)
                return
        }
        
            self.mainView?.scrollToItem(at: NSIndexPath.init(item: targetIndex, section: 0) as IndexPath, at: .centeredHorizontally, animated: true)
    }
    func currentIndex() ->(NSInteger) {
        if self.mainView?.frame.size.width == 0 || self.mainView?.frame.size.height == 0 {
            return 0
        }
        var index:NSInteger = 0
        if self.flowLayout?.scrollDirection == UICollectionViewScrollDirection.horizontal {
            index = NSInteger(((self.mainView?.contentOffset.x)! + (self.flowLayout?.itemSize.width)! / 2) / (self.flowLayout?.itemSize.width)!)
        }else{
            index = NSInteger(((self.mainView?.contentOffset.y)! + (self.flowLayout?.itemSize.height)! / 2) / (self.flowLayout?.itemSize.height)!)
        }
        return max(0, index)
    }
    func pageControlIndexWithCurrentCellIndex(index:NSInteger) ->(NSInteger) {
        return (index % self.imagePathsGroup!.count);
    }
    func clearImagesCache()  {
        SDWebImageManager.shared().imageCache?.clearDisk(onCompletion: {
            
        })
    }
    //pragma mark - life circles
    override func layoutSubviews() {
        super.layoutSubviews()
        self.flowLayout?.itemSize = self.frame.size
        self.mainView?.frame = self.bounds
        if self.mainView?.contentOffset.x == 0 && (self.totalItemsCount != nil) {
            var targetIndex = 0
//            if self.infiniteLoop {
                targetIndex = self.totalItemsCount! / 2
//            }else{
//                targetIndex = 0
//            }
            self.mainView?.scrollToItem(at: NSIndexPath.init(item: targetIndex, section: 0) as IndexPath, at: .centeredHorizontally, animated: false)
        }
        var size = CGSize(width: 0, height: 0)
        if self.pageControl is TAPageControl {
            let pageControl = self.pageControl as! TAPageControl
            size = pageControl.sizeForNumber(ofPages: (self.imagePathsGroup?.count)!)
        }else{
//            let count:CGFloat = CGFloat((self.imagePathsGroup?.count)!)
//            size = CGSize(width: count * (self.pageControlDotSize?.width)! * 1.5, height: (self.pageControlDotSize?.height)!)
        }
        var x = (self.frame.size.width - size.width) * 0.5
        if self.pageControlAliment == .SDCycleScrollViewPageContolAlimentRight {
            x = (self.mainView?.frame.size.width)! - size.width;
        }
        let y = (self.mainView?.frame.size.height)! - size.height
        if self.pageControl is  TAPageControl{
            let pageControl = self.pageControl as! TAPageControl
            pageControl.sizeToFit()
        }
        let pageControlFrame = CGRect(x: x, y: y, width: size.width, height: size.height)
        self.pageControl?.frame = pageControlFrame
        self.pageControl?.isHidden = !self.showPageControl!
        if ((self.backgroundImageView) != nil) {
            self.backgroundImageView?.frame = self.bounds;
        }
    }
    //解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
//    func willMoveToSuperview(newSuperview:UIView)  {
//        if newSuperview == nil {
//            invalidateTimer()
//        }
//    }
    deinit{     //解决当timer释放后 回调scrollViewDidScroll时访问野指针导致崩溃
        self.mainView?.delegate = nil;
        self.mainView?.dataSource = nil;
        
    }
    // pragma mark - public actions
    
    func adjustWhenControllerViewWillAppera() {
        let targetIndex = currentIndex()
        if targetIndex < self.totalItemsCount! {
            self.mainView?.scrollToItem(at: NSIndexPath.init(item: targetIndex, section: 0) as IndexPath, at: .centeredHorizontally, animated: false)
        }
    }
    //pragma mark - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView:UIScrollView){
        if !((self.imagePathsGroup?.count) != nil) {// 解决清除timer时偶尔会出现的问题
            return
        }
        let itemIndex = currentIndex()
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: itemIndex)
        if self.pageControl is TAPageControl {
            let pageControl = self.pageControl as! TAPageControl
            pageControl.currentPage = indexOnPageControl
        }else{
            let pageControl = self.pageControl as! UIPageControl
            pageControl.currentPage = indexOnPageControl;
        }
    }
    func scrollViewWillBeginDragging(_ scrollView:UIScrollView) {
//        if self.autoScroll{
        invalidateTimer()
//        }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if self.autoScroll {
            setupTimer()
//        }
    }
    func scrollViewDidEndDecelerating(_ scrollView:UIScrollView) {
        scrollViewDidEndScrollingAnimation(self.mainView!)
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView:UIScrollView) {
        if !((self.imagePathsGroup?.count) != nil) {// 解决清除timer时偶尔会出现的问题
            return
        }
        let itemIndex = currentIndex()
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: itemIndex)
        self.delegate?.cycleScrollViewDidScrollToIndex!(cycleScrollView: self, index: indexOnPageControl)
        
        if (self.itemDidScrollOperationBlock != nil) {
            self.itemDidScrollOperationBlock!(indexOnPageControl)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

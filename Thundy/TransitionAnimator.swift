
import UIKit
import Photos

final class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    // 1
    let presenting: Bool

    init(presenting: Bool) {
        self.presenting = presenting
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        // 3
        return TimeInterval(UINavigationController.hideShowBarDuration)
       
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 4
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        guard let fromViewController = transitionContext.viewController(forKey: .from) else { return }
        guard let toView = transitionContext.view(forKey: .to) else { return }
        guard let toViewController = transitionContext.viewController(forKey: .to) else { return }
        
        let snapshotView = UIImageView()
        
        var cellView: UICollectionViewCell? = nil
        
        // 5
        var duration = transitionDuration(using: transitionContext)
        //let duration: Double = 4
        

        // 6
        let container = transitionContext.containerView
        let toViewFrame = toView.frame
        container.backgroundColor = UIColor.white
        if presenting {
            container.addSubview(toView)
        } else {
            if TypeOfTransition.shared.currentTransition == .ImageSlide {
                toView.frame = fromView.frame
                container.addSubview(toView)
            } else {
                container.insertSubview(toView, belowSubview: fromView)
            }
        }
 
        // 7
        
        
        switch TypeOfTransition.shared.currentTransition {
        case .DefaultSlide:
            toView.frame = CGRect(x: presenting ? toView.frame.width : -toView.frame.width, y: toView.frame.origin.y, width: toView.frame.width, height: toView.frame.height)
        case .UpDownSlide:
            toView.frame = CGRect(x: toView.frame.origin.x, y: presenting ? toView.frame.height : -toView.frame.height, width: toView.frame.width, height: toView.frame.height)
        case .ImageSlide:
            print(toView)
            //duration = 3
            if let currentIndexPath = TypeOfTransition.shared.currentCellIndexPath, let currentFrame =  TypeOfTransition.shared.curretnCellFrame, let currentAsset = TypeOfTransition.shared.currentAsset  {
                if presenting{
                    
                    toView.isHidden = true
                    snapshotView.frame = currentFrame
                    snapshotView.fetchImage(asset: currentAsset, contentMode: .aspectFill)
                    snapshotView.clipsToBounds = true
              
                    container.addSubview(snapshotView)
                    
                    let collectionView = fromView.subviews[0] as! UICollectionView
                    let cell = collectionView.cellForItem(at: currentIndexPath)
                    cellView = cell
                    if let cellview = cellView {
                        cellview.isHidden = true
                    }
                    
                } else {
                   if let collectionView = toView.subviews[0] as? UICollectionView {
                        collectionView.frame = toView.frame
                        /*collectionView.scrollToItem(at: currentIndexPath, at: .centeredVertically, animated: false)
                        collectionView.collectionViewLayout.invalidateLayout()*/
                
                    }
                    snapshotView.frame = currentFrame
                    snapshotView.fetchImage(asset: currentAsset, contentMode: .aspectFill)
                    snapshotView.clipsToBounds = true
                    
                    container.addSubview(snapshotView)
                    
                }
            }
        }
    
        
        let animations = {
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                    switch TypeOfTransition.shared.currentTransition{
                    case .ImageSlide:
                        if let currentAsset = TypeOfTransition.shared.currentAsset, let indexPath = TypeOfTransition.shared.currentCellIndexPath {
                            if self.presenting {
                                let newDimensions = self.calculteFinalImageSize(asset: currentAsset)
                                snapshotView.frame = CGRect(x: toView.frame.origin.x + (toView.frame.width / 2) - (newDimensions.width / 2), y: toView.frame.origin.y + (toView.frame.height / 2) - (newDimensions.height / 2), width: newDimensions.width, height: newDimensions.height)
                            } else {
                                if let collectionView = toView.subviews[0] as? UICollectionView {
                                    print("collectionViewFrame: \(collectionView.frame)")
                                    collectionView.frame = toView.frame
                                    let attributes: UICollectionViewLayoutAttributes? = collectionView.layoutAttributesForItem(at: indexPath)
                                    let cellRect: CGRect? = attributes?.frame
                                    let cellRect2 = collectionView.cellForItem(at: indexPath)!
                                    print("@Cell rect: \(cellRect)")
                                    print("@Cell2 rect: \(cellRect2)")
                                    print("@Cell3 rect: \(attributes?.bounds)")
                                    print("View Frame: \(toView.frame)")
                                    let cellFrameInSuperview = collectionView.convert(cellRect ?? CGRect.zero, to: collectionView.superview)
                                    /*var origin = cellFrameInSuperview.origin
                                    

                                    let xWidthPercentage = origin.x / toViewFrame.width
                                    let yHeightPercentage = origin.y / toViewFrame.height
                                    let newXPosition = fromView.frame.width * xWidthPercentage
                                    let newYPosition = fromView.frame.height * yHeightPercentage
                                    let newOrigin = CGPoint(x: newXPosition, y: newYPosition)
                                    print("Nuevo origen: \(newOrigin)")
                                    origin = newOrigin
                                    let cellPrueba = CGRect(origin: newOrigin, size: cellFrameInSuperview.size)*/


                                    //let newDimensions = collectionView.cellForItem(at: indexPath)!.frame
                                    //print("new frame position: \(newDimensions)")
                                    snapshotView.frame = cellFrameInSuperview
                                    //snapshotView.frame = cellPrueba
                                }
                                if let galleryViewController = toViewController as? GalleryViewController {
                                    let attributes: UICollectionViewLayoutAttributes? = galleryViewController.collectionView.layoutAttributesForItem(at: indexPath)
                                    let cellRect: CGRect? = attributes?.frame
                                    print("@Cell4 rect: \(cellRect)")
                                    print("Celdas visibles: \(galleryViewController.collectionView.indexPathsForVisibleItems)")
                                }
                            }
                        }
                    default: break
                    }
            }

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                
                switch TypeOfTransition.shared.currentTransition {
                case .DefaultSlide:
                    toView.frame = toViewFrame
                    fromView.frame = CGRect(x: self.presenting ? -fromView.frame.width : fromView.frame.width, y: fromView.frame.origin.y, width: fromView.frame.width, height: fromView.frame.height)
                case .UpDownSlide:
                    toView.frame = toViewFrame
                   fromView.frame = CGRect(x: fromView.frame.origin.x, y: self.presenting ? -fromView.frame.height : fromView.frame.height, width: fromView.frame.width, height: fromView.frame.height)
                case .ImageSlide:
                    fromView.alpha = self.presenting ? 0 : 1
                    print("predd")
                }
    
            }

        }

        UIView.animateKeyframes(withDuration: duration,
                                delay: 0,
                                options: .calculationModeCubic,
                                animations: animations,
                                completion: { finished in
                                    // 8
                            
                                    if !self.presenting{
                                        if let collectionView = toView.subviews[0] as? UICollectionView , let indexPath = TypeOfTransition.shared.currentCellIndexPath{
                                            let cell = collectionView.cellForItem(at: indexPath)
                                            cell?.isHidden = false
                                        }
                                    }
                                    toView.isHidden = false
                                    fromView.alpha = 1.0
                                    snapshotView.removeFromSuperview()
                                    container.addSubview(toView)
                                    TypeOfTransition.shared = TypeOfTransition()
                                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func calculteFinalImageSize(asset: PHAsset) -> CGRect{
        let width:CGFloat = CGFloat(asset.pixelWidth)
        let height:CGFloat = CGFloat(asset.pixelHeight)
        let screenShortSide = UIScreen.main.bounds.width
        let screenLongSide = UIScreen.main.bounds.height
        var positionX: CGFloat = 0
        var positionY: CGFloat = 0
        
        var proportion = height / width
        var newShortSide = screenShortSide
        var newLongSide = screenShortSide * proportion
        
        if newLongSide > screenLongSide {
            proportion = pow(proportion, -1)
            newLongSide = screenLongSide
            newShortSide = screenLongSide * proportion
            positionX = ( screenShortSide - newShortSide) / 2
        } else {
            positionY = (screenLongSide - newLongSide) / 2
        }
       
        return CGRect(x: positionX, y: positionY, width: newShortSide, height: newLongSide)
        
    }
}


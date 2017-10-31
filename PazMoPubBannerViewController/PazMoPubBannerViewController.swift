//
//  PazMoPubBannerViewController.swift
//  PazMoPubBannerViewController
//
//  Created by Pantelis Zirinis on 23/10/2017.
//  Copyright © 2017 Pantelis Zirinis. All rights reserved.
//

import UIKit

public class PazMoPubBannerViewController: UIViewController {
    
    public enum UpdateNotification {
        case BannerViewActionWillPresent
        case BannerViewActionDidDismiss
        case BannerViewClassBannerSizeChanged
        case BannerViewClassAdUnitIdChanged
        
        var name: Notification.Name {
            switch self {
            case .BannerViewActionDidDismiss:
                return Notification.Name("BannerViewActionDidFinish")
            case .BannerViewActionWillPresent:
                return Notification.Name("BannerViewActionWillBegin")
            case .BannerViewClassAdUnitIdChanged:
                return Notification.Name("BannerViewClassAdUnitIdChanged")
            case .BannerViewClassBannerSizeChanged:
                return Notification.Name("BannerViewClassBannerSizeChanged")
            }
        }
    }
    
    public var contentViewController: UIViewController
    public lazy var contentView: UIView = {
        let view = UIView(frame: UIScreen.main.bounds)
        return view
    }()
    private (set) var bannerLoaded: Bool = false
    private (set) var showing: Bool = false
    
    // Initialize using a content view controller
    public init(contentViewController: UIViewController, adUnitId: String, active: Bool = true) {
        self.adUnitId = adUnitId
        self.active = active
        self.contentViewController = contentViewController
        self.adSize = (UI_USER_INTERFACE_IDIOM() == .pad) ? MOPUB_LEADERBOARD_SIZE : MOPUB_BANNER_SIZE
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        super.loadView()
        // Setup containment of the _contentController.
        self.addChildViewController(self.contentViewController)
        self.contentView.addSubview(self.contentViewController.view)
        self.contentViewController.didMove(toParentViewController: self)
        
        self.view = self.contentView
    }
    
    // Setting everything in one function
    public func set(adUnitId: String, active: Bool = true, logLevel: MPLogLevel = MPLogLevelOff) {
        MPLogSetLevel(logLevel)
        self.adUnitId = adUnitId
        self.active = active
    }
    
    // The MoPub Ad Unit Id to be used to load adverts
    public var adUnitId: String {
        didSet {
            guard self.adUnitId != oldValue else {
                return
            }
            self.removeAdView()
            if self.active {
                self.adView?.loadAd()
            }
            NotificationCenter.default.post(name: UpdateNotification.BannerViewClassAdUnitIdChanged.name, object: self)
        }
    }
    
    public func disableLogging() {
        MPLogSetLevel(MPLogLevelOff)
    }
    
    // Activates/Deactivate the presentation of adverts
    public var active: Bool = true {
        didSet {
            if oldValue == self.active {
                return
            }
            if self.active {
                self.adView?.loadAd()
            } else {
                self.removeAdView()
            }
        }
    }
    
    // Ad Size for current device
    public var adSize: CGSize {
        didSet {
            guard self.adSize != oldValue else {
                return
            }
            if self.adSize == CGSize.zero {
                self.removeAdView()
                let _ = self.adView
            }
            NotificationCenter.default.post(name: UpdateNotification.BannerViewClassBannerSizeChanged.name, object: self)
        }
    }
    
    // MARK: - View Updates
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.refreshLayout()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.refreshLayout()
    }
    
    public func refreshLayout() {
        var contentFrame = self.view.bounds
        guard var bannerFrame = self.adView?.frame else {
            return
        }
        
        // Check if the banner has an ad loaded and ready for display.  Move the banner off
        // screen if it does not have an ad.
        if self.bannerLoaded {
            contentFrame.size.height -= bannerFrame.size.height
            bannerFrame.origin.y = contentFrame.size.height
            self.showing = true
        } else {
            bannerFrame.origin.y = contentFrame.size.height
            self.showing = false
        }
        self.contentViewController.view.frame = contentFrame
        if let nv = self.contentViewController as? UINavigationController {
            nv.visibleViewController?.view.setNeedsLayout()
        }
        // Center banner frame
        // Repositioning example: keep the ad view centered horizontally.
        bannerFrame.origin.x = (self.view.bounds.size.width - bannerFrame.size.width) / 2;
        self.adView?.frame = bannerFrame;
    }
    
    // MARK: - AdView
    
    func newAdView() -> MPAdView {
        return MPAdView.init(adUnitId: self.adUnitId, size: self.adSize)
    }
    
    private var _adView: MPAdView?
    public var adView: MPAdView? {
        guard self.active else {
            return nil
        }
        if let adView = self._adView {
            return adView
        }
        let adView = self.newAdView()
        adView.delegate = self
        self.contentView.addSubview(adView)
        self._adView = adView
        return adView
    }
    
    func removeAdView() {
        guard self._adView != nil else {
            self.bannerLoaded = false
            return
        }

        self._adView?.removeFromSuperview()
        self._adView = nil
        self.bannerLoaded = false
        UIView.animate(withDuration: 0.25) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
}

extension PazMoPubBannerViewController: MPAdViewDelegate {
    public func viewControllerForPresentingModalView() -> UIViewController! {
        return self.contentViewController
    }
    
    public func adViewDidLoadAd(_ view: MPAdView!) {
        self.showing = true
        UIView.animate(withDuration: 0.25) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    public func adViewDidFail(toLoadAd view: MPAdView!) {
        guard let _ = self._adView else {
            self.bannerLoaded = false
            return
        }
        self.bannerLoaded = false
        UIView.animate(withDuration: 0.25) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    public func willPresentModalView(forAd view: MPAdView!) {
        NotificationCenter.default.post(name: UpdateNotification.BannerViewActionWillPresent.name, object: self)
    }
    
    public func didDismissModalView(forAd view: MPAdView!) {
        NotificationCenter.default.post(name: UpdateNotification.BannerViewActionDidDismiss.name, object: self)
    }

}

// MARK: - Interface Orientation and Rotation
public extension PazMoPubBannerViewController {
    public override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.adView?.rotate(to: toInterfaceOrientation)
    }
    
    public override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.contentViewController.preferredInterfaceOrientationForPresentation
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.contentViewController.supportedInterfaceOrientations
    }
    
}


//
//  PazMoPubNavigationController.swift
//  PazMoPubNavigationController
//
//  Created by Pantelis Zirinis on 23/10/2017.
//  Copyright © 2017 Pantelis Zirinis. All rights reserved.
//

import UIKit

public class PazMoPubNavigationController: UINavigationController {
    
    public init(rootViewController: UIViewController, adUnitId: String, active: Bool = true) {
        self.adUnitId = adUnitId
        self.active = active
        super.init(rootViewController: rootViewController)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.adUnitId = ""
        super.init(coder: aDecoder)
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
            self.removeAdView()
            if self.active {
                self.adView.loadAd()
            }
        }
    }
    
    // Activates/Deactivate the presentation of adverts
    public var active: Bool = true {
        didSet {
            if oldValue == self.active {
                return
            }
            if self.active {
                self.adView.loadAd()
            } else {
                self.removeAdView()
            }
        }
    }
    
    // Whether an advert is currently visible
    var showing: Bool {
        return !self.isToolbarHidden
    }
    
    // Ad Size for current device
    public var adSize: CGSize {
        return (UI_USER_INTERFACE_IDIOM() == .pad) ? MOPUB_LEADERBOARD_SIZE : MOPUB_BANNER_SIZE
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
        guard let adView = self._adView else {
            return
        }
        
        var toolbarFrame = self.toolbar.frame
        
        let size = adView.adContentViewSize()
        var newFrame = self.adView.frame
        newFrame.size = size;
        newFrame.origin.x = (toolbarFrame.size.width - size.width) / 2
        adView.frame = newFrame;
        
        let dHeight = toolbarFrame.size.height - self.adSize.height
        guard dHeight != 0.0 else {
            return
        }
        toolbarFrame.size.height -= dHeight;
        toolbarFrame.origin.y += dHeight;
        self.toolbar.frame = toolbarFrame;
    }
    
    // MARK: - AdView
    
    func newAdView() -> MPAdView {
        return MPAdView.init(adUnitId: self.adUnitId, size: self.adSize)
    }
    
    private var _adView: MPAdView?
    public var adView: MPAdView {
        if let adView = self._adView {
            return adView
        }
        let adView = self.newAdView()
        adView.delegate = self
        self.view.needsUpdateConstraints()
        self.toolbar.addSubview(adView)
        return adView
    }
    
    func removeAdView() {
        self._adView?.removeFromSuperview()
        self._adView = nil
        self.isToolbarHidden = true
    }
}

extension PazMoPubNavigationController: MPAdViewDelegate {
    public func viewControllerForPresentingModalView() -> UIViewController! {
        return self.visibleViewController
    }
    
    public func adViewDidLoadAd(_ view: MPAdView!) {
        self.isToolbarHidden = false
        self.view.setNeedsLayout()
    }
    
    public func adViewDidFail(toLoadAd view: MPAdView!) {
        self.isToolbarHidden = true
    }
}

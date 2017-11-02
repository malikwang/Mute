//
//  AppDelegate.swift
//  Mute
//
//  Created by 王一凡 on 2017/7/10.
//  Copyright © 2017年 王一凡. All rights reserved.
//

import Cocoa
import AMCoreAudio

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let device = AudioDevice.lookup(by: "AppleHDAEngineOutput:1F,3,0,1,1:0")
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let menu = NSMenu()
    var neteaseItem = NSMenuItem.init(title: "网易云暂停", action: Selector("toggleState"), keyEquivalent: "")
    var tipWindow:NSWindow!
    var imageView:NSImageView!
    
    //定义一个定时器，用来不断执行静音
    var timer = Timer()
    //同样定义定时器重复次数
    var repeatCount = 0
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
        menu.addItem(neteaseItem)
        menu.addItem(NSMenuItem.init(title: "退出", action: Selector("terminate:"), keyEquivalent: "q"))
        statusItem.menu = menu
        self.openSystemAccessibility()
        self.initTipWindow()
        self.checkJackStatus()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func initTipWindow(){
        let screenFrame = NSScreen.main()?.frame
        let tipWindowWidth:CGFloat = 200.0
        let tipWindowHeight:CGFloat = 200.0
        let screenWidth = screenFrame?.size.width
        let screenHeight = screenFrame?.size.height
        let contentRect = CGRect.init(x: (screenWidth! - tipWindowWidth)*0.5, y: (screenHeight! - tipWindowHeight)*0.2, width: tipWindowWidth, height: tipWindowHeight)
        tipWindow = NSWindow.init(contentRect: contentRect, styleMask: NSWindowStyleMask.borderless, backing: NSBackingStoreType.buffered, defer: false)
        tipWindow.level = NSPopUpMenuWindowLevel
        tipWindow.isOpaque = false
        tipWindow.backgroundColor = NSColor.clear
        tipWindow.contentView?.wantsLayer = true
        let effectView = NSVisualEffectView.init(frame: NSRect.init(x: 0, y: 0, width: tipWindowWidth, height: tipWindowHeight))
        effectView.material = NSVisualEffectMaterial.selection
        effectView.blendingMode = NSVisualEffectBlendingMode.behindWindow
        effectView.state = NSVisualEffectState.active
        effectView.wantsLayer = true;
        effectView.layer?.cornerRadius = 18
        tipWindow.contentView?.addSubview(effectView)
    }
    
    func showTipWindowWithState(state:Bool){
        if imageView != nil {
            imageView.removeFromSuperview()
        }
        imageView = NSImageView.init(frame: NSRect.init(x: 60, y: 70, width: 80, height: 80))
        if state {
            imageView.image = NSImage(named:"headphone_on")
        } else {
            imageView.image = NSImage(named:"headphone_off")
        }
        tipWindow.contentView?.addSubview(imageView)
        tipWindow.orderFront(self)
    }
    
    func autoDismissTipWindowAfterDelay(delay:Double){
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.tipWindow.orderOut(self)
        }
    }
    
    
    func checkJackStatus(){
        if device?.isJackConnected(direction: .playback) == true{
            statusItem.button?.image = NSImage(named:"jack")
        } else {
            statusItem.button?.image = NSImage(named:"notjack")
        }
    }
    
    func jackChanged(device1:AudioDevice){
        if let isJackConnected = device?.isJackConnected(direction: .playback) {
            if !isJackConnected {
                statusItem.button?.image = NSImage(named:"notjack")
                self.showTipWindowWithState(state: false)
                if neteaseItem.state == NSOnState {
                    self.neteasePause()
                }
                timer = Timer.init(timeInterval: 0.01, target:self, selector: Selector("setOutputMute"), userInfo: nil, repeats: true)
                RunLoop.current.add(timer, forMode: .commonModes)
            } else {
                statusItem.button?.image = NSImage(named:"jack")
                self.showTipWindowWithState(state: true)
            }
            self.autoDismissTipWindowAfterDelay(delay: 3)
        }
    }
    func setOutputMute() {
        let mute = "set volume with output muted"
        let muteScript = NSAppleScript.init(source: mute)
        muteScript?.executeAndReturnError(nil)
        repeatCount += 1
        if repeatCount > 100 {
            timer.invalidate()
        }
    }
    func neteasePause(){
        let url = Bundle(for: self.classForCoder).url(forResource: "NeteasePause", withExtension: "scpt")
        let appleScript = NSAppleScript.init(contentsOf: url as! URL, error: nil)
        appleScript?.executeAndReturnError(nil)
    }
    
    func toggleState(){
        if !self.systemAccessibilityState() {
            //alert
            let alert: NSAlert = NSAlert()
            alert.messageText = "权限提示"
            alert.informativeText = "您必须将Mute.app添加到[系统偏好设置-->安全与隐私-->辅助功能]列表中才能使用此功能。"
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "确定")
            alert.addButton(withTitle: "取消")
            if alert.runModal() == NSAlertFirstButtonReturn{
                self.openSystemAccessibility()
            }
        } else {
            if neteaseItem.state == NSOnState {
                neteaseItem.state = NSOffState
            } else {
                neteaseItem.state = NSOnState
            }
        }
    }
    
    func systemAccessibilityState() -> Bool{
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let privOptions = [trusted: false] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)
        return accessEnabled
    }
    
    func openSystemAccessibility(){
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let privOptions = [trusted: true] as CFDictionary
        AXIsProcessTrustedWithOptions(privOptions)
    }
}

extension AppDelegate : EventSubscriber {
    func eventReceiver(_ event: Event) {
        switch event {
        case let event as AudioDeviceEvent:
            switch event {
            case .isJackConnectedDidChange(let audioDevice):
                if device as? AudioDevice == audioDevice {
                    self.jackChanged(device1: audioDevice)
                }
            default:
                break
            }
        default:
            break
        }
    }
}

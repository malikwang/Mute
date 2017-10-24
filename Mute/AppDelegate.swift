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
    
    //定义一个定时器，用来不断执行静音
    var timer = Timer()
    //同样定义定时器重复次数
    var repeatCount = 0
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
        self.checkJackStatus()
        menu.addItem(neteaseItem)
        menu.addItem(NSMenuItem.init(title: "退出", action: Selector("terminate:"), keyEquivalent: "q"))
        statusItem.menu = menu
        self.openSystemAccessibility()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
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
                if neteaseItem.state == NSOnState {
                    self.neteasePause()
                }
                timer = Timer.init(timeInterval: 0.01, target:self, selector: Selector("setOutputMute"), userInfo: nil, repeats: true)
                RunLoop.current.add(timer, forMode: .commonModes)
            } else {
                statusItem.button?.image = NSImage(named:"jack")
            }
        }
    }
    func setOutputMute() {
        device?.setMute(true, channel: 0, direction: .playback)
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

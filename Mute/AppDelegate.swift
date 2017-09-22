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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
        self.checkJackStatus()
        menu.addItem(neteaseItem)
        menu.addItem(NSMenuItem.init(title: "退出", action: Selector("terminate:"), keyEquivalent: "q"))
        statusItem.menu = menu
       
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
                self.perform(#selector(setOutputMute), with: nil)
            } else {
                statusItem.button?.image = NSImage(named:"jack")
            }
        }
    }
    func setOutputMute() {
        while let isMuted = device?.isMuted(channel: 0, direction: .playback) {
            if !isMuted{
                device?.setMute(true, channel: 0, direction: .playback)
                print("1")
            }
        }
    }
    func neteasePause(){
        let tell = "tell application \"System Events\"\n"
        let key = "key code 49 using {option down, command down}\n"
        let endTell = "end tell"
        let neteasePauseScript: NSAppleScript = NSAppleScript(source: tell
            + key + endTell)!
        neteasePauseScript.executeAndReturnError(nil)
    }
    func toggleState(){
        if neteaseItem.state == NSOnState {
            neteaseItem.state = NSOffState
        } else {
            neteaseItem.state = NSOnState
        }
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

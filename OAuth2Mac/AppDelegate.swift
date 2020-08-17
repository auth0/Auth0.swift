//
//  AppDelegate.swift
//  OAuth2Mac
//
//  Created by Martin on 16/07/2018.
//  Copyright © 2018 Auth0. All rights reserved.
//

import Cocoa
import Auth0

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initalize apple event manager for operating systems prior to 10.15
        let appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(self, andSelector: #selector(handleGetURLEvent(event:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // Url handling for operating systems 10.15 and higher
    func application(_ application: NSApplication, open urls: [URL]) {
        Auth0.resumeAuth(urls)
    }
    
    // Url handling for operating systems prior to 10.15
    @objc fileprivate func handleGetURLEvent(event: NSAppleEventDescriptor?, withReplyEvent replyEvent: NSAppleEventDescriptor?) {
        guard let event = event else {
            return
        }
        guard let stringVal = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue, let url = URL(string: stringVal) else {
            return
        }
        
       Auth0.resumeAuth([url])
    }

}

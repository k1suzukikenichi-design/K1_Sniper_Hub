//
//  K1_Sniper_HubApp.swift
//  K1_Sniper_Hub
//
//  Created by 鈴木健一 on 2026/02/23.
//

import SwiftUI

@main
struct K1_Sniper_HubApp: App {
    // AppDelegate（Firebase + FCM + プッシュ通知）を SwiftUI ライフサイクルに接続
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

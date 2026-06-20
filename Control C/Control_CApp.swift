//
//  Control_CApp.swift
//  Control C
//
//  Created by Peter Olusesan on 20/06/2026.
//

import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct Control_CApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var monitor = ClipboardMonitor()

    var body: some Scene {
        MenuBarExtra("Control C", systemImage: "doc.on.clipboard") {
            ContentView(monitor: monitor)
                .onAppear { monitor.start() }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

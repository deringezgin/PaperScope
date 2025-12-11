//
//  PaperScopeApp.swift
//  PaperScope
//
//  Created by Derin Gezgin on 12/11/25.
//

import SwiftUI

@main
struct PaperScopeApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var navState = NavigationState()
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appSettings)
                .environmentObject(navState)
                .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
        }
    }
}

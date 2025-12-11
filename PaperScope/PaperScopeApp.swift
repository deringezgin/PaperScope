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
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
        }
    }
}

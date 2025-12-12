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
    
    init() {
        // Register Fonts
        let fontNames = ["cmu.serif-bold", "cmu.serif-roman", "cmu.serif-italic"]
        for name in fontNames {
            var fontURL: URL?
            // Try multiple paths
            let subdirectories = ["assets/fonts", "fonts", nil]
            
            for subdirectory in subdirectories {
                if let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: subdirectory) {
                    fontURL = url
                    break
                }
            }
            
            if let fontURL = fontURL {
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
                if let error = error?.takeRetainedValue() {
                    print("Error registering font \(name): \(error)")
                }
            } else {
                 print("Failed to find font \(name) in bundle")
            }
        }

        // Configure Navigation Bar Title Font
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        
        // Attempt to load the custom font "CMUSerif-Bold"
        // If registration worked, this should succeed.
        if let customFont = UIFont(name: "CMUSerif-Bold", size: 34) {
             appearance.largeTitleTextAttributes = [
                 .font: customFont,
                 .foregroundColor: UIColor.label
             ]
             appearance.titleTextAttributes = [
                 .font: customFont.withSize(17),
                 .foregroundColor: UIColor.label
             ]
        } else {
            // Fallback to system serif if custom font fails
            let descriptor = UIFont.systemFont(ofSize: 34).fontDescriptor.withDesign(.serif) ?? UIFont.systemFont(ofSize: 34).fontDescriptor
            let serifFont = UIFont(descriptor: descriptor, size: 34)
            appearance.largeTitleTextAttributes = [
                .font: serifFont,
                .foregroundColor: UIColor.label
            ]
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appSettings)
                .environmentObject(navState)
                .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
        }
    }
}

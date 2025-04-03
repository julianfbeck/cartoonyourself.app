//
//  cartoonyourselfApp.swift
//  cartoonyourself
//
//  Created by Julian Beck on 03.04.25.
//

import SwiftUI
import RevenueCat

@main
struct cartoonyourselfApp: App {
    @StateObject var globalViewModel = GlobalViewModel()
    @StateObject var wmrm = AnimeViewModel()
    
    init() {
        Purchases.configure(withAPIKey: "appl_xIhJySLYOoywhePdUmVaSAnaZ")
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(globalViewModel)
                .environmentObject(wmrm)
                
                .onAppear {
                    Plausible.shared.configure(domain: "anime.juli.sh", endpoint: "https://stats.juli.sh/api/event")
                }
        }
    }
}

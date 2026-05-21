//
//  Pano_ViewApp.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import SwiftUI

@main
struct Pano_ViewApp: App {
    @StateObject private var panoramaFetcher = PanoramaFetcher()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(panoramaFetcher)
        }
    }
}

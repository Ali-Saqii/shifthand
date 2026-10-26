//
//  shifthandApp.swift
//  shifthand
//
//  Created by Mac mini on 21/10/2026.
//

import SwiftUI

@main
@MainActor
struct shifthandApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}

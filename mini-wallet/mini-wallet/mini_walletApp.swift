//
//  mini_walletApp.swift
//  mini-wallet
//
//  Created by Daniil Kiryanchuk on 28.08.2026.
//

import SwiftUI

@main
struct mini_walletApp: App {
    @State private var store = WalletStore()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .environment(router)
        }
    }
}

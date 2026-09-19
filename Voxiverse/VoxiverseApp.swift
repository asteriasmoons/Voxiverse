//
//  VoxiverseApp.swift
//  Voxiverse
//
//  Created by Asteria Moon on 9/7/26.
//

import SwiftUI
import SwiftData

@main
struct VoxiverseApp: App {
    @StateObject private var deepLinkRouter = VoxiverseDeepLinkRouter()

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            VoxiverseManagedApp.self,
            VoxiverseReport.self,
            VoxiverseFeatureRequest.self,
            VoxiverseReportAttachment.self,
            VoxiverseActivity.self
        ])
        let modelConfiguration = ModelConfiguration(
            "Voxiverse",
            schema: schema,
            cloudKitDatabase: .private("iCloud.im.lystaria.Voxiverse")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create CloudKit model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deepLinkRouter)
                .onOpenURL { url in
                    deepLinkRouter.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

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
    @UIApplicationDelegateAdaptor(VoxiverseNotificationDelegate.self) private var notificationDelegate
    @StateObject private var deepLinkRouter = VoxiverseDeepLinkRouter()
    @Environment(\.scenePhase) private var scenePhase

    let sharedModelContainer: ModelContainer = {
        let cloudSchema = Schema([
            VoxiverseManagedApp.self,
            VoxiverseReport.self,
            VoxiverseFeatureRequest.self,
            VoxiverseReportAttachment.self,
            VoxiverseActivity.self
        ])
        let conversationSchema = Schema([
            VoxiverseConversation.self
        ])
        let schema = Schema([
            VoxiverseManagedApp.self,
            VoxiverseReport.self,
            VoxiverseFeatureRequest.self,
            VoxiverseReportAttachment.self,
            VoxiverseActivity.self,
            VoxiverseConversation.self
        ])
        let cloudConfiguration = ModelConfiguration(
            "Voxiverse",
            schema: cloudSchema,
            cloudKitDatabase: .private("iCloud.im.lystaria.Voxiverse")
        )
        let conversationConfiguration = ModelConfiguration(
            "VoxiverseConversationIndex",
            schema: conversationSchema,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [cloudConfiguration, conversationConfiguration]
            )
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
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { await VoxiverseReportConversationNotificationManager.scanForNewMessages() }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

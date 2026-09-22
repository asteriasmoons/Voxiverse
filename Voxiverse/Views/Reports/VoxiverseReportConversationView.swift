//
//  VoxiverseReportConversationView.swift
//  Voxiverse
//

import PhotosUI
import QuickLook
import SwiftUI
import UniformTypeIdentifiers

struct VoxiverseReportConversationView: View {
    let context: ReportConversationContext
    let onClose: () -> Void

    @StateObject private var service = VoxiverseReportConversationService()
    @State private var draft = ""
    @State private var isExpandedComposerPresented = false
    @State private var showingAttachmentOptions = false
    @State private var showingPhotos = false
    @State private var showingFiles = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachments: [ReportConversationAttachment] = []
    @State private var attachmentError: String?
    @State private var attachmentPreviewURL: URL?
    @State private var messagePendingDeletion: ReportConversationMessage?
    @State private var didPerformInitialScroll = false
    @FocusState private var isComposerFocused: Bool

    private let conversationBottomID = "report-conversation-bottom"

    var body: some View {
        ZStack {
            VoxiverseColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isComposerFocused = false
            }
        }
        .task {
            await service.load(context: context, markRead: true)
        }
        .sheet(isPresented: $isExpandedComposerPresented) {
            expandedComposerSheet
        }
        .quickLookPreview($attachmentPreviewURL)
        .confirmationDialog("Add Attachment", isPresented: $showingAttachmentOptions, titleVisibility: .visible) {
            Button("Gallery") { showingPhotos = true }
            Button("Files") { showingFiles = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotos, selection: $selectedPhotos, maxSelectionCount: 3, matching: .images)
        .onChange(of: selectedPhotos) { _, items in
            Task { await loadPhotos(items) }
        }
        .fileImporter(isPresented: $showingFiles, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            loadFiles(result)
        }
        .alert("Attachment Error", isPresented: Binding(
            get: { attachmentError != nil },
            set: { if !$0 { attachmentError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(attachmentError ?? "")
        }
        .alert(
            "Delete this message?",
            isPresented: Binding(
                get: { messagePendingDeletion != nil },
                set: { if !$0 { messagePendingDeletion = nil } }
            ),
            presenting: messagePendingDeletion
        ) { message in
            Button("Delete Message", role: .destructive) {
                Task { await service.deleteMessage(message, context: context) }
                messagePendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                messagePendingDeletion = nil
            }
        } message: { message in
            Text(message.isFromStaff
                ? "This removes your message for both you and the reporter. This can't be undone."
                : "This removes the reporter's message for both you and the reporter. This can't be undone.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(context.reportID)
                .font(.system(size: 31, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryText)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            if service.snapshot?.recordID != nil {
                Menu {
                    Button("Accept Replies") {
                        Task { await service.setAcceptsReplies(true, context: context) }
                    }
                    .disabled(service.snapshot?.acceptsReplies == true)

                    Button("Read Only") {
                        Task { await service.setAcceptsReplies(false, context: context) }
                    }
                    .disabled(service.snapshot?.acceptsReplies == false)
                } label: {
                    VoxiverseAssetIcon(assetName: "settings", size: 25, tint: VoxiverseColor.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Conversation reply setting")
                .accessibilityValue(service.snapshot?.acceptsReplies == false ? "Read Only" : "Accept Replies")
            }

            VoxiverseIconButton(assetName: "xmarkwavy", label: "Close", action: onClose)
        }
        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var content: some View {
        if service.isLoading && service.snapshot == nil {
            VStack(spacing: 18) {
                VoxiverseConversationLoadingRing()
                Text("Loading conversation…")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            reportContextCard
                            stateContent
                            Color.clear
                                .frame(height: 1)
                                .id(conversationBottomID)
                        }
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 18)
                    }
                    .onAppear {
                        scrollToConversationBottom(using: proxy, animated: false)
                    }
                    .onChange(of: service.displayedMessages.count) { _, count in
                        guard count > 0 else { return }
                        scrollToConversationBottom(
                            using: proxy,
                            animated: didPerformInitialScroll
                        )
                        didPerformInitialScroll = true
                    }
                    .onChange(of: service.snapshot?.acceptsReplies) { _, acceptsReplies in
                        guard acceptsReplies == false else { return }
                        scrollToConversationBottom(using: proxy, animated: true)
                    }
                }

                if canCompose {
                    composer
                }
            }
        }
    }

    private func scrollToConversationBottom(using proxy: ScrollViewProxy, animated: Bool) {
        Task { @MainActor in
            await Task.yield()
            await Task.yield()
            if animated {
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(conversationBottomID, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(conversationBottomID, anchor: .bottom)
            }
        }
    }

    private var reportContextCard: some View {
        VoxiverseSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    conversationFrostedBadge(title: currentStateLabel, tint: VoxiverseFrostedPalette.purple)
                    conversationFrostedBadge(title: context.reportType, tint: VoxiverseFrostedPalette.blue)
                }

                Text(context.reportTitle)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(context.sourceAppName) • \(context.reporterDisplayName.isEmpty ? "Unknown reporter" : context.reporterDisplayName)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)
    }

    @ViewBuilder
    private var stateContent: some View {
        if let error = service.errorMessage {
            VoxiverseSurfaceCard {
                Text(error)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.berry, cornerRadius: 18)
        }

        switch currentState {
        case .notStarted:
            VStack(spacing: 14) {
                VoxiverseSurfaceCard {
                    VStack(alignment: .leading, spacing: 10) {
                        VoxiverseFrostedGlassIcon(
                            assetName: "luvmail",
                            size: 30,
                            tint: VoxiverseFrostedPalette.blue
                        )
                        Text(messages.isEmpty ? "No invitation sent yet" : "Creating conversation…")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(VoxiverseColor.primaryText)
                        Text("Sending your first message creates the private conversation and invites this report's original submitter. Opening this screen does not send anything.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(VoxiverseColor.secondaryText)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.blue, cornerRadius: 18)

                if !messages.isEmpty {
                    messagesOrWaitingText("Creating conversation…")
                }
            }
        case .invited:
            VStack(spacing: 14) {
                VoxiverseSurfaceCard {
                    VStack(spacing: 14) {
                        VoxiverseFrostedGlassIcon(
                            assetName: "starmailing",
                            size: 38,
                            tint: VoxiverseFrostedPalette.berry
                        )

                        Text("Conversation Invitation")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(VoxiverseColor.primaryText)
                            .multilineTextAlignment(.center)

                        Text("The reporter has been invited to join this private conversation. These controls mirror the invitation actions currently available to them.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(VoxiverseColor.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 10) {
                            invitationPreviewButton(
                                title: "Accept",
                                tint: VoxiverseFrostedPalette.purple
                            )
                            invitationPreviewButton(
                                title: "Decline",
                                tint: VoxiverseFrostedPalette.blue
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)

                messagesOrWaitingText("Invitation sent. The reporter has not accepted yet.")
            }
        case .accepted:
            messagesOrWaitingText("Conversation accepted. Messages will appear here.")
        case .declined:
            VoxiverseSurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    VoxiverseAssetIcon(assetName: "xmarkwavy", size: 28, tint: VoxiverseColor.secondaryAccent)
                    Text("The reporter declined this conversation.")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(VoxiverseColor.primaryText)
                    Text("Declining is saved as the conversation state, and Voxiverse will not send additional messages in this thread.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func messagesOrWaitingText(_ emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if messages.isEmpty {
                VoxiverseSurfaceCard {
                    Text(emptyText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ForEach(messages) { message in
                    messageBubble(message)
                        .id(message.id)
                }
            }

            if service.snapshot?.acceptsReplies == false {
                Text("This conversation is currently read only. Voxiverse can turn replies back on at any time.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .id("read-only-status")
            }
        }
    }

    private func messageBubble(_ message: ReportConversationMessage) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.isFromStaff {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.isFromStaff ? .trailing : .leading, spacing: 8) {
                VStack(alignment: message.isFromStaff ? .trailing : .leading, spacing: 5) {
                    Text(message.isFromStaff ? "Voxiverse" : "Reporter")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(message.isFromStaff ? VoxiverseColor.primaryAction : VoxiverseColor.secondaryAccent)

                    if !message.body.isEmpty {
                        Text(message.body)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(VoxiverseColor.primaryText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)

                    if message.isFromStaff && message.deliveryState != .sent {
                        HStack(spacing: 8) {
                            Text(message.deliveryState == .sending ? "Sending…" : "Failed to send")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(message.deliveryState == .failed ? VoxiverseColor.secondaryAccent : VoxiverseColor.secondaryText)
                            if message.deliveryState == .failed {
                                Button("Retry") { service.retryStaffMessage(message.id, context: context) }
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(VoxiverseColor.primaryAction)
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(13)
                .background(
                    VoxiverseFrostedGlassMaterial(
                        tint: message.isFromStaff ? VoxiverseFrostedPalette.blue : VoxiverseFrostedPalette.purple,
                        cornerRadius: 18
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .contextMenu {
                    if message.deliveryState != .sending {
                        Button("Delete Message", role: .destructive) {
                            messagePendingDeletion = message
                        }
                    }
                }

                ForEach(message.attachments) { attachment in
                    Button {
                        openAttachment(attachment)
                    } label: {
                        attachmentLabel(attachment)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open \(attachment.name)")
                }
            }

            if !message.isFromStaff {
                Spacer(minLength: 40)
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $draft)
                    .focused($isComposerFocused)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .padding(.leading, 10)
                    .padding(.trailing, 44)
                    .padding(.vertical, 7)

                if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(currentState == .notStarted ? "Send the first invitation message…" : "Message the reporter…")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText.opacity(0.75))
                        .padding(.leading, 16)
                        .padding(.top, 15)
                        .allowsHitTesting(false)
                }

                Button {
                    isExpandedComposerPresented = true
                } label: {
                    VoxiverseFrostedGlassIcon(
                        assetName: "expand",
                        size: 20,
                        tint: VoxiverseFrostedPalette.blue
                    )
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Expand message editor")
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .padding(.top, 5)
                .padding(.trailing, 8)
            }
            .frame(height: 74)

            if !attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(attachments) { attachment in
                            HStack(spacing: 6) {
                                Text(attachment.name).lineLimit(1)
                                Button {
                                    attachments.removeAll { $0.id == attachment.id }
                                } label: {
                                    VoxiverseAssetIcon(assetName: "xmarkwavy", size: 12, tint: VoxiverseColor.secondaryAccent)
                                }
                                .accessibilityLabel("Remove \(attachment.name)")
                            }
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(VoxiverseColor.primaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(VoxiverseColor.raisedSurface, in: Capsule())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
            }

            Rectangle()
                .fill(VoxiverseColor.primaryText.opacity(0.17))
                .frame(height: 1)
                .padding(.horizontal, 12)

            HStack {
                Button {
                    showingAttachmentOptions = true
                } label: {
                    VoxiverseFrostedGlassIcon(
                        assetName: "attachment",
                        size: 30,
                        tint: VoxiverseFrostedPalette.blue
                    )
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add attachment")

                Spacer(minLength: 0)

                sendButton
            }
            .padding(.horizontal, 11)
            .frame(height: 58)
        }
        .background(VoxiverseColor.raisedSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(VoxiverseColor.primaryAction.opacity(0.46), lineWidth: 1)
        }
        .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 24)
        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
        .padding(.top, 10)
        .padding(.bottom, 22)
        .background(VoxiverseColor.background.opacity(0.96))
    }

    private var sendButton: some View {
        Button(action: sendDraft) {
            VoxiverseFrostedGlassIcon(
                assetName: "send",
                size: 30,
                tint: VoxiverseFrostedPalette.purple
            )
            .frame(width: 48, height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .opacity(canSend ? 1 : 0.45)
        .accessibilityLabel(currentState == .notStarted ? "Send invitation message" : "Send message")
    }

    private var expandedComposerSheet: some View {
        NavigationStack {
            ZStack {
                VoxiverseColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("Message")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(VoxiverseColor.primaryText)

                        Spacer(minLength: 16)

                        Button {
                            isExpandedComposerPresented = false
                        } label: {
                            VoxiverseAssetIcon(assetName: "xmarkwavy", size: 28, tint: VoxiverseColor.secondaryAccent)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close message editor")

                        Button {
                            sendDraft()
                            isExpandedComposerPresented = false
                        } label: {
                            VoxiverseAssetIcon(assetName: "send", size: 28, tint: VoxiverseColor.primaryAction)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSend)
                        .opacity(canSend ? 1 : 0.45)
                        .accessibilityLabel(currentState == .notStarted ? "Send invitation message" : "Send message")
                    }
                    .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                    TextEditor(text: $draft)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.primaryText)
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .background(Color.clear)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func sendDraft() {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSend else { return }
        let selectedAttachments = attachments
        if service.sendStaffMessage(message, attachments: selectedAttachments, context: context) {
            draft = ""
            attachments = []
        }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    private func addAttachment(name: String, typeIdentifier: String, data: Data) {
        guard attachments.count < 3 else {
            attachmentError = "You can attach up to three items to a message."
            return
        }
        do {
            let prepared = try ConversationImageOptimizer.prepare(data: data, name: name, typeIdentifier: typeIdentifier)
            guard prepared.data.count <= ConversationImageOptimizer.maximumAttachmentBytes else {
                attachmentError = "Files must be 10 MB or smaller."
                return
            }
            attachments.append(ReportConversationAttachment(
                name: prepared.name,
                typeIdentifier: prepared.typeIdentifier,
                data: prepared.data
            ))
        } catch {
            attachmentError = error.localizedDescription
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let type = item.supportedContentTypes.first ?? .image
                let ext = type.preferredFilenameExtension ?? "jpg"
                addAttachment(name: "Photo \(attachments.count + 1).\(ext)", typeIdentifier: type.identifier, data: data)
            } catch {
                attachmentError = error.localizedDescription
            }
        }
        selectedPhotos = []
    }

    private func loadFiles(_ result: Result<[URL], Error>) {
        do {
            for url in try result.get() {
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let resourceType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
                let extensionType = UTType(filenameExtension: url.pathExtension)
                let type = resourceType?.conforms(to: .image) == true
                    ? (resourceType ?? .image)
                    : (extensionType ?? resourceType ?? .data)
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                let sourceLimit = type.conforms(to: .image)
                    ? ConversationImageOptimizer.maximumSourceImageBytes
                    : ConversationImageOptimizer.maximumAttachmentBytes
                guard size <= sourceLimit else {
                    attachmentError = type.conforms(to: .image)
                        ? "This image is too large to process."
                        : "Files must be 10 MB or smaller."
                    continue
                }
                let data = try Data(contentsOf: url)
                addAttachment(name: url.lastPathComponent, typeIdentifier: type.identifier, data: data)
            }
        } catch {
            attachmentError = error.localizedDescription
        }
    }

    @ViewBuilder
    private func attachmentLabel(_ attachment: ReportConversationAttachment) -> some View {
        if UTType(attachment.typeIdentifier)?.conforms(to: .image) == true,
           let image = UIImage(data: attachment.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 120, alignment: .top)
                .background(VoxiverseColor.raisedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(VoxiverseColor.primaryAction, lineWidth: 2)
                }
                .shadow(color: VoxiverseColor.primaryAction.opacity(0.3), radius: 6)
        } else {
            HStack(spacing: 8) {
                VoxiverseAssetIcon(assetName: "document", size: 16, tint: VoxiverseColor.primaryAction)
                Text(attachment.name)
            }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryText)
                .lineLimit(1)
                .padding(10)
                .background(VoxiverseColor.raisedSurface, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func openAttachment(_ attachment: ReportConversationAttachment) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent(URL(fileURLWithPath: attachment.name).lastPathComponent)
            try attachment.data.write(to: url, options: .atomic)
            attachmentPreviewURL = url
        } catch {
            attachmentError = error.localizedDescription
        }
    }

    private var currentState: ReportConversationState {
        service.snapshot?.state ?? .notStarted
    }

    private var messages: [ReportConversationMessage] {
        service.displayedMessages
    }

    private var canCompose: Bool {
        currentState != .declined
    }

    private var currentStateLabel: String {
        switch currentState {
        case .notStarted:
            return "Not Started"
        case .invited:
            return "Invited"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        }
    }

    private func invitationPreviewButton(title: String, tint: Color) -> some View {
        Button {
            // Mirrors the reporter-facing invitation action on the Voxiverse staff side.
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    VoxiverseFrostedGlassMaterial(tint: tint, cornerRadius: 14)
                )
        }
        .buttonStyle(.plain)
    }

    private func conversationFrostedBadge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(VoxiverseColor.primaryText)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                VoxiverseFrostedGlassMaterial(tint: tint, cornerRadius: 9)
            )
    }

    private var stateAccent: Color {
        switch currentState {
        case .notStarted:
            return VoxiverseColor.indicator
        case .invited, .accepted:
            return VoxiverseColor.primaryAction
        case .declined:
            return VoxiverseColor.secondaryAccent
        }
    }
}

private struct VoxiverseConversationLoadingRing: View {
    private let bubbleCount = 12
    private let ringSize: CGFloat = 96
    private let bubbleSize: CGFloat = 14

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<bubbleCount, id: \.self) { index in
                    let phase = elapsed * 2.4 - Double(index) * 0.22
                    let pulse = 0.82 + CGFloat((sin(phase) + 1) * 0.09)

                    Circle()
                        .fill(Color.clear)
                        .frame(width: bubbleSize, height: bubbleSize)
                        .background(
                            VoxiverseFrostedGlassMaterial(
                                tint: VoxiverseFrostedPalette.color(at: index),
                                cornerRadius: bubbleSize / 2
                            )
                        )
                        .clipShape(Circle())
                        .scaleEffect(pulse)
                        .opacity(0.62 + Double(index % 3) * 0.16)
                        .offset(y: -(ringSize - bubbleSize) / 2)
                        .rotationEffect(.degrees(Double(index) * (360 / Double(bubbleCount))))
                }
            }
            .frame(width: ringSize, height: ringSize)
            .rotationEffect(.degrees(elapsed * 105))
        }
        .frame(width: ringSize, height: ringSize)
        .accessibilityLabel("Loading conversation")
    }
}

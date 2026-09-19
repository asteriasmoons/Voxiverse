//
//  VoxiverseReportConversationView.swift
//  Voxiverse
//

import SwiftUI

struct VoxiverseReportConversationView: View {
    let context: ReportConversationContext
    let onClose: () -> Void

    @StateObject private var service = VoxiverseReportConversationService()
    @State private var draft = ""
    @State private var isExpandedComposerPresented = false
    @FocusState private var isComposerFocused: Bool

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
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(context.reportID)
                .font(.system(size: 31, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryText)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            VoxiverseIconButton(assetName: "xmarkwavy", label: "Close", action: onClose)
        }
        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var content: some View {
        if service.isLoading && service.snapshot == nil {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(VoxiverseColor.primaryAction)
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
                        }
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 18)
                    }
                    .onChange(of: service.snapshot?.messages.count ?? 0) { _, _ in
                        if let lastID = service.snapshot?.messages.last?.id {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }

                if canCompose {
                    composer
                }
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
            VoxiverseSurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    VoxiverseFrostedGlassIcon(
                        assetName: "luvmail",
                        size: 30,
                        tint: VoxiverseFrostedPalette.blue
                    )
                    Text("No invitation sent yet")
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
        }
    }

    private func messageBubble(_ message: ReportConversationMessage) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.isFromStaff {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.isFromStaff ? .trailing : .leading, spacing: 5) {
                Text(message.isFromStaff ? "Voxiverse" : "Reporter")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(message.isFromStaff ? VoxiverseColor.primaryAction : VoxiverseColor.secondaryAccent)

                Text(message.body)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }
            .padding(13)
            .background(
                VoxiverseFrostedGlassMaterial(
                    tint: message.isFromStaff ? VoxiverseFrostedPalette.blue : VoxiverseFrostedPalette.purple,
                    cornerRadius: 18
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if !message.isFromStaff {
                Spacer(minLength: 40)
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $draft)
                    .focused($isComposerFocused)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .padding(.leading, 10)
                    .padding(.trailing, 42)
                    .padding(.vertical, 10)

                if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(currentState == .notStarted ? "Send the first invitation message…" : "Message the reporter…")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText.opacity(0.75))
                        .padding(.leading, 15)
                        .padding(.top, 18)
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
                .padding(.top, 7)
                .padding(.trailing, 7)
            }
            .frame(height: 116)
            .background(VoxiverseColor.raisedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(VoxiverseColor.primaryAction.opacity(0.46), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)

            VStack(spacing: 8) {
                Button {
                    // Attachment selection will be wired to the conversation transport separately.
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

                sendButton
            }
        }
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
        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isSending)
        .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isSending ? 0.45 : 1)
        .accessibilityLabel(currentState == .notStarted ? "Send invitation message" : "Send message")
    }

    private var expandedComposerSheet: some View {
        NavigationStack {
            ZStack {
                VoxiverseColor.background.ignoresSafeArea()

                TextEditor(text: $draft)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .background(VoxiverseColor.raisedSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(VoxiverseColor.primaryAction.opacity(0.46), lineWidth: 1)
                    )
                    .padding(VoxiverseSpacing.pageHorizontal)
            }
            .navigationTitle("Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isExpandedComposerPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        sendDraft()
                        isExpandedComposerPresented = false
                    } label: {
                        VoxiverseAssetIcon(assetName: "send", size: 20, tint: VoxiverseColor.primaryAction)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isSending)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func sendDraft() {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !service.isSending else { return }
        draft = ""
        Task { await service.sendStaffMessage(message, context: context) }
    }

    private var currentState: ReportConversationState {
        service.snapshot?.state ?? .notStarted
    }

    private var messages: [ReportConversationMessage] {
        service.snapshot?.messages ?? []
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

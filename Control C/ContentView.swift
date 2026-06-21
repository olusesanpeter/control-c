//
//  ContentView.swift
//  Control C
//
//  Created by Peter Olusesan on 20/06/2026.
//

import SwiftUI
import QuickLookThumbnailing
import QuickLookUI
import ServiceManagement

struct ContentView: View {
    let monitor: ClipboardMonitor
    @State private var screen: Screen = .main

    private enum Screen: Hashable { case main, settings }

    var body: some View {
        ZStack {
            switch screen {
            case .main:
                MainScreen(monitor: monitor) {
                    withAnimation(.smooth(duration: 0.25)) { screen = .settings }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            case .settings:
                SettingsScreen {
                    withAnimation(.smooth(duration: 0.25)) { screen = .main }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: 320)
    }
}

private struct MainScreen: View {
    let monitor: ClipboardMonitor
    let onOpenSettings: () -> Void

    @State private var hoveredItemID: ClipboardItem.ID?
    @State private var hasContentAbove = false
    @State private var hasContentBelow = false
    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if monitor.history.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    VStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Copy something to get started")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 140)
                    bottomBar
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(monitor.history) { item in
                            ClipboardCard(
                                item: item,
                                hoveredID: $hoveredItemID,
                                onCopy: { monitor.copy(item) },
                                onPreview: { ClipboardPreviewer.preview(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 38)
                    .padding(.bottom, 68)
                }
                .scrollIndicators(.never)
                .frame(maxHeight: 540)
                .overlay(alignment: .top) {
                    header.allowsHitTesting(false)
                }
                .overlay(alignment: .bottom) {
                    bottomBar
                }
                .onScrollGeometryChange(for: BarVisibility.self) { geometry in
                    let above = geometry.contentOffset.y > 2
                    let below = (geometry.contentOffset.y + geometry.containerSize.height) < (geometry.contentSize.height - 2)
                    return BarVisibility(above: above, below: below)
                } action: { _, state in
                    withAnimation(.smooth(duration: 0.22)) {
                        hasContentAbove = state.above
                        hasContentBelow = state.below
                    }
                }
            }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onKeyPress(.space) {
            guard let id = hoveredItemID,
                  let item = monitor.history.first(where: { $0.id == id })
            else { return .ignored }
            ClipboardPreviewer.preview(item)
            return .handled
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard history")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Color.clear.frame(height: 24)
        }
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: Rectangle())
        .mask {
            LinearGradient(
                stops: headerMaskStops,
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: 24)
            settingsRow
            quitRow
        }
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: Rectangle())
        .mask {
            LinearGradient(
                stops: bottomBarMaskStops,
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var headerMaskStops: [Gradient.Stop] {
        if hasContentAbove {
            return [
                .init(color: .black, location: 0.0),
                .init(color: .black, location: 0.5),
                .init(color: .black.opacity(0.85), location: 0.65),
                .init(color: .black.opacity(0.55), location: 0.78),
                .init(color: .black.opacity(0.25), location: 0.9),
                .init(color: .clear, location: 1.0),
            ]
        } else {
            return [
                .init(color: .black, location: 0.0),
                .init(color: .black, location: 0.5),
                .init(color: .black.opacity(0.85), location: 0.56),
                .init(color: .black.opacity(0.5), location: 0.6),
                .init(color: .black.opacity(0.15), location: 0.64),
                .init(color: .clear, location: 0.68),
                .init(color: .clear, location: 1.0),
            ]
        }
    }

    private var bottomBarMaskStops: [Gradient.Stop] {
        if hasContentBelow {
            return [
                .init(color: .clear, location: 0.0),
                .init(color: .black.opacity(0.25), location: 0.1),
                .init(color: .black.opacity(0.55), location: 0.22),
                .init(color: .black.opacity(0.85), location: 0.35),
                .init(color: .black, location: 0.5),
                .init(color: .black, location: 1.0),
            ]
        } else {
            return [
                .init(color: .clear, location: 0.0),
                .init(color: .clear, location: 0.18),
                .init(color: .black.opacity(0.15), location: 0.22),
                .init(color: .black.opacity(0.5), location: 0.26),
                .init(color: .black.opacity(0.85), location: 0.3),
                .init(color: .black, location: 0.35),
                .init(color: .black, location: 1.0),
            ]
        }
    }

    private var settingsRow: some View {
        Button(action: onOpenSettings) {
            HStack {
                Text("Settings")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .contentShape(Rectangle())
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var quitRow: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            HStack {
                Text("Quit")
                Spacer()
            }
            .contentShape(Rectangle())
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct SettingsScreen: View {
    let onBack: () -> Void

    @State private var openOnLaunch = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                    Text("Settings")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            Toggle(isOn: $openOnLaunch) {
                Text("Open on launch")
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .onChange(of: openOnLaunch) { _, newValue in
                LaunchAtLogin.set(enabled: newValue)
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 180)
        .onAppear { openOnLaunch = LaunchAtLogin.isEnabled }
    }
}

private struct BarVisibility: Equatable {
    let above: Bool
    let below: Bool
}

private struct ClipboardCard: View {
    let item: ClipboardItem
    @Binding var hoveredID: ClipboardItem.ID?
    let onCopy: () -> Void
    let onPreview: () -> Void

    @State private var isHovering = false
    @State private var isExpanded = false

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            thumbnail
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: thumbnailHeight)
                .frame(maxHeight: thumbnailMaxHeight)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isHovering ? Color.accentColor : Color.clear, lineWidth: 2)
                }
                .overlay(alignment: .bottomTrailing) {
                    if isHovering {
                        actions
                            .padding(8)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 8))
                .onDrag { dragItemProvider() }

            Text(Self.relativeFormatter.localizedString(for: item.timestamp, relativeTo: Date()))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                hoveredID = item.id
            } else if hoveredID == item.id {
                hoveredID = nil
            }
        }
    }

    private func dragItemProvider() -> NSItemProvider {
        switch item.kind {
        case .text(let string):
            return NSItemProvider(object: string as NSString)
        case .image(let data):
            if let nsImage = NSImage(data: data) {
                return NSItemProvider(object: nsImage)
            }
            return NSItemProvider()
        case .files(let urls):
            if let url = urls.first {
                return NSItemProvider(object: url as NSURL)
            }
            return NSItemProvider()
        }
    }

    private var thumbnailMaxHeight: CGFloat {
        if case .text = item.kind, isExpanded { return 380 }
        return 200
    }

    private func isTextTruncatable(_ string: String) -> Bool {
        string.components(separatedBy: "\n").count > 4 || string.count > 200
    }

    private var isText: Bool {
        if case .text = item.kind { return true }
        return false
    }

    private var thumbnailHeight: CGFloat? {
        switch item.kind {
        case .text, .image: return nil
        case .files: return 140
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch item.kind {
        case .text(let string):
            VStack(alignment: .leading, spacing: 4) {
                Text(string)
                    .font(.system(.callout, design: .monospaced))
                    .lineLimit(isExpanded ? nil : 4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                if isTextTruncatable(string) {
                    Button {
                        withAnimation(.smooth(duration: 0.2)) { isExpanded.toggle() }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .contentShape(Rectangle())
                            .frame(width: 20, height: 18)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
        case .image(let data):
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            } else {
                fallbackIcon("photo")
            }
        case .files(let urls):
            if let url = urls.first {
                FileThumbnailView(url: url, targetSize: CGSize(width: 296, height: 140))
                    .padding(8)
            } else {
                fallbackIcon("doc")
            }
        }
    }

    private func fallbackIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var actions: some View {
        HStack(spacing: 8) {
            if !isText {
                Button {
                    onPreview()
                } label: {
                    Text("Preview")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .shadow(color: .black.opacity(0.08), radius: 1.5, y: 0.5)
            }
            Button("Copy") {
                onCopy()
            }
            .buttonStyle(.borderedProminent)
            .shadow(color: .black.opacity(0.08), radius: 1.5, y: 0.5)
        }
        .controlSize(.small)
        .buttonBorderShape(.capsule)
    }
}

private struct FileThumbnailView: View {
    let url: URL
    var targetSize: CGSize = CGSize(width: 44, height: 44)

    @State private var thumbnail: NSImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .scaledToFit()
            }
        }
        .task(id: url) {
            thumbnail = await Self.generate(for: url, size: targetSize)
        }
    }

    private static func generate(for url: URL, size: CGSize) async -> NSImage? {
        let scale = await MainActor.run { NSScreen.main?.backingScaleFactor ?? 2.0 }
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )
        return await withCheckedContinuation { continuation in
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, _ in
                continuation.resume(returning: rep?.nsImage)
            }
        }
    }
}

private enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func set(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Control C launch-at-login error: \(error)")
        }
    }
}

private enum ClipboardPreviewer {
    static func preview(_ item: ClipboardItem) {
        let url: URL?
        switch item.kind {
        case .text(let string):
            url = writeTemp(data: Data(string.utf8), ext: "txt")
        case .image(let data):
            url = writeTemp(data: data, ext: imageExtension(for: data))
        case .files(let urls):
            url = urls.first
        }
        guard let url else {
            NSSound.beep()
            return
        }
        QuickLookCoordinator.shared.show(url: url)
    }

    private static func writeTemp(data: Data, ext: String) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("control-c-\(UUID().uuidString).\(ext)")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    private static func imageExtension(for data: Data) -> String {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" }
        return "tiff"
    }
}

private final class QuickLookPreviewItem: NSObject, QLPreviewItem {
    let url: URL
    init(url: URL) { self.url = url }
    var previewItemURL: URL? { url }
}

private final class QuickLookCoordinator: NSObject, QLPreviewPanelDataSource {
    static let shared = QuickLookCoordinator()
    private var item: QuickLookPreviewItem?

    func show(url: URL) {
        item = QuickLookPreviewItem(url: url)
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        item == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        item
    }
}

#Preview {
    ContentView(monitor: ClipboardMonitor())
}

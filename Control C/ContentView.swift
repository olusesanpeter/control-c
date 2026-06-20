//
//  ContentView.swift
//  Control C
//
//  Created by Peter Olusesan on 20/06/2026.
//

import SwiftUI
import QuickLookThumbnailing
import ServiceManagement

struct ContentView: View {
    let monitor: ClipboardMonitor
    @Environment(\.openSettings) private var openSettings
    @State private var isScrolled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
            Divider()
            settings
            footer
        }
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Text("Clipboard History")
                .font(.system(size: 13, weight: .medium))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            if isScrolled {
                Rectangle().fill(.thinMaterial)
            }
        }
        .overlay(alignment: .bottom) {
            if isScrolled {
                Divider()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if monitor.history.isEmpty {
            VStack(spacing: 0) {
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
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(monitor.history) { item in
                        ClipboardCard(
                            item: item,
                            onCopy: { monitor.copy(item) },
                            onPreview: { ClipboardPreviewer.preview(item) }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.top, 6)
            }
            .scrollIndicators(.never)
            .frame(maxHeight: 420)
            .safeAreaInset(edge: .top, spacing: 0) {
                header
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y > 4
            } action: { _, scrolled in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isScrolled = scrolled
                }
            }
        }
    }

    private var settings: some View {
        Button {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        } label: {
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

    private var footer: some View {
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

private struct ClipboardCard: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onPreview: () -> Void

    @State private var isHovering = false

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
                .onTapGesture { onCopy() }

            Text(Self.relativeFormatter.localizedString(for: item.timestamp, relativeTo: Date()))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onHover { isHovering = $0 }
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
            Text(string)
                .font(.system(.callout, design: .monospaced))
                .lineLimit(8)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
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

struct SettingsView: View {
    @State private var openOnLaunch: Bool = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Toggle("Open on launch", isOn: $openOnLaunch)
                .onChange(of: openOnLaunch) { _, newValue in
                    LaunchAtLogin.set(enabled: newValue)
                }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 160)
        .onAppear { openOnLaunch = LaunchAtLogin.isEnabled }
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
        switch item.kind {
        case .text(let string):
            openTemp(data: Data(string.utf8), ext: "txt")
        case .image(let data):
            openTemp(data: data, ext: imageExtension(for: data))
        case .files(let urls):
            urls.forEach { NSWorkspace.shared.open($0) }
        }
    }

    private static func openTemp(data: Data, ext: String) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("control-c-\(UUID().uuidString).\(ext)")
        do {
            try data.write(to: url)
            NSWorkspace.shared.open(url)
        } catch {
            NSSound.beep()
        }
    }

    private static func imageExtension(for data: Data) -> String {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" }
        return "tiff"
    }
}

#Preview {
    ContentView(monitor: ClipboardMonitor())
}

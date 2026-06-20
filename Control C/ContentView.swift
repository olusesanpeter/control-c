//
//  ContentView.swift
//  Control C
//
//  Created by Peter Olusesan on 20/06/2026.
//

import SwiftUI
import QuickLookThumbnailing

struct ContentView: View {
    let monitor: ClipboardMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
            Divider()
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
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private var content: some View {
        if monitor.history.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "doc.on.clipboard")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Copy something to get started")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 140)
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
        }
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
                .frame(height: isText ? nil : 140)
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
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
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

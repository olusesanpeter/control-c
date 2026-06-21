//
//  ClipboardMonitor.swift
//  Control C
//

import AppKit
import Observation

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let kind: Kind
    let timestamp: Date

    enum Kind: Equatable {
        case text(String)
        case image(Data)
        case files([URL])
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.kind == rhs.kind
    }
}

@Observable
final class ClipboardMonitor {
    private(set) var history: [ClipboardItem] = []

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let maxHistory = 50

    init() {
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func copy(_ item: ClipboardItem) {
        pasteboard.clearContents()
        switch item.kind {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let data):
            pasteboard.setData(data, forType: .tiff)
        case .files(let urls):
            pasteboard.writeObjects(urls as [NSURL])
        }
        lastChangeCount = pasteboard.changeCount

        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.4
            sound.play()
        }
    }

    func clear() {
        history.removeAll()
    }

    private func checkPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let kind = readKind() else { return }

        if let existing = history.firstIndex(where: { $0.kind == kind }) {
            history.remove(at: existing)
        }

        history.insert(ClipboardItem(kind: kind, timestamp: Date()), at: 0)

        if history.count > maxHistory {
            history.removeLast(history.count - maxHistory)
        }
    }

    private func readKind() -> ClipboardItem.Kind? {
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           !urls.isEmpty,
           urls.allSatisfy({ $0.isFileURL }) {
            return .files(urls)
        }

        if let data = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            return .image(data)
        }

        if let string = pasteboard.string(forType: .string),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .text(string)
        }

        return nil
    }
}

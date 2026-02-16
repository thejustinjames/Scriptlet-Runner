import Foundation

class ScriptScanner: ObservableObject {
    private let parser = ScriptParser()
    private let fileManager = FileManager.default

    func scan(locations: [ScanLocation]) -> [Script] {
        var scripts: [Script] = []

        for location in locations where location.isEnabled && location.exists {
            let found = scanDirectory(at: location.url, recursive: location.recursive)
            scripts.append(contentsOf: found)
        }

        return scripts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func scan(directory: URL, recursive: Bool = true) -> [Script] {
        scanDirectory(at: directory, recursive: recursive)
    }

    private func scanDirectory(at url: URL, recursive: Bool) -> [Script] {
        var scripts: [Script] = []

        var options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        if !recursive {
            options.insert(.skipsSubdirectoryDescendants)
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .isExecutableKey],
            options: options
        ) else {
            return scripts
        }

        while let fileURL = enumerator.nextObject() as? URL {
            if isShellScript(fileURL) {
                let script = parser.parse(scriptPath: fileURL.path)
                scripts.append(script)
            }
        }

        return scripts
    }

    private func isShellScript(_ url: URL) -> Bool {
        // Check extension
        if url.pathExtension == "sh" {
            return true
        }

        // Check if executable and has shebang
        guard fileManager.isExecutableFile(atPath: url.path) else {
            return false
        }

        guard let handle = FileHandle(forReadingAtPath: url.path) else {
            return false
        }

        defer { try? handle.close() }

        guard let data = try? handle.read(upToCount: 64),
              let header = String(data: data, encoding: .utf8) else {
            return false
        }

        return header.hasPrefix("#!/bin/bash") ||
               header.hasPrefix("#!/bin/sh") ||
               header.hasPrefix("#!/usr/bin/env bash") ||
               header.hasPrefix("#!/usr/bin/env sh") ||
               header.hasPrefix("#!/bin/zsh") ||
               header.hasPrefix("#!/usr/bin/env zsh")
    }
}

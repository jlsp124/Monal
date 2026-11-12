import Foundation

extension String {
    /// Count extended grapheme clusters, so families, flags and skin tones stay intact.
    var isShortEmojiMessage: Bool {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...3).contains(value.count) else { return false }
        return value.allSatisfy { character in
            let scalars = character.unicodeScalars
            // VS15 explicitly asks for text presentation.
            guard !scalars.contains(where: { $0.value == 0xFE0E }) else { return false }
            let keycap = scalars.contains(where: { $0.value == 0x20E3 })
            let hasEmojiBase = scalars.contains { $0.properties.isEmoji && ($0.value > 0x7F || keycap) }
            return hasEmojiBase && scalars.allSatisfy {
                $0.properties.isEmoji || $0.value == 0x200D || $0.value == 0xFE0F || $0.value == 0x20E3 || (0xE0020...0xE007F).contains($0.value)
            }
        }
    }

    func sanitizedFilename() -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*%?\"<>|")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)
        var sanitized = self.components(separatedBy: invalidCharacters).joined(separator: "_")

        if sanitized.isEmpty || sanitized == "." || sanitized == ".." {
            return "file"
        }

        if sanitized.unicodeScalars.count >= 255 {
            let fileExtension = (sanitized as NSString).pathExtension
            if fileExtension.isEmpty {
                sanitized = String(sanitized.prefix(63))
            } else {
                let fileBasename = (sanitized as NSString).deletingPathExtension
                sanitized = String(fileBasename.prefix(54) + "." + fileExtension.prefix(8))
            }
        }

        return sanitized
    }
}

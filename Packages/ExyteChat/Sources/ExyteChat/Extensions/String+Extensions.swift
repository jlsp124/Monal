import Foundation

extension String {
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

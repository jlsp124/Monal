//
//  ChatLocalization.swift
//  Chat
//
//  Created by Aman Kumar on 18/12/24.
//

import Foundation

public struct ChatLocalization: Hashable {
    public var inputPlaceholder: String
    public var signatureText: String
    public var cancelButtonText: String
    public var recentToggleText: String
    public var waitingForNetwork: String
    public var recordingText: String
    public var replyToText: String
    public var attachMediaText: String
    public var attachFileText: String
    public var attachGifText: String
    public var attachCameraText: String
    public var attachLocationText: String
    public var missingLocationPermissionTitle: String
    public var missingLocationPermissionText: String
    public var sendLocationText: String
    public var shareLiveLocationText: String
    public var stopSharingLocationText: String
    public var liveLocationText: String
    public var liveLocationEndedText: String
    public var liveLocationUpdatedJustNowText: String
    /// Format string with a single `%d` placeholder for the number of minutes, e.g. "updated %d min ago"
    public var liveLocationUpdatedMinutesAgoFormat: String
    public var openInMapsText: String
    public var unknownSize: String
    public var unknownFileType: String

    public init(
        inputPlaceholder: String,
        signatureText: String,
        cancelButtonText: String,
        recentToggleText: String,
        waitingForNetwork: String,
        recordingText: String,
        replyToText: String,
        attachMediaText: String = String(localized: "Media"),
        attachFileText: String = String(localized: "File"),
        attachGifText: String = String(localized: "GIF"),
        attachCameraText: String = String(localized: "Camera"),
        attachLocationText: String = String(localized: "Location"),
        missingLocationPermissionTitle: String = String(localized: "Location Access Needed"),
        missingLocationPermissionText: String = String(localized: "Monal does not have access to your location. Please update the location access in your device's Privacy Settings."),
        sendLocationText: String = String(localized: "Send this location"),
        shareLiveLocationText: String = String(localized: "Share Live Location"),
        stopSharingLocationText: String = String(localized: "Stop Sharing"),
        liveLocationText: String = String(localized: "Live Location"),
        liveLocationEndedText: String = String(localized: "Live location ended"),
        liveLocationUpdatedJustNowText: String = String(localized: "updated just now"),
        liveLocationUpdatedMinutesAgoFormat: String = String(localized: "updated %d min ago"),
        openInMapsText: String = String(localized: "Open in Maps"),
        unknownSize: String = String(localized: "Unknown size"),
        unknownFileType: String = String(localized: "Unknown file type")
    ) {
        self.inputPlaceholder = inputPlaceholder
        self.signatureText = signatureText
        self.cancelButtonText = cancelButtonText
        self.recentToggleText = recentToggleText
        self.waitingForNetwork = waitingForNetwork
        self.recordingText = recordingText
        self.replyToText = replyToText
        self.attachMediaText = attachMediaText
        self.attachFileText = attachFileText
        self.attachGifText = attachGifText
        self.attachCameraText = attachCameraText
        self.attachLocationText = attachLocationText
        self.missingLocationPermissionTitle = missingLocationPermissionTitle
        self.missingLocationPermissionText = missingLocationPermissionText
        self.sendLocationText = sendLocationText
        self.shareLiveLocationText = shareLiveLocationText
        self.stopSharingLocationText = stopSharingLocationText
        self.liveLocationText = liveLocationText
        self.liveLocationEndedText = liveLocationEndedText
        self.liveLocationUpdatedJustNowText = liveLocationUpdatedJustNowText
        self.liveLocationUpdatedMinutesAgoFormat = liveLocationUpdatedMinutesAgoFormat
        self.openInMapsText = openInMapsText
        self.unknownSize = unknownSize
        self.unknownFileType = unknownFileType
    }

   public static var defaultLocalization: ChatLocalization {
        ChatLocalization(
            inputPlaceholder: String(localized: "Type a message..."),
            signatureText: String(localized: "Add signature..."),
            cancelButtonText: String(localized: "Cancel"),
            recentToggleText: String(localized: "Recents"),
            waitingForNetwork: String(localized: "Waiting for network"),
            recordingText: String(localized: "Recording..."),
            replyToText: String(localized: "Reply to"),
            attachMediaText: String(localized: "Media"),
            attachFileText: String(localized: "File"),
            attachGifText: String(localized: "GIF"),
            attachCameraText: String(localized: "Camera"),
            attachLocationText: String(localized: "Location"),
            missingLocationPermissionTitle: String(localized: "Location Access Needed"),
            missingLocationPermissionText: String(localized: "Monal does not have access to your location. Please update the location access in your device's Privacy Settings."),
            sendLocationText: String(localized: "Send this location"),
            shareLiveLocationText: String(localized: "Share Live Location"),
            stopSharingLocationText: String(localized: "Stop Sharing"),
            liveLocationText: String(localized: "Live Location"),
            liveLocationEndedText: String(localized: "Live location ended"),
            liveLocationUpdatedJustNowText: String(localized: "updated just now"),
            liveLocationUpdatedMinutesAgoFormat: String(localized: "updated %d min ago"),
            openInMapsText: String(localized: "Open in Maps"),
            unknownSize: String(localized: "Unknown size"),
            unknownFileType: String(localized: "Unknown file type")
        )
    }
}

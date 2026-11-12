//
//  StaticLocation.swift
//  Chat
//

import Foundation
import CoreLocation

/// A single static location - latitude/longitude.
public struct StaticLocation: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public extension StaticLocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    init?(geoURIString input: String) {
        let geoPattern = /^geo:(?<lat>-?(?:90|[1-8][0-9]|[0-9])(?:\.[0-9]{1,32})?),(?<lon>-?(?:180|1[0-7][0-9]|[0-9]{1,2})(?:\.[0-9]{1,32})?)(;.*)?([?].*)?$/
            .ignoresCase()
        guard let match = input.wholeMatch(of: geoPattern),
            let latitude = Double(match.lat),
            let longitude = Double(match.lon) else {
            print("Couldn't extract location from string '\(input)'")
            return nil
        }
        self.init(latitude: latitude, longitude: longitude)
    }
}

import Foundation
#if os(macOS)
    import PostboxMac
    import TelegramApiMac
#else
    import Postbox
    import TelegramApi
#endif

public final class NamedGeoPlace: PostboxCoding, Equatable {
    public let country: String?
    public let state: String?
    public let city: String?
    public let district: String?
    public let street: String?
    
    public init(country: String?, state: String?, city: String?, district: String?, street: String?) {
        self.country = country
        self.state = state
        self.city = city
        self.district = district
        self.street = street
    }
    
    public init(decoder: PostboxDecoder) {
        self.country = decoder.decodeOptionalStringForKey("gp_co")
        self.state = decoder.decodeOptionalStringForKey("gp_sta")
        self.city = decoder.decodeOptionalStringForKey("gp_ci")
        self.district = decoder.decodeOptionalStringForKey("gp_dis")
        self.street = decoder.decodeOptionalStringForKey("gp_str")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        if let country = self.country {
            encoder.encodeString(country, forKey: "gp_co")
        }
        
        if let state = self.state {
            encoder.encodeString(state, forKey: "gp_sta")
        }
        
        if let city = self.city {
            encoder.encodeString(city, forKey: "gp_ci")
        }
        
        if let district = self.district {
            encoder.encodeString(district, forKey: "gp_dis")
        }
        
        if let street = self.street {
            encoder.encodeString(street, forKey: "gp_str")
        }
    }
    
    public static func ==(lhs: NamedGeoPlace, rhs: NamedGeoPlace) -> Bool {
        if lhs.country != rhs.country {
            return false
        }
        if lhs.state != rhs.state {
            return false
        }
        if lhs.city != rhs.city {
            return false
        }
        if lhs.district != rhs.district {
            return false
        }
        if lhs.street != rhs.street {
            return false
        }
        return true
    }
}

public final class MapVenue: PostboxCoding, Equatable {
    public let title: String
    public let address: String?
    public let provider: String?
    public let id: String?
    public let type: String?
    
    public init(title: String, address: String?, provider: String?, id: String?, type: String?) {
        self.title = title
        self.address = address
        self.provider = provider
        self.id = id
        self.type = type
    }
    
    public init(decoder: PostboxDecoder) {
        self.title = decoder.decodeStringForKey("ti", orElse: "")
        self.address = decoder.decodeOptionalStringForKey("ad")
        self.provider = decoder.decodeOptionalStringForKey("pr")
        self.id = decoder.decodeOptionalStringForKey("id")
        self.type = decoder.decodeOptionalStringForKey("ty")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeString(self.title, forKey: "ti")
        
        if let address = self.address {
            encoder.encodeString(address, forKey: "ad")
        } else {
            encoder.encodeNil(forKey: "ad")
        }
        if let provider = self.provider {
            encoder.encodeString(provider, forKey: "pr")
        } else {
            encoder.encodeNil(forKey: "pr")
        }
        if let id = self.id {
            encoder.encodeString(id, forKey: "id")
        } else {
            encoder.encodeNil(forKey: "id")
        }
        if let type = self.type {
            encoder.encodeString(type, forKey: "ty")
        } else {
            encoder.encodeNil(forKey: "ty")
        }
    }
    
    public static func ==(lhs: MapVenue, rhs: MapVenue) -> Bool {
        if lhs.address != rhs.address {
            return false
        }
        if lhs.provider != rhs.provider {
            return false
        }
        if lhs.id != rhs.id {
            return false
        }
        if lhs.type != rhs.type {
            return false
        }
        return true
    }
}

public final class TelegramMediaMap: Media {
    public let latitude: Double
    public let longitude: Double
    public let geoPlace: NamedGeoPlace?
    public let venue: MapVenue?
    public let liveBroadcastingTimeout: Int32?
    
    public let id: MediaId? = nil
    public let peerIds: [PeerId] = []
    
    public init(latitude: Double, longitude: Double, geoPlace: NamedGeoPlace?, venue: MapVenue?, liveBroadcastingTimeout: Int32?) {
        self.latitude = latitude
        self.longitude = longitude
        self.geoPlace = geoPlace
        self.venue = venue
        self.liveBroadcastingTimeout = liveBroadcastingTimeout
    }
    
    public init(decoder: PostboxDecoder) {
        self.latitude = decoder.decodeDoubleForKey("la", orElse: 0.0)
        self.longitude = decoder.decodeDoubleForKey("lo", orElse: 0.0)
        self.geoPlace = decoder.decodeObjectForKey("gp", decoder: { NamedGeoPlace(decoder: $0) }) as? NamedGeoPlace
        self.venue = decoder.decodeObjectForKey("ve", decoder: { MapVenue(decoder: $0) }) as? MapVenue
        self.liveBroadcastingTimeout = decoder.decodeOptionalInt32ForKey("bt")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeDouble(self.latitude, forKey: "la")
        encoder.encodeDouble(self.longitude, forKey: "lo")
        if let geoPlace = self.geoPlace {
            encoder.encodeObject(geoPlace, forKey: "gp")
        } else {
            encoder.encodeNil(forKey: "gp")
        }
        if let venue = self.venue {
            encoder.encodeObject(venue, forKey: "ve")
        } else {
            encoder.encodeNil(forKey: "ve")
        }
        if let liveBroadcastingTimeout = self.liveBroadcastingTimeout {
            encoder.encodeInt32(liveBroadcastingTimeout, forKey: "bt")
        } else {
            encoder.encodeNil(forKey: "bt")
        }
    }
    
    public func isEqual(to other: Media) -> Bool {
        if let other = other as? TelegramMediaMap {
            if self.latitude != other.latitude || self.longitude != other.longitude {
                return false
            }
            if self.geoPlace != other.geoPlace {
                return false
            }
            if self.venue != other.venue {
                return false
            }
            if self.liveBroadcastingTimeout != other.liveBroadcastingTimeout {
                return false
            }
            return true
        }
        return false
    }
    
    public func isSemanticallyEqual(to other: Media) -> Bool {
        return self.isEqual(to: other)
    }
}

func telegramMediaMapFromApiGeoPoint(_ geo: Api.GeoPoint, title: String?, address: String?, provider: String?, venueId: String?, venueType: String?, liveBroadcastingTimeout: Int32?) -> TelegramMediaMap {
    var venue: MapVenue?
    if let title = title {
        venue = MapVenue(title: title, address: address, provider: provider, id: venueId, type: venueType)
    }
    switch geo {
        case let .geoPoint(long, lat, _):
            return TelegramMediaMap(latitude: lat, longitude: long, geoPlace: nil, venue: venue, liveBroadcastingTimeout: liveBroadcastingTimeout)
        case .geoPointEmpty:
            return TelegramMediaMap(latitude: 0.0, longitude: 0.0, geoPlace: nil, venue: venue, liveBroadcastingTimeout: liveBroadcastingTimeout)
    }
}

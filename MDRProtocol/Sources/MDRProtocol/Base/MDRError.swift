import Foundation

public enum MDRError: Error, Equatable, Sendable {
    case notEnoughData
    case invalidChecksum
    case timeout
    case badMarker
    case protocolError(String)
    case invalidValue(String)
}

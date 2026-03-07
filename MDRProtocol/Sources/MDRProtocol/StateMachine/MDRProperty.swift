import Foundation

/// A property with desired/current value tracking for dirty-checking.
/// Matches C++ `MDRProperty<T>` from Headphones.hpp.
public struct MDRProperty<T: Equatable & Sendable>: Equatable, Sendable {
    public var desired: T
    public var current: T

    public init(_ value: T) {
        desired = value
        current = value
    }

    public var isDirty: Bool { desired != current }

    public mutating func overwrite(_ value: T) {
        desired = value
        current = value
    }

    public mutating func commit() {
        current = desired
    }
}

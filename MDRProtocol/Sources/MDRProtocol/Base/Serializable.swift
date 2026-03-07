import Foundation

/// Protocol for types that can be serialized to/from binary data.
/// Replaces C++ `MDRIsSerializable` concept + `Serialize`/`Deserialize` functions.
public protocol MDRSerializable: Sendable {
    func serialize(to writer: inout DataWriter)
    static func deserialize(from reader: inout DataReader) throws -> Self
}

/// Protocol for sub-types that can be read/written within a larger struct.
/// Replaces C++ `MDRIsReadWritable` concept + `Read`/`Write` functions.
public protocol MDRReadWritable: Sendable {
    static func read(from reader: inout DataReader) throws -> Self
    func write(to writer: inout DataWriter)
}

// Convenience: every MDRReadWritable is also MDRSerializable
extension MDRReadWritable {
    public func serialize(to writer: inout DataWriter) {
        self.write(to: &writer)
    }
}

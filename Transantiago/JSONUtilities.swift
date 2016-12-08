// from json2swift. https://github.com/ijoshsmith/json2swift

import Foundation

/// Adopted by a type that can be instantiated from JSON data.
protocol CreatableFromJSON {
    /// Attempts to configure a new instance of the conforming type with values from a JSON dictionary.
    init?(json: [String: Any])
}

extension CreatableFromJSON {
    /// Attempts to configure a new instance using a JSON dictionary selected by the `key` argument.
    init?(json: [String: Any], key: String) {
        guard let jsonDictionary = json[key] as? [String: Any] else { return nil }
        self.init(json: jsonDictionary)
    }
    
    /// Attempts to produce an array of instances of the conforming type based on an array in the JSON dictionary.
    /// - Returns: `nil` if the JSON array is missing or if there is an invalid/null element in the JSON array.
    static func createRequiredInstances(from json: [String: Any], arrayKey: String) -> [Self]? {
        guard let jsonDictionaries = json[arrayKey] as? [[String: Any]] else { return nil }
        return createRequiredInstances(from: jsonDictionaries)
    }
    
    /// Attempts to produce an array of instances of the conforming type based on an array of JSON dictionaries.
    /// - Returns: `nil` if there is an invalid/null element in the JSON array.
    static func createRequiredInstances(from jsonDictionaries: [[String: Any]]) -> [Self]? {
        var array = [Self]()
        for jsonDictionary in jsonDictionaries {
            guard let instance = Self.init(json: jsonDictionary) else { return nil }
            array.append(instance)
        }
        return array
    }
    
    /// Attempts to produce an array of instances of the conforming type, or `nil`, based on an array in the JSON dictionary.
    /// - Returns: `nil` if the JSON array is missing, or an array with `nil` for each invalid/null element in the JSON array.
    static func createOptionalInstances(from json: [String: Any], arrayKey: String) -> [Self?]? {
        guard let array = json[arrayKey] as? [Any] else { return nil }
        return createOptionalInstances(from: array)
    }
    
    /// Attempts to produce an array of instances of the conforming type, or `nil`, based on an array.
    /// - Returns: An array of instances of the conforming type and `nil` for each invalid/null element in the source array.
    static func createOptionalInstances(from array: [Any]) -> [Self?] {
        return array.map { item in
            if let jsonDictionary = item as? [String: Any] {
                return Self.init(json: jsonDictionary)
            }
            else {
                return nil
            }
        }
    }
}

extension Date {
    // Date formatters are cached because they are expensive to create. All cache access is performed on a serial queue.
    private static let cacheQueue = DispatchQueue(label: "DateFormatterCacheQueue")
    private static var formatterCache = [String: DateFormatter]()
    private static func dateFormatter(with format: String) -> DateFormatter {
        if let formatter = formatterCache[format] { return formatter }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)! // UTC is assumed, but won't interfere with a format-specified time zone.
        formatterCache[format] = formatter
        return formatter
    }
    
    static func parse(string: String, format: String) -> Date? {
        var formatter: DateFormatter!
        cacheQueue.sync { formatter = dateFormatter(with: format) }
        return formatter.date(from: string)
    }
    
    init?(json: [String: Any], key: String, format: String) {
        guard let string = json[key] as? String else { return nil }
        guard let date = Date.parse(string: string, format: format) else { return nil }
        self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
    }
}

extension URL {
    init?(json: [String: Any], key: String) {
        guard let string = json[key] as? String else { return nil }
        self.init(string: string)
    }
}

extension Double {
    init?(json: [String: Any], key: String) {
        // Explicitly unboxing the number allows an integer to be converted to a double,
        // which is needed when a JSON attribute value can have either representation.
        guard let nsNumber = json[key] as? NSNumber else { return nil }
        self.init(_: nsNumber.doubleValue)
    }
}

extension Array where Element: NSNumber {
    // Convert integers to doubles, for example [1, 2.0] becomes [1.0, 2.0]
    // This is necessary because ([1, 2.0] as? [Double]) yields nil.
    func toDoubleArray() -> [Double] {
        return map { $0.doubleValue }
    }
}

extension Array where Element: CustomStringConvertible {
    func toDateArray(withFormat format: String) -> [Date]? {
        var dateArray = [Date]()
        for string in self {
            guard let date = Date.parse(string: String(describing: string), format: format) else { return nil }
            dateArray.append(date)
        }
        return dateArray
    }
    
    func toURLArray() -> [URL]? {
        var urlArray = [URL]()
        for string in self {
            guard let url = URL(string: String(describing: string)) else { return nil }
            urlArray.append(url)
        }
        return urlArray
    }
}

extension Array where Element: Any {
    func toOptionalValueArray<Value>() -> [Value?] {
        return map { ($0 is NSNull) ? nil : ($0 as? Value) }
    }
    
    func toOptionalDateArray(withFormat format: String) -> [Date?] {
        return map { item in
            guard let string = item as? String else { return nil }
            return Date.parse(string: string, format: format)
        }
    }
    
    func toOptionalDoubleArray() -> [Double?] {
        return map { item in
            guard let nsNumber = item as? NSNumber else { return nil }
            return nsNumber.doubleValue
        }
    }
    
    func toOptionalURLArray() -> [URL?] {
        return map { item in
            guard let string = item as? String else { return nil }
            return URL(string: string)
        }
    }
}

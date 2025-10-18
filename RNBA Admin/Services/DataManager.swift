//
//  DataManager.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 15.10.25.
//  Data persistence manager with cache and JSON storage
//

import Foundation

/// Data persistence manager combining NSCache and JSON file storage
/// Provides fast access during sessions with persistent storage across app launches
@available(iOS 14.0, *)
class DataManager {
    
    // MARK: - Properties
    
    /// Session cache for fast access
    private let cache = NSCache<NSString, AnyObject>()
    
    /// File manager for JSON storage
    private let fileManager = FileManager.default
    
    /// Documents directory URL
    private lazy var documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    // MARK: - Cache Methods
    
    /// Store object in session cache
    func setCache<T: Codable>(_ object: T, forKey key: String) {
        cache.setObject(object as AnyObject, forKey: key as NSString)
    }
    
    /// Retrieve object from session cache
    func getCache<T: Codable>(forKey key: String) -> T? {
        return cache.object(forKey: key as NSString) as? T
    }
    
    /// Remove object from session cache
    func removeCache(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    /// Clear all cache
    func clearCache() {
        cache.removeAllObjects()
    }
    
    // MARK: - Persistent Storage Methods
    
    /// Save object to JSON file
    func saveToDisk<T: Codable>(_ object: T, filename: String) throws {
        let fileURL = documentsURL.appendingPathComponent("\(filename).json")
        
        // Create directory if needed
        try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
        
        let data = try JSONEncoder().encode(object)
        try data.write(to: fileURL)
        
        print("📁 DataManager: Saved \(filename).json")
    }
    
    /// Load object from JSON file
    func loadFromDisk<T: Codable>(filename: String) throws -> T {
        let fileURL = documentsURL.appendingPathComponent("\(filename).json")
        let data = try Data(contentsOf: fileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let object = try decoder.decode(T.self, from: data)
        print("📁 DataManager: Loaded \(filename).json")
        
        return object
    }
    
    /// Check if JSON file exists
    func fileExists(filename: String) -> Bool {
        let fileURL = documentsURL.appendingPathComponent("\(filename).json")
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Delete JSON file
    func deleteFile(filename: String) throws {
        let fileURL = documentsURL.appendingPathComponent("\(filename).json")
        try fileManager.removeItem(at: fileURL)
        print("🗑️ DataManager: Deleted \(filename).json")
    }
    
    // MARK: - Combined Methods (Primary Interface)
    
    /// Store object in both cache and disk
    func set<T: Codable>(_ object: T, forKey key: String) throws {
        // Save to cache first (fast access)
        setCache(object, forKey: key)
        // Save to disk (persistence)
        try saveToDisk(object, filename: key)
    }
    
    /// Retrieve object from cache first, then disk
    func get<T: Codable>(forKey key: String) -> T? {
        // Try cache first (fast)
        if let cached: T = getCache(forKey: key) {
            print("⚡ DataManager: Cache hit for \(key)")
            return cached
        }
        
        // Try disk (persistent)
        if fileExists(filename: key) {
            if let loaded: T = try? loadFromDisk(filename: key) {
                // Populate cache for future access
                setCache(loaded, forKey: key)
                print("💾 DataManager: Disk hit for \(key)")
                return loaded
            }
        }
        
        print("❌ DataManager: No data for \(key)")
        return nil
    }
    
    /// Check if data exists (cache or disk)
    func exists(forKey key: String) -> Bool {
        return cache.object(forKey: key as NSString) != nil || fileExists(filename: key)
    }
    
    /// Remove from both cache and disk
    func invalidate(forKey key: String) {
        removeCache(forKey: key)
        try? deleteFile(filename: key)
        print("🗑️ DataManager: Invalidated \(key)")
    }
    
    /// Clear all data (cache and disk)
    func clearAll() {
        clearCache()
        
        // Delete all JSON files in documents directory
        if let files = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "json" {
                try? fileManager.removeItem(at: file)
            }
        }
        
        print("🧹 DataManager: Cleared all data")
    }
    
    // MARK: - Cache with Expiry
    
    /// Store object with expiry time
    func setCache<T: Codable>(_ object: T, forKey key: String, expiresIn seconds: TimeInterval) {
        let expiryData = CacheData(object: object, expiryDate: Date().addingTimeInterval(seconds))
        cache.setObject(expiryData as AnyObject, forKey: key as NSString)
    }
    
    /// Get object from cache, checking expiry
    func getCacheWithExpiry<T: Codable>(forKey key: String) -> T? {
        guard let cacheData = cache.object(forKey: key as NSString) as? CacheData<T> else {
            return nil
        }
        
        // Check if expired
        if Date() > cacheData.expiryDate {
            removeCache(forKey: key)
            return nil
        }
        
        return cacheData.object
    }
    
    /// Store with expiry (cache + disk)
    func set<T: Codable>(_ object: T, forKey key: String, expiresIn seconds: TimeInterval) throws {
        // Cache with expiry
        setCache(object, forKey: key, expiresIn: seconds)
        // Disk (no expiry, can be used as fallback)
        try saveToDisk(object, filename: key)
        
        // Also save expiry timestamp
        let expiryInfo = ["timestamp": Date().addingTimeInterval(seconds)]
        try saveToDisk(expiryInfo, filename: "\(key)_expiry")
    }
    
    /// Get with expiry check (cache first, then disk)
    func get<T: Codable>(forKey key: String, maxAge: TimeInterval? = nil) -> T? {
        // Try cache with expiry
        if let maxAge = maxAge, let cached: T = getCacheWithExpiry(forKey: key) {
            return cached
        }
        
        // Check disk expiry if maxAge specified
        if let maxAge = maxAge,
           let expiryInfo: [String: Date] = try? loadFromDisk(filename: "\(key)_expiry"),
           let expiryDate = expiryInfo["timestamp"],
           Date() > expiryDate {
            // Expired, remove
            invalidate(forKey: key)
            try? deleteFile(filename: "\(key)_expiry")
            return nil
        }
        
        // Try disk
        return get(forKey: key)
    }
}

// MARK: - Cache Data Wrapper

private class CacheData<T> {
    let object: T
    let expiryDate: Date
    
    init(object: T, expiryDate: Date) {
        self.object = object
        self.expiryDate = expiryDate
    }
}

// MARK: - Cache Keys

@available(iOS 14.0, *)
extension DataManager {
    enum CacheKey {
        static let dashboardStats = "dashboard_stats"
        static let registrations = "registrations_event_2024"
        static func visitorData(registrationID: Int64) -> String {
            return "visitor_data_reg_\(registrationID)"
        }
        static let visitTypes = "visit_types"
        static let foodTypes = "food_types"
        
        // Timestamps
        static func timestamp(for key: String) -> String {
            return "\(key)_timestamp"
        }
        static func expiry(for key: String) -> String {
            return "\(key)_expiry"
        }
    }
}

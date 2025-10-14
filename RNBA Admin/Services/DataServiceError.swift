//
//  DataServiceError.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import Foundation

/// Error types for data service operations
@available(iOS 14.0, *)
enum DataServiceError: LocalizedError {
    case registrationCreationFailed
    case invalidData
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .registrationCreationFailed:
            return "Failed to create registration"
        case .invalidData:
            return "Invalid data provided"
        case .networkError:
            return "Network connection error"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

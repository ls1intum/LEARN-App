//
//  SearchHistory.swift
//  Master
//
//  Created by Minkyoung Park on 15.10.25.
//

import Foundation

// MARK: - Domain Models

struct SearchHistory: Identifiable {
    let id: Int
    let searchCriteria: SearchCriteria
    let resultsCount: Int
    let createdAt: Date
    let name: String?
}

struct SearchCriteria: Codable {
    let targetAge: Int?
    let targetDuration: Int?
    let availableResources: [String]?
    let preferredTopics: [String]?
    let priorityCategories: [String]?
    let includeBreaks: Bool?
    let limit: Int?
    let maxActivityCount: Int?
    
    // Computed properties for display
    var gradeText: String {
        guard let age = targetAge else { return "Alle Klassen" }
        let grade = age - 5 // Convert age to grade (6->1, 7->2, etc.)
        return "Klasse \(grade)"
    }
    
    var durationText: String {
        guard let duration = targetDuration else { return "Alle Dauern" }
        return "\(duration) Minuten"
    }
    
    var topicsText: String {
        guard let topics = preferredTopics, !topics.isEmpty else { return "Alle Themen" }
        return topics.joined(separator: ", ")
    }
    
    var devicesText: String {
        guard let devices = availableResources, !devices.isEmpty else { return "Alle Geräte" }
        return devices.joined(separator: ", ")
    }
    
    var summaryText: String {
        let parts = [gradeText, durationText]
        return parts.joined(separator: " • ")
    }
}

// MARK: - DTOs

struct SearchHistoryResponseDTO: Decodable {
    let searchHistory: [SearchHistoryDTO]
    let pagination: PaginationDTO
    
    func toDomain() -> [SearchHistory] {
        return searchHistory.map { $0.toDomain() }
    }
}

struct SearchHistoryDeleteResponseDTO: Decodable {
    let message: String
}

struct SearchHistoryDTO: Decodable {
    let id: Int
    let searchCriteria: SearchCriteriaDTO
    let createdAt: String
}

struct SearchCriteriaDTO: Decodable {
    let targetAge: String?
    let targetDuration: String?
    let availableResources: String?
    let preferredTopics: String?
    let priorityCategories: String?
    let includeBreaks: String?
    let limit: String?
    let maxActivityCount: String?
}

// MARK: - Mappers

extension SearchHistoryDTO {
    func toDomain() -> SearchHistory {
        print("🔍 Parsing date: \(createdAt)")
        
        // Parse the date string from backend: "2025-10-16T15:53:15.804344"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Assume UTC
        
        let parsedDate = dateFormatter.date(from: createdAt) ?? Date()
        print("🔍 Parsed date: \(parsedDate)")
        
        return SearchHistory(
            id: id,
            searchCriteria: searchCriteria.toDomain(),
            resultsCount: 0, // Not provided in backend response
            createdAt: parsedDate,
            name: nil // Not provided in backend response
        )
    }
}

extension SearchCriteriaDTO {
    func toDomain() -> SearchCriteria {
        return SearchCriteria(
            targetAge: targetAge.flatMap(Int.init),
            targetDuration: targetDuration.flatMap(Int.init),
            availableResources: availableResources?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            preferredTopics: preferredTopics?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            priorityCategories: priorityCategories?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            includeBreaks: includeBreaks.flatMap { $0.lowercased() == "true" },
            limit: limit.flatMap(Int.init),
            maxActivityCount: maxActivityCount.flatMap(Int.init)
        )
    }
}

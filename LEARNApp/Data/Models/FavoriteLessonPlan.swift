//
//  FavoriteLessonPlan.swift
//  Master
//
//  Created by Minkyoung Park on 15.10.25.
//

import Foundation

// MARK: - Domain Models

struct FavoriteLessonPlan: Identifiable {
    let id: Int                     // Favorite record ID (for deletion)
    let name: String?
    let activities: [Material]
    let totalDuration: Int
    let searchCriteria: [String: String]?
    let createdAt: Date?
}

struct FavoriteLessonPlanRequest: Codable {
    let activityIds: [Int]  // Array of activity IDs
    let lessonPlan: LessonPlanMetadata
    let name: String?  // Optional name at top level
    
    enum CodingKeys: String, CodingKey {
        case activityIds = "activity_ids"
        case lessonPlan = "lesson_plan"
        case name
    }
}

struct LessonPlanMetadata: Codable {
    let name: String?
    let searchCriteria: [String: String]?
    let totalDuration: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case searchCriteria = "search_criteria"
        case totalDuration = "total_duration"
    }
}

struct LessonPlanPDFRequest: Codable {
    let activities: [ActivityForPDF]  // Array of full activity objects
    let searchCriteria: [String: String]  // Moved to top level
    let name: String?  // Optional name at top level
    
    enum CodingKeys: String, CodingKey {
        case activities
        case searchCriteria = "search_criteria"
        case name
    }
}

struct ActivityForPDF: Codable {
    let id: Int
    let title: String
    let category: String
    let grade: Int
    let gradeMin: Int?
    let gradeMax: Int?
    let duration: Int
    let devices: [String]
    let topics: [String]
    let ageMin: Int?
    let ageMax: Int?
    let durationMax: Int?
    let prepTimeMinutes: Int?
    let cleanupTimeMinutes: Int?
    let breakAfter: Int?
    let mentalLoad: String?
    let physicalEnergy: String?
    let bloomLevel: String?
    let source: String?
    let documentId: String?
}

extension Material {
    func toActivityForPDF() -> ActivityForPDF {
        return ActivityForPDF(
            id: self.id,
            title: self.title,
            category: self.category,
            grade: self.grade,
            gradeMin: self.gradeMin,
            gradeMax: self.gradeMax,
            duration: self.duration,
            devices: self.devices,
            topics: self.topics,
            ageMin: self.ageMin,
            ageMax: self.ageMax,
            durationMax: self.durationMax,
            prepTimeMinutes: self.prepTimeMinutes,
            cleanupTimeMinutes: self.cleanupTimeMinutes,
            breakAfter: self.breakAfter,
            mentalLoad: self.mentalLoad?.rawValue,
            physicalEnergy: self.physicalEnergy?.rawValue,
            bloomLevel: self.bloomLevel,
            source: self.source,
            documentId: self.documentId
        )
    }
}


// MARK: - DTOs

struct FavoriteLessonPlanRecordDTO: Decodable {
    let id: Int
    let activityIds: [Int]  // snake_case auto-converted
    let lessonPlan: LessonPlanMetadataDTO  // snake_case auto-converted
    let favouriteType: String  // snake_case auto-converted
    let createdAt: String  // snake_case auto-converted
    let name: String?
    
    // No CodingKeys needed - using .convertFromSnakeCase in APIClient
}

struct LessonPlanMetadataDTO: Decodable {
    let name: String?
    let searchCriteria: [String: String]?  // snake_case auto-converted
    let totalDuration: Int?  // snake_case auto-converted
    let totalDurationMinutes: Int?  // snake_case auto-converted
    let activities: [ActivityDTO]?  // Some responses include full activities
    let orderingStrategy: String?  // snake_case auto-converted
    let title: String?
    
    // No CodingKeys needed - using .convertFromSnakeCase in APIClient
    
    // Computed property to get the actual total duration
    var actualTotalDuration: Int {
        return totalDuration ?? totalDurationMinutes ?? 0
    }
}

struct FavoriteLessonPlansResponseDTO: Decodable {
    let favourites: [FavoriteLessonPlanRecordDTO]
    let pagination: PaginationDTO
}

struct PaginationDTO: Decodable {
    let count: Int
    let limit: Int
    let offset: Int
}

struct FavoriteLessonPlanSaveResponseDTO: Decodable {
    let message: String
    let favouriteId: Int?  // snake_case auto-converted
    
    // No CodingKeys needed - using .convertFromSnakeCase in APIClient
}

// Helper to store lesson plan data locally (since backend only stores IDs)
struct StoredLessonPlanData: Codable {
    let favouriteId: Int
    let activities: [StoredActivity]
    let totalDuration: Int
    let searchCriteria: [String: String]?
    let name: String?
    let createdAt: Date
}

struct StoredActivity: Codable {
    let id: Int
    let title: String
    let duration: Int
    let category: String
    let grade: Int
    let gradeMin: Int?
    let gradeMax: Int?
    let devices: [String]
    let topics: [String]
    let ageMin: Int?
    let ageMax: Int?
    let source: String?
    let bloomLevel: String?
    let mentalLoad: String?
    let physicalEnergy: String?
    let prepTimeMinutes: Int?
    let cleanupTimeMinutes: Int?
    let durationMax: Int?
    let breakAfter: Int?
    let documentId: String?
}

extension Material {
    func toStoredActivity() -> StoredActivity {
        StoredActivity(
            id: id,
            title: title,
            duration: duration,
            category: category,
            grade: grade,
            gradeMin: gradeMin,
            gradeMax: gradeMax,
            devices: devices,
            topics: topics,
            ageMin: ageMin,
            ageMax: ageMax,
            source: source,
            bloomLevel: bloomLevel,
            mentalLoad: mentalLoad?.rawValue,
            physicalEnergy: physicalEnergy?.rawValue,
            prepTimeMinutes: prepTimeMinutes,
            cleanupTimeMinutes: cleanupTimeMinutes,
            durationMax: durationMax,
            breakAfter: breakAfter,
            documentId: documentId
        )
    }
}

extension StoredActivity {
    func toMaterial() -> Material {
        Material(
            id: id,
            category: category,
            title: title,
            grade: grade,
            gradeMin: gradeMin,
            gradeMax: gradeMax,
            duration: duration,
            devices: devices,
            isFavorite: false,
            topics: topics,
            ageMin: ageMin,
            ageMax: ageMax,
            durationMax: durationMax,
            prepTimeMinutes: prepTimeMinutes,
            cleanupTimeMinutes: cleanupTimeMinutes,
            breakAfter: breakAfter,
            mentalLoad: mentalLoad.flatMap { EffortLevel(rawValue: $0) },
            physicalEnergy: physicalEnergy.flatMap { EffortLevel(rawValue: $0) },
            bloomLevel: bloomLevel,
            source: source,
            documentId: documentId
        )
    }
}

//
//  ActivitiesDTO.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import Foundation

struct ActivitiesResponseDTO: Decodable {
    let activities: [ActivityDTO]
    let limit: Int?
    let offset: Int?
    let total: Int?
}

struct ActivityDTO: Decodable {
    let id: Int
    let name: String
    let type: String
    let format: String?

    // Unstable numerics → LossyInt
    let ageMin: LossyInt?
    let ageMax: LossyInt?
    let durationMinMinutes: LossyInt?
    let durationMaxMinutes: LossyInt?
    let prepTimeMinutes: LossyInt?
    let cleanupTimeMinutes: LossyInt?
    let breakAfter: LossyInt?
    let mentalLoad: LossyString?
    let physicalEnergy: LossyString?

    // Strings/arrays
    let bloomLevel: String?
    let resourcesNeeded: [String]
    let topics: [String]
    let source: String?
    let documentId: LossyString?
}

// MARK: - Favorite Activities DTOs

struct FavoriteRecordDTO: Decodable {
    let id: Int
    let activityId: Int  // snake_case auto-converted
    let name: String?
    let favouriteType: String  // snake_case auto-converted
    let createdAt: String  // snake_case auto-converted
    
    // No CodingKeys needed - using .convertFromSnakeCase in APIClient
}

struct FavoriteActivitiesResponseDTO: Decodable {
    let favourites: [FavoriteRecordDTO]  // Favorite records, not full activities
    let pagination: PaginationInfoDTO?
}

struct PaginationInfoDTO: Decodable {
    let count: Int
    let limit: Int
    let offset: Int
}

struct FavoriteActivitySaveResponseDTO: Decodable {
    let message: String
}

struct FavoriteStatusResponseDTO: Decodable {
    let isFavorite: Bool  // snake_case auto-converted (is_favorite)
    
    // No CodingKeys needed - using .convertFromSnakeCase in APIClient
}

struct FavoriteActivityDeleteResponseDTO: Decodable {
    let message: String
}

struct DeleteResponseDTO: Decodable {
    let message: String
}

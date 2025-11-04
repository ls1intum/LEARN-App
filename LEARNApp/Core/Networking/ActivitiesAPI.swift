//
//  ActivitiesAPI.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import Foundation

protocol ActivitiesAPI {
    func listActivities() async throws -> [Material]
    func getRecommendations(
        name: String?           /* search term */,
        targetAge: Int?,
        format: [String]?,
        bloomLevels: [String]?,
        targetDuration: Int?,
        availableResources: [String]?,
        preferredTopics: [String]?,
        priorityCategories: [String]?,
        includeBreaks: Bool,
        limit: Int,
        maxActivityCount: Int
    ) async throws -> [Recommendation]
    func getFavoriteLessonPlans() async throws -> [FavoriteLessonPlan]
    func saveFavoriteLessonPlan(_ lessonPlan: FavoriteLessonPlanRequest, fullActivities: [Material]) async throws -> Int?
    func deleteFavoriteLessonPlan(favouriteId: Int) async throws -> String
    func getSearchHistory() async throws -> [SearchHistory]
    func deleteSearchHistory(historyId: Int) async throws -> String
    
    // Favorite Activities
    func getFavoriteActivities() async throws -> [Material]
    func saveFavoriteActivity(activityId: Int, name: String?) async throws -> String
    func checkActivityFavoriteStatus(activityId: Int) async throws -> Bool
    func removeFavoriteActivity(activityId: Int) async throws -> String
    
    // PDF Export
    func generateLessonPlanPDF(_ request: LessonPlanPDFRequest) async throws -> Data
}

final class LiveActivitiesAPI: ActivitiesAPI {
    private let api: APIClient
    init(api: APIClient) { self.api = api }

    func listActivities() async throws -> [Material] {
        let res: ActivitiesResponseDTO = try await api.send(.GET, "/api/activities/", query: [
            URLQueryItem(name: "limit", value: "100")
        ])
        return res.activities.map { $0.toMaterial() }
    }

    func getRecommendations(
        name: String? = nil,
        targetAge: Int? = nil,
        format: [String]? = nil,
        bloomLevels: [String]? = nil,
        targetDuration: Int? = nil,
        availableResources: [String]? = nil,
        preferredTopics: [String]? = nil,
        priorityCategories: [String]? = nil,
        includeBreaks: Bool = false,
        limit: Int = 10,
        maxActivityCount: Int = 2
    ) async throws -> [Recommendation] {

        var q: [URLQueryItem] = []
        func add(_ key: String, _ value: String?)       { if let v = value, !v.isEmpty { q.append(.init(name: key, value: v)) } }
        func add(_ key: String, _ value: Int?)          { if let v = value { q.append(.init(name: key, value: String(v))) } }
        func add(_ key: String, _ value: Bool)          { q.append(.init(name: key, value: value ? "true" : "false")) }
        func add(_ key: String, _ values: [String]?) {
            guard let values, !values.isEmpty else { return }
            let csv = values.joined(separator: ",")
            q.append(.init(name: key, value: csv))

            for v in values where !v.isEmpty {
                q.append(.init(name: key, value: v))
            }

            for v in values where !v.isEmpty {
                q.append(.init(name: "\(key)[]", value: v))
            }
        }

        add("name", name)
        add("target_age", targetAge)
        add("format", format)
        add("bloom_levels", bloomLevels)
        add("target_duration", targetDuration)
        add("available_resources", availableResources)
        add("preferred_topics", preferredTopics)
        add("priority_categories", priorityCategories)
        add("include_breaks", includeBreaks)
        add("limit", limit)
        add("max_activity_count", maxActivityCount)

        let res: RecommendationsResponseDTO = try await api.send(.GET, "/api/activities/recommendations", query: q)
        
        // Debug: Print full backend response
        print("=== FULL BACKEND RESPONSE ===")
        print("Activities count: \(res.activities.count)")
        print("Generated at: \(res.generatedAt?.description ?? "nil")")
        print("Response total field: \(res.total ?? 0)")
        print("Requested target duration: \(targetDuration ?? 0) minutes")
        print("Requested limit: \(limit)")
        print("Requested max activity count: \(maxActivityCount)")
        for (index, activity) in res.activities.enumerated() {
            print("Recommendation \(index + 1):")
            print("  Raw Score: \(activity.score?.value ?? 0)")
            print("  Activities count: \(activity.activities.count)")
            print("  Activities: \(activity.activities.map { $0.name ?? "unnamed" })")
            
            // Calculate total duration for this recommendation
            let totalDuration = activity.activities.reduce(0) { sum, act in
                sum + (act.durationMinMinutes?.value ?? 0)
            }
            let totalDurationMax = activity.activities.reduce(0) { sum, act in
                sum + (act.durationMaxMinutes?.value ?? act.durationMinMinutes?.value ?? 0)
            }
            print("  Total duration: \(totalDuration) minutes (min), \(totalDurationMax) minutes (max)")
            
            // Calculate potential percentage (score as percentage of max possible)
            if let score = activity.score?.value, let total = res.total, total > 0 {
                let percentage = (score / Double(total)) * 100
                print("  Calculated percentage: \(String(format: "%.1f", percentage))%")
            }
            
            // Check if total field matches requested duration
            if let responseTotal = res.total, let requestedDuration = targetDuration {
                print("  Total field vs requested duration: \(responseTotal) vs \(requestedDuration)")
                if responseTotal == requestedDuration {
                    print("  ✓ Total field matches requested duration")
                } else {
                    print("  ✗ Total field differs from requested duration")
                }
            }
            
            // Show score breakdown details
            if let breakdown = activity.scoreBreakdown {
                print("  Score breakdown:")
                for (key, detail) in breakdown {
                    print("    \(key): score=\(detail.score?.value ?? 0), impact=\(detail.impact?.value ?? 0), isPriority=\(detail.isPriority ?? false), multiplier=\(detail.priorityMultiplier?.value ?? 0)")
                }
            }
        }
        print("=== END BACKEND RESPONSE ===")
        
        return res.activities.map { $0.toDomain() }
    }
    
    func getFavoriteLessonPlans() async throws -> [FavoriteLessonPlan] {
        // Get favorite records from backend
        let res: FavoriteLessonPlansResponseDTO = try await api.send(.GET, "/api/history/favourites/lesson-plans")
        
        // Fetch all activities to match with IDs
        let allActivitiesRes: ActivitiesResponseDTO = try await api.send(.GET, "/api/activities/", query: [
            URLQueryItem(name: "limit", value: "100")
        ])
        
        // Create a lookup dictionary for activities by ID
        let activitiesById = Dictionary(uniqueKeysWithValues: allActivitiesRes.activities.map { ($0.id, $0) })
        
        // Map records to domain models
        // Custom date formatter for backend format: "2025-10-21T22:57:56.164440"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return res.favourites.compactMap { record in
            // Get the activities for this lesson plan
            let activities = record.activityIds.compactMap { activityId -> Material? in
                guard let activityDTO = activitiesById[activityId] else { return nil }
                return activityDTO.toMaterial()
            }
            
            // Skip if we couldn't find all activities
            guard activities.count == record.activityIds.count else {
                return nil
            }
            
            // Parse the date
            let parsedDate = dateFormatter.date(from: record.createdAt)
            
            return FavoriteLessonPlan(
                id: record.id,
                name: record.lessonPlan.name ?? record.lessonPlan.title ?? record.name,  // Try multiple name sources
                activities: activities,
                totalDuration: record.lessonPlan.actualTotalDuration,  // DTO has this computed property
                searchCriteria: record.lessonPlan.searchCriteria,
                createdAt: parsedDate
            )
        }
    }
    
    func saveFavoriteLessonPlan(_ lessonPlan: FavoriteLessonPlanRequest, fullActivities: [Material]) async throws -> Int? {
        let res: FavoriteLessonPlanSaveResponseDTO = try await api.send(.POST, "/api/history/favourites/lesson-plans", body: lessonPlan)
        return res.favouriteId
    }
    
    func deleteFavoriteLessonPlan(favouriteId: Int) async throws -> String {
        let res: DeleteResponseDTO = try await api.send(.DELETE, "/api/history/favourites/\(favouriteId)")
        return res.message
    }
    
    func getSearchHistory() async throws -> [SearchHistory] {
        let res: SearchHistoryResponseDTO = try await api.send(.GET, "/api/history/search")
        return res.toDomain()
    }
    
    func deleteSearchHistory(historyId: Int) async throws -> String {
        let res: SearchHistoryDeleteResponseDTO = try await api.send(.DELETE, "/api/history/search/\(historyId)")
        return res.message
    }
    
    // MARK: - Favorite Activities
    
    func getFavoriteActivities() async throws -> [Material] {
        // Get favorite records (which contain activity IDs)
        let favRes: FavoriteActivitiesResponseDTO = try await api.send(.GET, "/api/history/favourites/activities")
        let favoriteActivityIds = Set(favRes.favourites.map { $0.activityId })
        
        // If no favorites, return empty array
        guard !favoriteActivityIds.isEmpty else {
            return []
        }
        
        // Fetch all activities and filter by favorite IDs
        let allActivitiesRes: ActivitiesResponseDTO = try await api.send(.GET, "/api/activities/", query: [
            URLQueryItem(name: "limit", value: "100")
        ])
        
        return allActivitiesRes.activities
            .filter { favoriteActivityIds.contains($0.id) }
            .map { $0.toMaterial() }
    }
    
    func saveFavoriteActivity(activityId: Int, name: String?) async throws -> String {
        struct Body: Encodable {
            let activityId: Int  // Will be converted to activity_id by snake_case encoder
            let name: String?
            
            enum CodingKeys: String, CodingKey {
                case activityId = "activity_id"
                case name
            }
        }
        let res: FavoriteActivitySaveResponseDTO = try await api.send(
            .POST,
            "/api/history/favourites/activities",
            body: Body(activityId: activityId, name: name)
        )
        return res.message
    }
    
    func checkActivityFavoriteStatus(activityId: Int) async throws -> Bool {
        let res: FavoriteStatusResponseDTO = try await api.send(.GET, "/api/history/favourites/activities/\(activityId)/status")
        return res.isFavorite
    }
    
    func removeFavoriteActivity(activityId: Int) async throws -> String {
        let res: FavoriteActivityDeleteResponseDTO = try await api.send(.DELETE, "/api/history/favourites/activities/\(activityId)")
        return res.message
    }
    
    // MARK: - PDF Export
    
    func generateLessonPlanPDF(_ request: LessonPlanPDFRequest) async throws -> Data {
        return try await api.sendBinary(.POST, "/api/activities/lesson-plan", body: request)
    }
}

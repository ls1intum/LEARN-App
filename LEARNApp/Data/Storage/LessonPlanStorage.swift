//
//  LessonPlanStorage.swift
//  Master
//
//  Created by AI Assistant on 21.10.25.
//

import Foundation

// Manages local storage of favorite lesson plan data
// Since the backend only stores activity IDs, we need to persist the full lesson plan details locally
final class LessonPlanStorage {
    static let shared = LessonPlanStorage()
    
    private let defaults = UserDefaults.standard
    private let key = "stored_lesson_plans"
    
    private init() {}
    
    // MARK: - Public Methods
    
    func save(favouriteId: Int, activities: [Material], totalDuration: Int, searchCriteria: [String: String]?, name: String?) {
        var stored = loadAll()
        
        let data = StoredLessonPlanData(
            favouriteId: favouriteId,
            activities: activities.map { $0.toStoredActivity() },
            totalDuration: totalDuration,
            searchCriteria: searchCriteria,
            name: name,
            createdAt: Date()
        )
        
        // Remove existing if present (update)
        stored.removeAll { $0.favouriteId == favouriteId }
        stored.append(data)
        
        saveAll(stored)
    }
    
    func get(favouriteId: Int) -> StoredLessonPlanData? {
        return loadAll().first { $0.favouriteId == favouriteId }
    }
    
    func getAll() -> [StoredLessonPlanData] {
        return loadAll()
    }
    
    func delete(favouriteId: Int) {
        var stored = loadAll()
        stored.removeAll { $0.favouriteId == favouriteId }
        saveAll(stored)
    }
    
    func deleteAll() {
        defaults.removeObject(forKey: key)
    }
    
    // MARK: - Private Methods
    
    private func loadAll() -> [StoredLessonPlanData] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([StoredLessonPlanData].self, from: data)) ?? []
    }
    
    private func saveAll(_ plans: [StoredLessonPlanData]) {
        guard let data = try? JSONEncoder().encode(plans) else { return }
        defaults.set(data, forKey: key)
    }
}






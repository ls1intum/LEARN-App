//
//  MainTabView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 26.05.25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case 0:
                    PlanningView()
                case 1:
                    SearchView()
                case 2:
                    NavigationStack {
                        FavoritesView(showBackButton: false)
                    }
                case 3:
                    ProfileView()
                default:
                    PlanningView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 30)
                
                HStack(spacing: 8) {
                    TabBarButton(
                        icon: "square.grid.2x2",
                        title: "Planung",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabBarButton(
                        icon: "magnifyingglass.circle",
                        title: "Suchen",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabBarButton(
                        icon: "heart",
                        title: "Favoriten",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    
                    TabBarButton(
                        icon: "person",
                        title: "Profil",
                        isSelected: selectedTab == 3,
                        action: { selectedTab = 3 }
                    )
                }
                
                Spacer()
                    .frame(width: 30)
            }
            .frame(height: 70)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.separator)),
                alignment: .top
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private var filledIcon: String {
        switch icon {
        case "square.grid.2x2":
            return "square.grid.2x2.fill"
        case "magnifyingglass.circle":
            return "magnifyingglass.circle.fill"
        case "heart":
            return "heart.fill"
        case "person":
            return "person.fill"
        default:
            return icon + ".fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? filledIcon : icon)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundColor(isSelected ? Color.blue.opacity(0.8) : .gray)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

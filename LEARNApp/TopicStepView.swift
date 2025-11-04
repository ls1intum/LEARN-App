//
//  TopicStepView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

struct TopicStepView: View {
    @Binding var selected: Set<Topic>
    var onNext: () -> Void
    @State private var showingTopicInfo = false

    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Welche Themen möchtest du abdecken?")
                    .stepTitle()
                
                Spacer()
                
                Button(action: {
                    showingTopicInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
            }
            
            HStack {
                Spacer()
                Button(action: {
                    selected = Set(Topic.allCases)
                }) {
                    Text("Alle auswählen")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
            }
            .padding(.top, -16)

            LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                ForEach(Topic.allCases) { topic in
                    Chip(
                        label: topic.label,
                        isSelected: selected.contains(topic)
                    ) {
                        if selected.contains(topic) {
                            // nur abwählen, wenn danach nicht leer
                            if selected.count > 1 { selected.remove(topic) }
                        } else {
                            selected.insert(topic)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)   
            .onAppear {
                if selected.isEmpty { selected = Set(Topic.allCases) } // preselect all
            }

            Spacer()

            Button("Weiter") { onNext() }
                .buttonStyle(CurvedFilledButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .disabled(selected.isEmpty)
        }
        .sheet(isPresented: $showingTopicInfo) {
            TopicInfoModal()
        }
    }
}

struct TopicInfoModal: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Topic.allCases) { topic in
                        TopicInfoCard(topic: topic)
                    }
                }
                .padding()
            }
            .navigationTitle("Themen erklärt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TopicInfoCard: View {
    let topic: Topic
    
    private var topicInfo: (emoji: String, title: String, description: String) {
        switch topic {
        case .decomposition:
            return ("🧩", "Problemzerlegung", "Große Aufgaben werden in kleinere, besser handhabbare Teilprobleme zerlegt. So lassen sich komplexe Inhalte Schritt für Schritt verstehen und lösen.")
        case .patterns:
            return ("🔁", "Muster", "Wiederkehrende Strukturen oder Abläufe werden erkannt und genutzt, um Probleme effizienter zu lösen oder neue Aufgaben besser zu verstehen.")
        case .abstraction:
            return ("🧠", "Abstraktion", "Wichtige Informationen werden herausgefiltert, unwichtige Details weggelassen. So wird ein Problem vereinfacht dargestellt.")
        case .algorithms:
            return ("⚙️", "Algorithmen", "Eine genaue Schritt-für-Schritt-Anleitung, mit der ein Problem automatisch oder systematisch gelöst werden kann.")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(topicInfo.emoji)
                    .font(.system(size: 32))
                
                Text(topicInfo.title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text(topicInfo.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

//
//  ContentView.swift
//  newzyxIOS
//
//  Created by Ryan Gupta on 12/8/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var newsService = NewsService()
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var scrollToID: String?
    @State private var showingDebug = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.09, blue: 0.16),
                        Color(red: 0.04, green: 0.06, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            // Centered title
                            Text("NEWZYX")
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .tracking(2)
                            
                            // Debug button (top-right corner)
                            HStack {
                                Spacer()
                                Button(action: {
                                    showingDebug = true
                                }) {
                                    Image(systemName: "ladybug.fill")
                                        .font(.title3)
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        
                        Text("Your stream of daily news")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Controls
                    HStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await openLatestAvailableEpisode()
                            }
                        }) {
                            Text("Latest")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingDatePicker.toggle()
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("Pick Date")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Episode List
                    if newsService.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else if let error = newsService.errorMessage {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        Spacer()
                    } else {
                        ScrollViewReader { proxy in
                            List {
                                ForEach(newsService.episodes) { episode in
                                    NavigationLink(destination: NewsDetailView(episode: episode)) {
                                        EpisodeRow(episode: episode)
                                    }
                                    .listRowBackground(Color.white.opacity(0.05))
                                    .listRowSeparator(.hidden)
                                    .id(episode.id)
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .onChange(of: scrollToID) { oldValue, newValue in
                                if let newValue = newValue {
                                    print("📜 Scroll triggered to: \(newValue)")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            proxy.scrollTo(newValue, anchor: .top)
                                        }
                                    }
                                }
                            }
                            .onChange(of: showingDatePicker) { _, isShowing in
                                if !isShowing {
                                    let calendar = Calendar.current
                                    let month = calendar.component(.month, from: selectedDate)
                                    let day = calendar.component(.day, from: selectedDate)
                                    let year = calendar.component(.year, from: selectedDate) % 100
                                    scrollToID = String(format: "%d.%d.%02d", month, day, year)
                                }
                            }
                            .onAppear {
                                // Scroll to the first (most recent) episode on launch
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    if let firstEpisode = newsService.episodes.first {
                                        scrollToID = firstEpisode.id
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate, isPresented: $showingDatePicker)
            }
            .navigationDestination(for: NewsEpisode.self) { episode in
                NewsDetailView(episode: episode)
            }
            .sheet(isPresented: $showingDebug) {
                DebugView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func openLatestAvailableEpisode() async {
        print("🔘 Latest button tapped - searching for available content...")
        
        // Check up to the first 10 episodes (last 10 days)
        for episode in newsService.episodes.prefix(10) {
            print("🔍 Checking if content exists for: \(episode.displayDate)")
            
            let exists = await newsService.checkEpisodeExists(for: episode)
            
            if exists {
                print("✅ Found available content for: \(episode.displayDate)")
                await MainActor.run {
                    navigationPath.append(episode)
                }
                return
            } else {
                print("⏭️  Content not available for \(episode.displayDate), trying next...")
            }
        }
        
        // If none of the first 10 have content, just open the first one
        print("⚠️  No verified content found in last 10 days, opening most recent date anyway")
        if let firstEpisode = newsService.episodes.first {
            await MainActor.run {
                navigationPath.append(firstEpisode)
            }
        }
    }
}

struct EpisodeRow: View {
    let episode: NewsEpisode
    
    var body: some View {
        HStack(spacing: 16) {
            // Date icon
            VStack(spacing: 4) {
                Text(monthName(from: episode.displayDate))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(dayNumber(from: episode.displayDate))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDisplayDate(episode.displayDate))
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Daily news summary & podcast")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDisplayDate(_ dateString: String) -> String {
        let components = dateString.split(separator: ".")
        guard components.count == 3,
              let month = Int(components[0]),
              let day = Int(components[1]),
              let year = Int("20" + components[2]) else {
            return dateString
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        
        if let date = Calendar.current.date(from: dateComponents) {
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func monthName(from dateString: String) -> String {
        let components = dateString.split(separator: ".")
        guard components.count >= 1,
              let month = Int(components[0]) else {
            return ""
        }
        
        let dateFormatter = DateFormatter()
        return dateFormatter.shortMonthSymbols[month - 1].uppercased()
    }
    
    private func dayNumber(from dateString: String) -> String {
        let components = dateString.split(separator: ".")
        guard components.count >= 2 else {
            return ""
        }
        return String(components[1])
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Pick a Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ContentView()
}

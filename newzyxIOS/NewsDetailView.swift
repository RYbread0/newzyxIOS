//
//  NewsDetailView.swift
//  newzyxIOS
//
//  Detail view for a single news episode
//

import SwiftUI

struct NewsDetailView: View {
    let episode: NewsEpisode
    @StateObject private var newsService = NewsService()
    @StateObject private var audioPlayer = AudioPlayerManager()
    
    @State private var newsContent: String = "Loading..."
    @State private var isLoading = true
    @State private var lastUpdated: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(formatDisplayDate(episode.displayDate))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    if !lastUpdated.isEmpty {
                        Text(lastUpdated)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Audio Player Card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "headphones")
                            .font(.title2)
                        Text("3-Minute Recap")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    if audioPlayer.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            // Play/Pause button
                            Button(action: {
                                audioPlayer.togglePlayPause()
                            }) {
                                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            // Progress slider
                            VStack(spacing: 4) {
                                Slider(
                                    value: Binding(
                                        get: { audioPlayer.currentTime },
                                        set: { audioPlayer.seek(to: $0) }
                                    ),
                                    in: 0...max(audioPlayer.duration, 1)
                                )
                                .tint(.blue)
                                
                                HStack {
                                    Text(formatTime(audioPlayer.currentTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatTime(audioPlayer.duration))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Text("Press play to listen to the quick summary")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // News Summary Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "newspaper")
                            .font(.title2)
                        Text("Today's News")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    Divider()
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    } else {
                        HTMLTextView(htmlString: newsContent)
                            .font(.body)
                            .lineSpacing(6)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContent()
            audioPlayer.loadEpisode(episode)
        }
    }
    
    private func loadContent() async {
        do {
            let content = try await newsService.fetchNewsSummary(for: episode)
            await MainActor.run {
                newsContent = content.text
                isLoading = false
                
                if let date = content.lastModified {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    lastUpdated = "Updated: \(formatter.string(from: date))"
                }
            }
        } catch {
            await MainActor.run {
                newsContent = """
                Could not load news summary for this date.
                
                Error: \(error.localizedDescription)
                
                This episode may not be available yet.
                """
                isLoading = false
            }
        }
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
        dateFormatter.dateFormat = "MMMM d, yyyy"
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        
        if let date = Calendar.current.date(from: dateComponents) {
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    NavigationStack {
        NewsDetailView(episode: NewsEpisode(dateString: "12.9.25", baseURL: "https://kidsnewsfeed.s3.us-east-2.amazonaws.com"))
    }
}


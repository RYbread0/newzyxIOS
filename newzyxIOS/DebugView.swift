//
//  DebugView.swift
//  newzyxIOS
//
//  Debug view to test S3 connectivity and URL generation
//

import SwiftUI

struct DebugView: View {
    @State private var testResult = "Tap 'Test Connection' to verify S3 access"
    @State private var isTesting = false
    
    let baseURL = "https://kidsnewsfeed.s3.us-east-2.amazonaws.com"
    
    var body: some View {
        NavigationStack {
            List {
                Section("S3 Configuration") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Base URL:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(baseURL)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Section("Test URLs") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Summary:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(todayURL())
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Today's Podcast:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(todayPodcastURL())
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Section("Connection Test") {
                    if isTesting {
                        HStack {
                            ProgressView()
                            Text("Testing...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button("Test Connection") {
                            testConnection()
                        }
                    }
                    
                    Text(testResult)
                        .font(.caption)
                        .foregroundColor(testResult.contains("✅") ? .green : testResult.contains("❌") ? .red : .primary)
                }
                
                Section("Recent Dates") {
                    ForEach(0..<5) { daysAgo in
                        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
                        let dateString = formatDate(date)
                        VStack(alignment: .leading) {
                            Text("\(daysAgo == 0 ? "Today" : "\(daysAgo) days ago")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(dateString)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Debug Info")
        }
    }
    
    private func todayURL() -> String {
        let today = Date()
        let dateString = formatDate(today)
        return "\(baseURL)/\(dateString)_news_summary.txt"
    }
    
    private func todayPodcastURL() -> String {
        let today = Date()
        let dateString = formatDate(today)
        return "\(baseURL)/\(dateString)_podcast.mp3"
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date) % 100
        return String(format: "%d.%d.%02d", month, day, year)
    }
    
    private func testConnection() {
        isTesting = true
        testResult = "Testing..."
        
        Task {
            do {
                let urlString = todayURL()
                guard let url = URL(string: urlString) else {
                    await MainActor.run {
                        testResult = "❌ Invalid URL format"
                        isTesting = false
                    }
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    await MainActor.run {
                        if httpResponse.statusCode == 200 {
                            testResult = "✅ Connection successful! Status: \(httpResponse.statusCode)"
                        } else if httpResponse.statusCode == 403 {
                            testResult = "❌ Access denied (403). S3 bucket may not be public."
                        } else if httpResponse.statusCode == 404 {
                            testResult = "❌ File not found (404). Today's content may not exist yet."
                        } else {
                            testResult = "❌ HTTP \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                        }
                        isTesting = false
                    }
                } else {
                    await MainActor.run {
                        testResult = "❌ Invalid response from server"
                        isTesting = false
                    }
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ Error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}

#Preview {
    DebugView()
}


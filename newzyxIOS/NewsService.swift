//
//  NewsService.swift
//  newzyxIOS
//
//  Service for fetching news content from backend
//

import Foundation
import Combine

class NewsService: ObservableObject {
    // Use the alt S3 bucket URL (kidsnewsfeed)
    private let baseURL = "https://kidsnewsfeed.s3.us-east-2.amazonaws.com"
    
    @Published var episodes: [NewsEpisode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        generateEpisodeList()
    }
    
    // Generate list of episodes for the last 60 days
    private func generateEpisodeList() {
        var episodeList: [NewsEpisode] = []
        let calendar = Calendar.current
        
        for daysAgo in 0..<60 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
                let month = calendar.component(.month, from: date)
                let day = calendar.component(.day, from: date)
                let year = calendar.component(.year, from: date) % 100
                
                let dateString = String(format: "%d.%d.%02d", month, day, year)
                let episode = NewsEpisode(dateString: dateString, baseURL: baseURL)
                episodeList.append(episode)
            }
        }
        
        self.episodes = episodeList
    }
    
    // Fetch news summary text
    func fetchNewsSummary(for episode: NewsEpisode) async throws -> NewsContent {
        print("📡 Fetching news from: \(episode.summaryURL.absoluteString)")
        
        var request = URLRequest(url: episode.summaryURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw NewsServiceError.invalidResponse
        }
        
        print("📊 HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw NewsServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        guard let text = String(data: data, encoding: .utf8) else {
            print("❌ Failed to decode text")
            throw NewsServiceError.decodingError
        }
        
        print("✅ Successfully loaded news (\(text.count) characters)")
        
        // Try to get last modified date from headers
        var lastModified: Date?
        if let lastModString = httpResponse.value(forHTTPHeaderField: "Last-Modified") {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            lastModified = formatter.date(from: lastModString)
        }
        
        return NewsContent(text: text, lastModified: lastModified)
    }
    
    // Check if an episode exists by attempting to fetch its summary
    func checkEpisodeExists(for episode: NewsEpisode) async -> Bool {
        var request = URLRequest(url: episode.summaryURL)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
}

enum NewsServiceError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server error: \(statusCode)"
        case .decodingError:
            return "Could not decode response"
        case .notFound:
            return "Content not found for this date"
        }
    }
}


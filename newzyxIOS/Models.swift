//
//  Models.swift
//  newzyxIOS
//
//  Data models for news content
//

import Foundation

struct NewsEpisode: Identifiable, Codable, Hashable {
    let id: String
    let date: Date
    let displayDate: String
    let summaryURL: URL
    let podcastURL: URL
    
    init(dateString: String, baseURL: String) {
        self.id = dateString
        self.displayDate = dateString
        
        // Parse the date string (format: M.D.YY)
        let components = dateString.split(separator: ".")
        if components.count == 3,
           let month = Int(components[0]),
           let day = Int(components[1]),
           let year = Int("20" + components[2]) {
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = day
            self.date = Calendar.current.date(from: dateComponents) ?? Date()
        } else {
            self.date = Date()
        }
        
        self.summaryURL = URL(string: "\(baseURL)/\(dateString)_news_summary.txt")!
        self.podcastURL = URL(string: "\(baseURL)/\(dateString)_podcast.mp3")!
    }
}

struct NewsContent {
    let text: String
    let lastModified: Date?
}


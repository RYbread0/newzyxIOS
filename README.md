# Newzyx iOS App

An iOS app that displays daily news content from your Newzyx backend server.

## Features

- 📰 **Daily News Feed**: Browse news summaries from the last 60 days
- 🎧 **Audio Podcasts**: Listen to 3-minute audio recaps for each day
- 📅 **Date Picker**: Jump to any specific date to see that day's news
- 🌙 **Beautiful Dark UI**: Modern gradient design with smooth animations
- ⚡ **Live Updates**: Fetches content directly from your AWS S3 backend

## Architecture

### Files Overview

- **ContentView.swift**: Main view showing the list of news episodes
- **NewsDetailView.swift**: Detail view for a single news episode with audio player
- **Models.swift**: Data models for news episodes and content
- **NewsService.swift**: Service class for fetching news from AWS S3
- **AudioPlayerManager.swift**: AVFoundation-based audio player for podcasts
- **newzyxIOSApp.swift**: Main app entry point

### Backend Integration

The app connects to your existing backend infrastructure:
- **Base URL**: `https://kidsnewsfeed.s3.us-east-2.amazonaws.com`
- **Content Format**: 
  - News summaries: `M.D.YY_news_summary.txt`
  - Podcasts: `M.D.YY_podcast.mp3`

The app automatically generates dates for the last 60 days and fetches content from your S3 bucket.

## How It Works

1. **Episode List Generation**: The app generates a list of dates for the last 60 days
2. **Content Fetching**: When you tap on a date, it fetches:
   - News summary text from S3
   - Audio podcast file from S3
3. **Display & Playback**: Shows the news text and provides audio controls
4. **Date Navigation**: Use "Latest" button or date picker to navigate

## Building & Running

1. Open `newzyxIOS.xcodeproj` in Xcode
2. Select a simulator or device
3. Press Cmd+R to build and run

### Requirements

- **Xcode:** 15.0 or later
- **iOS Deployment Target:** 17.0
- **Minimum iOS Version:** 17.0 (iPhone/iPad running iOS 17.0+)
- **Internet:** Required to fetch content from S3

## UI Features

### Main Screen
- **NEWZYX** header with gradient logo
- **Latest** button - scrolls to today's episode
- **Pick Date** button - opens date picker for specific dates
- **Episode list** - Shows all available episodes with date cards

### Detail Screen
- **Date header** with formatted date display
- **3-Minute Recap card** with audio player controls:
  - Play/pause button
  - Progress slider
  - Time display
- **Today's News card** with full text summary

## Customization

### Changing Backend URL

Edit `NewsService.swift` and update the `baseURL`:

```swift
private let baseURL = "https://your-bucket.s3.your-region.amazonaws.com"
```

### Adjusting Date Range

Edit the date range in `NewsService.swift`:

```swift
// Change 60 to your desired number of days
for daysAgo in 0..<60 {
```

### UI Theming

All colors and gradients are defined in SwiftUI views and can be easily customized:
- Main gradients: Blue → Purple → Cyan
- Background: Dark navy gradient
- Cards: Semi-transparent white

## Notes

- The app uses cache-busting URL parameters to ensure fresh content
- No authentication required (S3 bucket must be publicly readable)
- Content is fetched on-demand when viewing each episode
- Audio playback uses `AVPlayer` for robust streaming support


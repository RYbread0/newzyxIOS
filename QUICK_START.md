# Quick Start Guide

## Running the App

### Requirements
- **iOS 17.0+** (iPhone or iPad running iOS 17.0 or later)
- **Xcode 15.0+**

### Steps

1. **Open the project**:
   ```bash
   open newzyxIOS.xcodeproj
   ```

2. **Select a target**:
   - In Xcode, select a simulator (iPhone 15, 16, etc.) or your physical device from the dropdown at the top

3. **Build and Run**:
   - Press `Cmd + R` or click the Play button
   - The app will build and launch

## Testing the App

### Main Features to Test

1. **Browse Episodes**:
   - The app opens to a list of the last 60 days of news
   - Tap any date to see that day's news

2. **Latest Button** (Smart):
   - Tap "Latest" to open the most recent available episode
   - Automatically checks if today's content exists
   - If not available, tries yesterday, then the day before, etc.
   - Opens the first date that has actual content
   - Watch Xcode console for availability checks (🔍 emojis)

3. **Date Picker**:
   - Tap "Pick Date" to select a specific date
   - Choose a date from the calendar
   - Tap "Done" to jump to that date

4. **Reading News**:
   - Tap on any episode to open the detail view
   - Scroll through the news summary

5. **Playing Audio**:
   - Tap the play button to start the podcast
   - Use the slider to skip forward/backward
   - Pause and resume playback

## Troubleshooting

### No Content Loading

If you see "Could not load summaries for this date":
- Check your internet connection
- Verify the S3 bucket is publicly accessible
- Confirm the backend uploaded content for that date

### Audio Not Playing

If the audio doesn't play:
- Ensure the MP3 file exists on S3 for that date
- Check that the file is publicly accessible
- Try a different date that you know has content

### Build Errors

If the project doesn't build:
- Make sure you're using Xcode 15+
- Clean the build folder: `Cmd + Shift + K`
- Rebuild: `Cmd + B`

## Configuration

### Backend URL

The app is configured to fetch from:
```
https://kidsnewsfeed.s3.us-east-2.amazonaws.com
```

This matches your backend's `alt_S3_BUCKET` configuration.

### Date Format

Files must follow this naming convention:
- Summary: `M.D.YY_news_summary.txt` (e.g., `12.7.25_news_summary.txt`)
- Podcast: `M.D.YY_podcast.mp3` (e.g., `12.7.25_podcast.mp3`)

Note: No leading zeros for month and day!

## Next Steps

### Recommended Improvements

1. **HTML Rendering**: The news summaries contain HTML tags (`<B>`, `<a href>`). You could add an HTML renderer to display formatted text with clickable links.

2. **Caching**: Add local caching so users can read previously loaded news offline.

3. **Notifications**: Push notifications when new daily content is available.

4. **Favorites**: Let users bookmark their favorite episodes.

5. **Share**: Add share functionality to share interesting news with friends.

6. **Dark/Light Mode**: Add a toggle for light mode (currently dark mode only).

7. **Search**: Add search functionality to find specific news topics.

8. **App Icon**: Design and add a custom app icon in Assets.xcassets.

## Publishing to App Store

When ready to publish:

1. Create an app icon (1024x1024 PNG)
2. Add screenshots for App Store listing
3. Create an Apple Developer account ($99/year)
4. Set up App Store Connect listing
5. Configure code signing in Xcode
6. Archive and upload to App Store Connect
7. Submit for review

## Support

If you encounter issues:
- Check the Xcode console for error messages
- Verify backend is uploading files correctly
- Test S3 URLs directly in a browser
- Ensure dates match between app and backend


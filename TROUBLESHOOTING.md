# Troubleshooting Guide

## Issues Fixed

### ✅ 1. Fixed Deprecation Warnings
**Problem:** AudioPlayerManager was using deprecated iOS APIs  
**Solution:** Updated to use modern async/await `asset.load(.duration)` API

### ✅ 2. Fixed Latest Button
**Problem:** Latest button wasn't scrolling to today's episode  
**Solution:** Refactored to use `@State` variable with `onChange` modifier for proper ScrollViewProxy access

### ✅ 3. Added Debug Logging
**Problem:** Hard to diagnose why content wasn't loading  
**Solution:** Added console logging throughout the app with emojis for easy identification:
- 📡 Network requests
- 📊 HTTP status codes
- ✅ Successful operations
- ❌ Errors
- 🎵 Audio loading

### ✅ 4. Added Debug View
**Problem:** No way to test S3 connectivity  
**Solution:** Created a debug screen accessible via bug icon in top-right corner

## Using the Debug View

1. **Launch the app**
2. **Tap the bug icon** (🐞) in the top-right corner of the header
3. **View generated URLs** to verify they match your S3 structure
4. **Tap "Test Connection"** to verify S3 accessibility

### What the Debug View Shows

- **S3 Configuration**: Base URL being used
- **Test URLs**: Generated URLs for today's content
- **Connection Test**: Live test of S3 accessibility
- **Recent Dates**: Shows how dates are formatted for the last 5 days

### Interpreting Test Results

**✅ Connection successful!**
- S3 is accessible and today's content exists
- Everything should work perfectly

**❌ Access denied (403)**
- S3 bucket is not publicly accessible
- Fix: Update bucket policy to allow public read access

**❌ File not found (404)**
- Content for today doesn't exist yet
- Your backend may not have run today
- Try a different date (e.g., 12.7.25 which exists in your alt folder)

**❌ Network error**
- Check internet connection
- Verify the S3 URL is correct

## Common Issues & Solutions

### News Not Loading

**Check:**
1. Open the Debug View and test connection
2. Check Xcode console for error messages (look for 📡 and ❌ emojis)
3. Verify the date format matches: `M.D.YY` (no leading zeros for month/day)
4. Ensure S3 bucket allows public read access

**Example URLs that should work:**
```
https://kidsnewsfeed.s3.us-east-2.amazonaws.com/12.7.25_news_summary.txt
https://kidsnewsfeed.s3.us-east-2.amazonaws.com/12.7.25_podcast.mp3
```

### Podcast Not Playing

**Check:**
1. Ensure MP3 file exists on S3 for that date
2. Check Xcode console for 🎵 audio loading messages
3. Verify file is publicly accessible
4. Try a different date that you know has content

**Audio Requirements:**
- Format: MP3
- Must be publicly readable on S3
- Filename format: `M.D.YY_podcast.mp3`

### Latest Button Not Working

**Fixed in latest version!** If still not working:
1. Check Xcode console for scroll-related errors
2. Ensure episodes list is not empty
3. Try manually scrolling to verify the list is working

## Viewing Console Logs

1. **Build and Run** in Xcode (Cmd+R)
2. **Open the Console** (bottom panel in Xcode)
3. **Filter by emoji** to see specific logs:
   - Filter for "📡" to see network requests
   - Filter for "❌" to see errors
   - Filter for "✅" to see successful operations
   - Filter for "🎵" to see audio operations

## Testing S3 Bucket Accessibility

### Option 1: Use the Debug View (Recommended)
Just tap the debug button and run the connection test!

### Option 2: Test in Safari
Open this URL in Safari (replace date with today):
```
https://kidsnewsfeed.s3.us-east-2.amazonaws.com/12.7.25_news_summary.txt
```

**If it works:** You'll see the news text  
**If it fails:** You'll see an error (likely 403 or 404)

### Option 3: Terminal Test
```bash
curl -I "https://kidsnewsfeed.s3.us-east-2.amazonaws.com/12.7.25_news_summary.txt"
```

Look for `HTTP/1.1 200 OK` in the response.

## Making S3 Bucket Public

If you're getting 403 errors, you need to make your S3 bucket publicly readable:

1. **Go to AWS S3 Console**
2. **Select your bucket:** `kidsnewsfeed`
3. **Permissions tab** → **Bucket Policy**
4. **Add this policy:**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::kidsnewsfeed/*"
        }
    ]
}
```

5. **Save changes**

**Security Note:** This makes all files in the bucket publicly readable. This is fine for news content but don't store private data in this bucket.

## Verifying Backend is Working

Check your backend is generating files:

```bash
ls -lht "/Users/rgupta/Desktop/newzyxIOS/newz - FINAL/alt" | head -5
```

You should see recent files (today or yesterday) with names like:
- `12.9.25_news_summary.txt`
- `12.9.25_podcast.mp3`

## Date Format Reference

The app uses this format: `M.D.YY`

**Examples:**
- December 9, 2025 → `12.9.25` (not `12.09.25`)
- January 5, 2025 → `1.5.25` (not `01.05.25`)
- November 27, 2025 → `11.27.25`

**Important:** No leading zeros for month or day!

## Still Having Issues?

1. **Check Xcode Console** - Look for error messages
2. **Use Debug View** - Verify URLs and test connectivity
3. **Test in Browser** - Open the generated URL directly
4. **Check Backend** - Verify files are being created locally
5. **Check S3** - Verify files are being uploaded to S3
6. **Check Date** - Ensure date format matches exactly

## Next Steps After Fixing

Once everything is working:
1. Remove or hide the debug button for production
2. Add better error messages in the UI
3. Consider adding offline caching
4. Add a refresh button to reload content


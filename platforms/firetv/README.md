# FaithSaver for Amazon Fire TV

This is the Fire TV / Fire Stick implementation of FaithSaver, built using Android's DreamService API.

## Requirements

- Android Studio (latest version recommended)
- Fire TV device or Android TV emulator
- Minimum SDK: API 21 (Android 5.0)
- Target SDK: API 34
- Kotlin 1.9+

## Project Structure

```
FaithSaverFireTV/
├── app/
│   ├── src/main/
│   │   ├── java/com/faithsaver/
│   │   │   ├── FaithSaverDream.kt         # Main screensaver service
│   │   │   ├── SettingsActivity.kt        # Settings UI
│   │   │   ├── models/Models.kt           # Data models
│   │   │   ├── network/GitHubApiClient.kt # API client
│   │   │   └── utils/Utils.kt             # Utilities
│   │   ├── res/
│   │   │   ├── drawable/
│   │   │   │   └── offline_default.jpg    # Default offline image
│   │   │   ├── xml/dream_info.xml         # Screensaver config
│   │   │   └── values/strings.xml         # String resources
│   │   └── AndroidManifest.xml
│   └── build.gradle
└── build.gradle
```

## Key Components

### FaithSaverDream.kt
The main screensaver service that:
- Extends Android's `DreamService`
- Manages two `ImageView` instances for smooth transitions
- Implements fade, slide, and zoom transitions
- Rotates images every 30 seconds
- Fetches images from GitHub API
- Implements offline-first loading

### SettingsActivity.kt
The settings interface that:
- Displays category list with single-choice selection
- Shows "About" dialog with app information
- Persists user preferences using SharedPreferences

### GitHubApiClient.kt
API client that:
- Fetches image list from GitHub Contents API
- Filters for valid image extensions (.jpg, .jpeg, .png)
- Converts GitHub URLs to direct download links

## Setup Instructions

### 1. Open in Android Studio
```bash
cd FaithSaverFireTV
# Open this directory in Android Studio
```

### 2. Add Offline Image
Place your default offline image at:
```
app/src/main/res/drawable/offline_default.jpg
```

### 3. Sync Gradle
Let Android Studio sync the Gradle files.

### 4. Build the Project
```bash
./gradlew assembleDebug
```

## Testing

### On Fire TV Device

1. **Enable ADB Debugging** on your Fire TV:
   - Go to Settings > My Fire TV > Developer Options
   - Turn on ADB Debugging
   - Turn on Apps from Unknown Sources

2. **Connect via ADB**:
   ```bash
   adb connect <FIRE_TV_IP_ADDRESS>
   ```

3. **Install APK**:
   ```bash
   adb install app/build/outputs/apk/debug/app-debug.apk
   ```

4. **Set as Screensaver**:
   - Go to Settings > Display & Sounds > Screen Saver
   - Select "FaithSaver"
   - Optionally set "Start Time"

### On Android TV Emulator

1. Create an Android TV Virtual Device in Android Studio
2. Run the app on the emulator
3. Access Settings > Display > Screensaver
4. Select FaithSaver

## Building for Release

### 1. Generate Signing Key

```bash
keytool -genkey -v -keystore faithsaver-release.keystore \
  -alias faithsaver -keyalg RSA -keysize 2048 -validity 10000
```

### 2. Create keystore.properties

Create `keystore.properties` in the project root:
```properties
storeFile=faithsaver-release.keystore
storePassword=YOUR_STORE_PASSWORD
keyAlias=faithsaver
keyPassword=YOUR_KEY_PASSWORD
```

### 3. Update build.gradle

Add signing configuration to `app/build.gradle`:
```gradle
android {
    signingConfigs {
        release {
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 4. Build Release APK

```bash
./gradlew assembleRelease
```

Output: `app/build/outputs/apk/release/app-release.apk`

## Publishing to Amazon Appstore

### 1. Create Amazon Developer Account
- Visit https://developer.amazon.com/apps-and-games
- Register and pay the one-time registration fee

### 2. Prepare App Assets
- Icon: 512x512 PNG
- Banner: 1920x720 PNG (for Fire TV home screen)
- Screenshots: At least 3-5 screenshots
- Privacy Policy URL
- App description and metadata

### 3. Submit App
1. Create new app in Amazon Developer Console
2. Fill in app details and metadata
3. Upload APK
4. Add screenshots and promotional images
5. Submit for review

### 4. Wait for Approval
Amazon typically reviews apps within 1-2 weeks.

## Features

- ✅ Offline-first with default image
- ✅ 30-second automatic rotation
- ✅ Three transition effects (Fade, Slide, Zoom)
- ✅ Category selection (10 categories)
- ✅ In-memory image caching
- ✅ About screen
- ✅ Optimized for Fire TV/Fire Stick

## Troubleshooting

### Screensaver doesn't start
- Verify DreamService is properly declared in AndroidManifest
- Check that Fire TV screensaver settings point to FaithSaver
- Ensure idle time is set appropriately

### Images not loading
- Check internet connection
- Verify GitHub repository URL is accessible
- Check logcat for network errors: `adb logcat | grep FaithSaver`

### App crashes on start
- Check logcat: `adb logcat | grep AndroidRuntime`
- Verify all required permissions in manifest
- Ensure minimum SDK requirements are met

## Performance Optimization

The app uses:
- LRU cache for bitmap memory management
- Coroutines for async operations
- View recycling for smooth transitions
- Proper lifecycle management

## License

MIT License - See parent repository LICENSE file

## Credits

Images sourced from: github.com/christhetech131/FaithSaver

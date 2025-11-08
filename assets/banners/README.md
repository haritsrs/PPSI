# Promotional Banners

Place your promotional banner images in this folder.

## Supported Formats
- PNG
- JPG/JPEG

## Recommended Size
- Width: 1080 pixels
- Height: 400 pixels
- Aspect Ratio: ~2.7:1

## How to Use

1. Add your banner images to this folder
2. Update the `_loadBanners()` method in `lib/main.dart` to include your banner file paths:

```dart
Future<void> _loadBanners() async {
  setState(() {
    _bannerImages = [
      'assets/banners/banner1.png',
      'assets/banners/banner2.jpg',
      'assets/banners/banner3.png',
    ];
  });
}
```

3. The banners will automatically display in the carousel on the home page

## Notes
- Banners will automatically rotate every 3 seconds
- The carousel supports smooth transitions and auto-play
- If no banners are found, a placeholder will be displayed


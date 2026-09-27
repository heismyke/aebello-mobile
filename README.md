# aebello-mobile

Aebello's Flutter app for iOS and Android.

Install dependencies with `flutter pub get`. Run the commands below from this repository.

## Development

```sh
flutter run                                             # debug, local API
flutter run --dart-define=API_URL=https://api.example.com
flutter build apk --dart-define=API_URL=https://api.example.com
flutter test
```

The Android emulator reaches the local API at `10.0.2.2:8080` automatically. Screens: Explore (search and destinations), plan picker with checkout (Paystack opens in the browser and the app follows the order until the eSIM is ready), My eSIMs dashboard, eSIM detail with an on-device QR code, manual codes and install steps, and Account.

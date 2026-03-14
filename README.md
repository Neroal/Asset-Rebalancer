# AssetRebalancer

![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?logo=swift&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-iOS_16+-007AFF?logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

An iOS portfolio management app that helps users track asset allocation and maintain their ideal investment ratios through automated rebalancing suggestions.

## Features

- **Multi-Asset Tracking**: Supports Taiwan stocks, US stocks, bonds, and cash — all valued in TWD
- **Real-Time Quotes**: Fetches live prices from TWSE (Taiwan Stock Exchange) and Yahoo Finance, with automatic USD/TWD currency conversion
- **Smart Rebalancing**: Calculates buy/sell recommendations based on customizable target allocations and deviation thresholds
- **Visual Dashboard**: Donut pie chart for intuitive visualization of portfolio allocation and deviations
- **Cloud Sync**: Data synced in real time to Firebase Firestore via Google Sign-In authentication
- **Bilingual UI**: Supports Traditional Chinese and English

## Screenshots

<!-- Add app screenshots here -->

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/Neroal/AssetRebalancer.git
   ```

2. Set up Firebase:
   - Create a project in the [Firebase Console](https://console.firebase.google.com/)
   - Enable **Authentication** (Google Sign-In) and **Firestore Database**
   - Download `GoogleService-Info.plist` and place it in the `AssetRebalancer/` directory

   > **Note**: `GoogleService-Info.plist` contains sensitive API keys and is excluded from version control via `.gitignore`. Never commit this file to a public repository.

3. Open `AssetRebalancer.xcodeproj` in Xcode

4. Install dependencies (resolved automatically via Swift Package Manager)

5. Select a simulator or device, then Build & Run

## Project Structure

```
AssetRebalancer/
├── AssetRebalancerApp.swift          # App entry point & Firebase initialization
├── ContentView.swift                 # Root navigation (login / main view switch)
├── Models/
│   ├── Asset.swift                   # Asset data model (stocks, bonds, cash)
│   └── Portfolio.swift               # Portfolio summary & rebalance actions
├── Services/
│   ├── AuthService.swift             # Google Sign-In authentication
│   ├── FirestoreService.swift        # Firestore data read/write
│   ├── StockAPIService.swift         # TW / US stock quotes (with caching)
│   └── ExchangeRateService.swift     # USD → TWD exchange rate conversion
├── Utils/
│   ├── PortfolioViewModel.swift      # Main state management ViewModel
│   └── Rebalancer.swift              # Rebalancing calculation logic
├── Localization/
│   └── LanguageViewModel.swift       # Chinese / English language toggle
└── Views/
    ├── Screens/
    │   ├── MainTabView.swift         # Tab navigation
    │   ├── LoginView.swift           # Google Sign-In screen
    │   ├── DashboardView.swift       # Portfolio overview dashboard
    │   ├── AssetsView.swift          # Asset list with add/edit
    │   └── SettingsView.swift        # Settings (target allocation, language)
    └── Components/
        ├── AssetRowView.swift        # Asset list row component
        └── PieChartView.swift        # Custom donut chart
```

## Tech Stack

| Area | Technology |
|------|------------|
| UI Framework | SwiftUI |
| Architecture | MVVM + `@EnvironmentObject` dependency injection |
| Concurrency | Swift Concurrency (async/await + Actor) |
| Backend | Firebase Auth + Firestore |
| Authentication | Google Sign-In |
| Stock Quotes | TWSE API, Yahoo Finance API |
| Exchange Rates | ExchangeRate-API (with fallback API) |

## Rebalancing Logic

The core feature calculates how far each asset category deviates from the user's target allocation:

- **Default Targets**: Stocks 60%, Bonds 30%, Cash 10% (customizable)
- **Deviation Threshold**: Default 5% (adjustable from 1% to 20%)
- When any category's actual percentage exceeds the threshold, the app suggests specific TWD amounts to buy or sell

## Caching Strategy

To reduce API calls and improve performance:

- Stock price cache TTL: **1 hour**
- Exchange rate cache TTL: **24 hours**

## Contributing

Contributions are welcome! If you'd like to help improve AssetRebalancer:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

For bug reports or feature requests, please [open an issue](https://github.com/Neroal/AssetRebalancer/issues).

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

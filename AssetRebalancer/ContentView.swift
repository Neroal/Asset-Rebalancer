import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var languageVM: LanguageViewModel

    var body: some View {
        Group {
            if authVM.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if authVM.isSignedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authVM.isSignedIn)
    }
}

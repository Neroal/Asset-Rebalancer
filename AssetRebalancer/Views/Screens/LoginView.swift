import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var lang: LanguageViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App Icon
                Image("AppIconDisplay")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(radius: 10)

                // Title
                VStack(spacing: 12) {
                    Text(lang.welcome)
                        .font(.system(size: 32, weight: .bold))

                    Text(lang.loginSubtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Google Sign In Button
                Button(action: {
                    Task {
                        await authVM.signInWithGoogle()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle.fill")
                            .font(.title2)

                        Text(lang.signInWithGoogle)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }
                .padding(.horizontal, 32)

                // Error
                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

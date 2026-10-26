//
//  AuthViewModel.swift
//  shifthand
//
//  State and validation logic for staff SignInView and RegisterView.
//

import SwiftUI
import Observation

@Observable
@MainActor
public final class AuthViewModel {
    public var name: String = ""
    public var email: String = ""
    public var password: String = ""
    public var isSecure: Bool = true
    public var state: ViewState<User> = .idle
    public var errorMessage: String? = nil

    private let appSession: AppSession

    public init(appSession: AppSession) {
        self.appSession = appSession
    }

    public var isSignInValid: Bool {
        return isValidEmail(email) && !password.isEmpty
    }

    public var isRegisterValid: Bool {
        return !name.trimmingCharacters(in: .whitespaces).isEmpty &&
               isValidEmail(email) &&
               password.count >= 8
    }

    public func signIn() async {
        guard isSignInValid else {
            errorMessage = "Please enter a valid email and password."
            return
        }

        state = .loading
        errorMessage = nil

        do {
            try await appSession.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            if let user = appSession.currentUser {
                state = .loaded(user)
            } else {
                state = .idle
            }
        } catch let appError as AppError {
            state = .failed(appError)
            errorMessage = appError.errorDescription
        } catch {
            let appError = AppError.unknown(error.localizedDescription)
            state = .failed(appError)
            errorMessage = appError.errorDescription
        }
    }

    public func register() async {
        guard isRegisterValid else {
            if password.count < 8 {
                errorMessage = "Password must be at least 8 characters long."
            } else {
                errorMessage = "Please fill in all fields with a valid email."
            }
            return
        }

        state = .loading
        errorMessage = nil

        do {
            try await appSession.register(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            if let user = appSession.currentUser {
                state = .loaded(user)
            } else {
                state = .idle
            }
        } catch let appError as AppError {
            state = .failed(appError)
            errorMessage = appError.errorDescription
        } catch {
            let appError = AppError.unknown(error.localizedDescription)
            state = .failed(appError)
            errorMessage = appError.errorDescription
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

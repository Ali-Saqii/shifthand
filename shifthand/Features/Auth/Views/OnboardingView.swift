//
//  OnboardingView.swift
//  shifthand
//
//  Welcome and onboarding screen presented to staff with 0 organisation memberships.
//  Strictly compliant with Docs/SCREENS.md and Plan v3 Day 3.
//

import SwiftUI

public struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showingCreateOrg = false
    @State private var showingJoinOrg = false

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.shPrimaryTeal)

                            Text("Welcome to ShiftHand")
                                .font(.title.bold())
                                .foregroundStyle(Color.shTextPrimary)

                            Text("You are not part of an organisation yet. Get started by creating your organisation or joining with an invite code.")
                                .font(.subheadline)
                                .foregroundStyle(Color.shTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 32)

                        // Action Options
                        VStack(spacing: 16) {
                            // Option 1: Create Organisation
                            Button(action: { showingCreateOrg = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.shPrimaryTeal.opacity(0.12))
                                            .frame(width: 48, height: 48)

                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(Color.shPrimaryTeal)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Create Organisation")
                                            .font(.headline)
                                            .foregroundStyle(Color.shTextPrimary)

                                        Text("Start a new workspace as an organisation owner.")
                                            .font(.caption)
                                            .foregroundStyle(Color.shTextSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.shTextSecondary)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: SHMetrics.cardCornerRadius)
                                        .fill(Color.shBackgroundCard)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: SHMetrics.cardCornerRadius)
                                        .stroke(Color.shBorderDefault, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            // Option 2: Join with Code
                            Button(action: { showingJoinOrg = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.shAccentAmber.opacity(0.12))
                                            .frame(width: 48, height: 48)

                                        Image(systemName: "ticket.fill")
                                            .font(.title2)
                                            .foregroundStyle(Color.shAccentAmber)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Join with Invite Code")
                                            .font(.headline)
                                            .foregroundStyle(Color.shTextPrimary)

                                        Text("Enter an 8-character code sent by your owner.")
                                            .font(.caption)
                                            .foregroundStyle(Color.shTextSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.shTextSecondary)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: SHMetrics.cardCornerRadius)
                                        .fill(Color.shBackgroundCard)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: SHMetrics.cardCornerRadius)
                                        .stroke(Color.shBorderDefault, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Sign Out Button
                        Button(role: .destructive, action: { viewModel.signOut() }) {
                            Text("Sign Out")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.shStatusRed)
                                .frame(height: SHMetrics.minTouchTarget)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 16)
                    }
                    .padding(20)
                }
            }
            .sheet(isPresented: $showingCreateOrg) {
                CreateOrgView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingJoinOrg) {
                JoinOrgView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Previews (Light and Dark)
#Preview("OnboardingView - Light") {
    OnboardingView(viewModel: OnboardingViewModel(appSession: AppSession()))
        .preferredColorScheme(.light)
}

#Preview("OnboardingView - Dark") {
    OnboardingView(viewModel: OnboardingViewModel(appSession: AppSession()))
        .preferredColorScheme(.dark)
}

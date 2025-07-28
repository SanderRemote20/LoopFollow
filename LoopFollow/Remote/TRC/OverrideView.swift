// LoopFollow
// OverrideView.swift
// Created by Jonas Björkert.

import HealthKit
import SwiftUI

struct OverrideView: View {
    @Environment(\.presentationMode) private var presentationMode
    private let pushNotificationManager = PushNotificationManager()

    @ObservedObject var device = Storage.shared.device
    @ObservedObject var overrideNote = Observable.shared.override

    @State private var showAlert: Bool = false
    @State private var alertType: AlertType? = nil
    @State private var alertMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var statusMessage: String? = nil

    @State private var selectedOverride: ProfileManager.TrioOverride? = nil
    @State private var showConfirmation: Bool = false

    @FocusState private var noteFieldIsFocused: Bool

    private var profileManager = ProfileManager.shared

    enum AlertType {
        case confirmActivation
        case confirmCancellation
        case statusSuccess
        case statusFailure
        case validation
    }

    var body: some View {
        NavigationView {
            VStack {
                if device.value != "Trio" {
                    ErrorMessageView(
                        message: "Remote commands are currently only available for Trio."
                    )
                } else {
                    Form {
                        if let activeNote = overrideNote.value {
                            Section(header: Text("Aktiv overstyring")) {
                                HStack {
                                    Text("Overstyring")
                                    Spacer()
                                    Text(activeNote)
                                        .foregroundColor(.secondary)
                                }
                                Button {
                                    alertType = .confirmCancellation
                                    showAlert = true
                                } label: {
                                    HStack {
                                        Text("Kanseller overstyring")
                                        Spacer()
                                        Image(systemName: "xmark.app")
                                            .font(.title)
                                    }
                                }
                                .tint(.red)
                            }
                        }

                        Section(header: Text("Tilgjengelige overstyringer")) {
                            if profileManager.trioOverrides.isEmpty {
                                Text("Ingen overstyringer tilgjengelige.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(profileManager.trioOverrides, id: \.name) { override in
                                    Button(action: {
                                        selectedOverride = override
                                        alertType = .confirmActivation
                                        showAlert = true
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(override.name)
                                                    .font(.headline)
                                                if let duration = override.duration {
                                                    Text("Duration: \(Int(duration)) minutes")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                                if let percentage = override.percentage {
                                                    Text("Percentage: \(Int(percentage))%")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }

                                                if let target = override.target {
                                                    Text("Target: \(Localizer.formatQuantity(target)) \(Localizer.getPreferredUnit().localizedShortUnitString)")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.right.circle")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if isLoading {
                        ProgressView("Please wait...")
                            .padding()
                    }
                }
            }
            .navigationTitle("Overstyringer")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                switch alertType {
                case .confirmActivation:
                    return Alert(
                        title: Text("Aktiver overstyring"),
                        message: Text("Vil du aktivere overstyringen '\(selectedOverride?.name ?? "")'?"),
                        primaryButton: .default(Text("Bekreft"), action: {
                            if let override = selectedOverride {
                                activateOverride(override)
                            }
                        }),
                        secondaryButton: .cancel()
                    )
                case .confirmCancellation:
                    return Alert(
                        title: Text("Kanseller overstyring"),
                        message: Text("Er du sikker på at du vil kansellere den aktive overstyringen?"),
                        primaryButton: .default(Text("Bekreft"), action: {
                            cancelOverride()
                        }),
                        secondaryButton: .cancel()
                    )
                case .statusSuccess:
                    return Alert(
                        title: Text("Suksess"),
                        message: Text(statusMessage ?? ""),
                        dismissButton: .default(Text("OK"), action: {
                            presentationMode.wrappedValue.dismiss()
                        })
                    )
                case .statusFailure:
                    return Alert(
                        title: Text("Feil"),
                        message: Text(statusMessage ?? "En feil oppstod."),
                        dismissButton: .default(Text("OK"))
                    )
                case .validation:
                    return Alert(
                        title: Text("Valideringsfeil"),
                        message: Text(alertMessage ?? "Ugyldig inndata."),
                        dismissButton: .default(Text("OK"))
                    )
                case .none:
                    return Alert(title: Text("Ukjent varsel"))
                }
            }
        }
    }

    // MARK: - Functions

    private func activateOverride(_ override: ProfileManager.TrioOverride) {
        isLoading = true

        pushNotificationManager.sendOverridePushNotification(override: override) { success, errorMessage in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.statusMessage = "Overstyringskommando vellykket."
                    self.alertType = .statusSuccess
                    LogManager.shared.log(category: .apns, message: "sendOverridePushNotification succeeded for override: \(override.name)")
                } else {
                    self.statusMessage = errorMessage ?? "Kunne ikke sende overstyringskommandoen."
                    self.alertType = .statusFailure
                    LogManager.shared.log(category: .apns, message: "sendOverridePushNotification failed for override: \(override.name). Error: \(errorMessage ?? "ukjent feil")")
                }
                self.showAlert = true
            }
        }
    }

    private func cancelOverride() {
        isLoading = true

        pushNotificationManager.sendCancelOverridePushNotification { success, errorMessage in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.statusMessage = "Cancel override command sent successfully."
                    self.alertType = .statusSuccess
                    LogManager.shared.log(category: .apns, message: "sendCancelOverridePushNotification succeeded")
                } else {
                    self.statusMessage = errorMessage ?? "Failed to send cancel override command."
                    self.alertType = .statusFailure
                    LogManager.shared.log(category: .apns, message: "sendCancelOverridePushNotification failed. Error: \(errorMessage ?? "unknown error")")
                }
                self.showAlert = true
            }
        }
    }
}

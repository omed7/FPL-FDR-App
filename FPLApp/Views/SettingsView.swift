import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: FPLManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sort & Filter")) {
                    Toggle("Sort by Easiest Fixtures", isOn: $manager.sortByEase)

                    Stepper("Start GW: \(manager.startGameweek)", value: $manager.startGameweek, in: 1...manager.endGameweek)
                    Stepper("End GW: \(manager.endGameweek)", value: $manager.endGameweek, in: manager.startGameweek...38)
                }

                Section(header: Text("Team Visibility")) {
                    // Visual Grid of logos
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))]) {
                        ForEach(manager.teams) { team in
                            let isVisible = manager.teamVisibility[team.id] ?? true
                            Button(action: {
                                manager.toggleVisibility(teamId: team.id)
                            }) {
                                TeamLogoView(team: team)
                                    .opacity(isVisible ? 1.0 : 0.3)
                                    .overlay(
                                        !isVisible ? Image(systemName: "eye.slash.fill").foregroundColor(.white) : nil
                                    )
                            }
                        }
                    }
                    .padding(.vertical)
                }

                Section(header: Text("Difficulty Overrides")) {
                    NavigationLink("Edit Team Strengths") {
                        TeamStrengthEditor(manager: manager)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct TeamStrengthEditor: View {
    @ObservedObject var manager: FPLManager

    var body: some View {
        List {
            ForEach(manager.teams) { team in
                VStack(alignment: .leading) {
                    HStack {
                        TeamLogoView(team: team)
                        Text(team.name).font(.headline)
                    }

                    HStack {
                        Text("Home Strength:")
                        Spacer()
                        StrengthPicker(value: Binding(
                            get: { manager.getStrength(teamId: team.id, location: "home") },
                            set: { manager.updateStrength(teamId: team.id, location: "home", value: $0) }
                        ))
                    }

                    HStack {
                        Text("Away Strength:")
                        Spacer()
                        StrengthPicker(value: Binding(
                            get: { manager.getStrength(teamId: team.id, location: "away") },
                            set: { manager.updateStrength(teamId: team.id, location: "away", value: $0) }
                        ))
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("Team Strengths")
    }
}

struct StrengthPicker: View {
    @Binding var value: Int

    var body: some View {
        Menu {
            ForEach(1...7, id: \.self) { i in
                Button("\(i)") { value = i }
            }
        } label: {
            Text("\(value)")
                .font(.headline)
                .frame(width: 30, height: 30)
                .background(Theme.color(for: value))
                .foregroundColor(Theme.textColor(for: Theme.color(for: value)))
                .cornerRadius(5)
        }
    }
}

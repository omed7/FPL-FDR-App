import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: FPLManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display Options")) {
                    Toggle("Sort by Easiest Fixtures", isOn: $manager.sortByEase)

                    Stepper("Start GW: \(manager.startGameweek)", value: $manager.startGameweek, in: 1...manager.endGameweek)
                    Stepper("End GW: \(manager.endGameweek)", value: $manager.endGameweek, in: manager.startGameweek...38)
                }

                Section(header: Text("Team Visibility")) {
                    // Grid of logos
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                        ForEach(manager.teams) { team in
                            TeamLogoView(teamShortName: team.short_name)
                                .opacity((manager.teamVisibility[team.id] ?? true) ? 1.0 : 0.3)
                                .onTapGesture {
                                    manager.toggleVisibility(teamId: team.id)
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
                        TeamLogoView(teamShortName: team.short_name)
                        Text(team.name)
                            .font(.headline)
                    }

                    HStack {
                        Text("Home:")
                        Spacer()
                        StrengthPicker(
                            selection: Binding(
                                get: { manager.getStrength(teamId: team.id, location: "home") },
                                set: { manager.updateStrength(teamId: team.id, location: "home", value: $0) }
                            )
                        )
                    }

                    HStack {
                        Text("Away:")
                        Spacer()
                        StrengthPicker(
                            selection: Binding(
                                get: { manager.getStrength(teamId: team.id, location: "away") },
                                set: { manager.updateStrength(teamId: team.id, location: "away", value: $0) }
                            )
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Team Strengths")
    }
}

struct StrengthPicker: View {
    @Binding var selection: Int

    var body: some View {
        Menu {
            ForEach(1...7, id: \.self) { i in
                Button(action: { selection = i }) {
                    HStack {
                        Text("\(i)")
                        if i == selection { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack {
                Text("\(selection)")
                    .fontWeight(.bold)
                    .foregroundColor(Theme.contrastTextColor(for: Theme.color(for: selection)))
                    .frame(width: 30, height: 30)
                    .background(Theme.color(for: selection))
                    .cornerRadius(4)
            }
        }
    }
}

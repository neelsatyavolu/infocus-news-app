import SwiftUI

/// Send an announcement for InFocus News to read on air.
struct AnnounceView: View {
    @Environment(Preferences.self) private var preferences
    @Environment(ShowsStore.self) private var shows
    @State private var model: AnnounceModel?

    var body: some View {
        Group {
            if let model {
                if model.status == .sent {
                    SentView { model.startOver() }
                } else {
                    AnnounceForm(model: model)
                }
            }
        }
        .brandBackground()
        .readableMargins()
        .navigationTitle("Announcement")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model == nil {
                model = AnnounceModel(name: preferences.announcerName, email: preferences.announcerEmail)
            }
            await shows.load()
            model?.useShowDates(shows.feed.value?.upcomingShowDates ?? [])
        }
    }
}

private struct AnnounceForm: View {
    @Bindable var model: AnnounceModel
    @Environment(Preferences.self) private var preferences
    @FocusState private var focused: Bool

    var body: some View {
        Form {
            Section {
                Text("Announcements run on InFocus News (and the Schoology Update if you choose). Producers review each one before it airs.")
                    .font(.small)
                    .foregroundStyle(Brand.secondary)
                    .listRowBackground(Color.clear)
            }
            Section("About you") {
                TextField("Full name", text: $model.form.name)
                    .textContentType(.name)
                TextField("Email", text: $model.form.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker("I am a", selection: $model.form.submitterKind) {
                    ForEach(AnnouncementSubmission.SubmitterKind.allCases) { Text($0.label).tag($0) }
                }
            }
            Section {
                TextField("What should we announce?", text: $model.form.announcement, axis: .vertical)
                    .lineLimit(5...12)
                    .focused($focused)
                Picker("Run on", selection: $model.form.runOn) {
                    ForEach(AnnouncementSubmission.RunOn.allCases) { Text($0.label).tag($0) }
                }
            } header: {
                Text("Announcement")
            } footer: {
                Text("\(model.form.announcement.count) / \(AnnouncementSubmission.maxLength)")
                    .font(.mono(12))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            DatesSection(model: model)
            Section("Optional") {
                TextField("Link to a flyer or video (https://…)", text: optional(\.mediaLink))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Anything else we should know", text: optional(\.moreInfo), axis: .vertical)
                    .lineLimit(2...6)
            }
            Section {
                Toggle(AnnouncementSubmission.policyText, isOn: $model.form.policyAgreed)
                    .font(.small)
            }
            Section {
                if let error = model.error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.small)
                        .foregroundStyle(Brand.danger)
                        .listRowBackground(Brand.dangerTint)
                }
                Button {
                    Task {
                        focused = false
                        if await model.submit() {
                            preferences.announcerName = model.form.name.trimmed
                            preferences.announcerEmail = model.form.email.trimmed
                        }
                    }
                } label: {
                    if model.status == .sending { ProgressView().tint(Brand.softWhite) } else { Text("Send announcement") }
                }
                .buttonStyle(.brandPrimary)
                .disabled(model.status == .sending)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } footer: {
                Text("InFocus uses your name and email only to review your announcement and contact you about it. [Privacy policy](https://infocuspaly.com/privacy)")
                    .font(.small)
                    .foregroundStyle(Brand.muted)
                    .tint(Brand.green)
                    .padding(.top, 8)
            }
        }
        .font(.bodyText)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func optional(_ keyPath: WritableKeyPath<AnnouncementSubmission, String?>) -> Binding<String> {
        Binding(get: { model.form[keyPath: keyPath] ?? "" }, set: { model.form[keyPath: keyPath] = $0 })
    }
}

/// First and last show: picked from real show days when the schedule is known.
private struct DatesSection: View {
    @Bindable var model: AnnounceModel

    var body: some View {
        Section {
            if model.showDates.isEmpty {
                DatePicker("First day", selection: dateBinding(\.startDate), displayedComponents: .date)
                DatePicker("Last day", selection: dateBinding(\.endDate), displayedComponents: .date)
            } else {
                Picker("First show", selection: Binding(get: { model.form.startDate }, set: { model.setStart($0) })) {
                    ForEach(model.showDates, id: \.self) { Text(label($0)).tag($0) }
                }
                Picker("Last show", selection: $model.form.endDate) {
                    ForEach(model.endChoices, id: \.self) { Text(label($0)).tag($0) }
                }
            }
        } header: {
            Text("Show dates")
        } footer: {
            Text("Up to \(AnnouncementSubmission.maxShowDays) consecutive show days. Shows air Wednesdays and Fridays.")
        }
    }

    private func label(_ key: String) -> String {
        ShowDate.parse(key).map(ShowDate.short) ?? key
    }

    private func dateBinding(_ keyPath: WritableKeyPath<AnnouncementSubmission, String>) -> Binding<Date> {
        Binding(get: { ShowDate.parse(model.form[keyPath: keyPath]) ?? .now },
                set: { model.form[keyPath: keyPath] = ShowDate.key($0) })
    }
}

private struct SentView: View {
    let another: () -> Void

    var body: some View {
        ScrollView {
            EmptyStateView(title: "Announcement sent",
                           message: "Thanks! InFocus producers review every announcement before it airs.",
                           actionTitle: "Send another", action: another)
                .padding(.top, 40)
        }
    }
}

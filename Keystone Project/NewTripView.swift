import SwiftUI
import PhotosUI

struct NewTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State var tripName: String
    @State var startDate: Date
    @State var endDate: Date
    @State var selectedPhotoItem: PhotosPickerItem?
    @State var tripImage: Data?
    @FocusState var isTextFieldFocused: Bool
    @State var isInfiniteDuration: Bool
    
    var title: String
    var onSave: ((String, Date, Date?, Data?) -> Void)?
    
    init(
        tripName: String = "",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(86400 * 7),
        tripImage: Data? = nil,
        isInfiniteDuration: Bool = false,
        title: String = "New Trip",
        onSave: ((String, Date, Date?, Data?) -> Void)? = nil
    ) {
        _tripName = State(initialValue: tripName)
        _startDate = State(initialValue: startDate)
        _endDate = State(initialValue: endDate)
        _tripImage = State(initialValue: tripImage)
        _isInfiniteDuration = State(initialValue: isInfiniteDuration)
        self.title = title
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Trip Name", text: $tripName)
                        .focused($isTextFieldFocused)
                    
                    DatePicker("Start Date",
                              selection: $startDate,
                              displayedComponents: .date)
                        .onTapGesture {
                            hideKeyboard()
                            isTextFieldFocused = false
                        }
                    
                    HStack(spacing: 8) {
                        Text("End Date")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            isInfiniteDuration.toggle()
                            hideKeyboard()
                            isTextFieldFocused = false
                        }) {
                            Image(systemName: "infinity")
                                .frame(width: 30, height: 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isInfiniteDuration ? Color.blue : Color.gray.opacity(0.15))
                                )
                                .foregroundColor(isInfiniteDuration ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        
                        DatePicker("", // Empty title since we're using custom label
                                  selection: $endDate,
                                  in: startDate...,
                                  displayedComponents: .date)
                            .labelsHidden() // Hide the default label
                            .disabled(isInfiniteDuration)
                            .opacity(isInfiniteDuration ? 0.5 : 1)
                            .onTapGesture {
                                hideKeyboard()
                                isTextFieldFocused = false
                            }
                    }
                }
                
                Section(header: Text("Trip Photo (Optional)")) {
                    VStack {
                        if let tripImage = tripImage, let uiImage = UIImage(data: tripImage) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                                .padding(.bottom, 8)
                        }
                        
                        PhotosPicker(selection: $selectedPhotoItem,
                                    matching: .images) {
                            Label(
                                tripImage == nil ? "Add Cover Photo" : "Change Cover Photo",
                                systemImage: "photo"
                            )
                        }
                        .buttonStyle(.borderless)
                        .onTapGesture {
                            hideKeyboard()
                            isTextFieldFocused = false
                        }
                        .onChange(of: selectedPhotoItem) { newItem in
                            isTextFieldFocused = false
                            Task {
                                guard let photoItem = newItem else { return }
                                
                                if let data = try? await photoItem.loadTransferable(type: Data.self) {
                                    await MainActor.run {
                                        self.tripImage = data
                                        isTextFieldFocused = false
                                    }
                                }
                            }
                        }
                        
                        if tripImage != nil {
                            Button(role: .destructive) {
                                selectedPhotoItem = nil
                                tripImage = nil
                            } label: {
                                Label("Remove Cover Photo", systemImage: "trash")
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let onSave = onSave {
                            onSave(tripName, startDate, isInfiniteDuration ? nil : endDate, tripImage)
                        } else {
                            saveTrip()
                        }
                        dismiss()
                    }
                    .disabled(tripName.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    func saveTrip() {
        // If user didn't enter a name, use "Untitled Trip" as fallback
        let finalName = tripName.isEmpty ? "Untitled Trip" : tripName
        
        // Create the trip
        let trip = dataController.addTrip(
            name: finalName,
            startDate: startDate,
            endDate: isInfiniteDuration ? nil : endDate,
            tripImage: tripImage
        )
        
        // Create journal entries for each day
        let calendar = Calendar.current
        let currentDate = Date()
        let endDateForEntries = min(isInfiniteDuration ? currentDate : endDate, currentDate)
        
        var currentDay = startDate
        while currentDay <= endDateForEntries {
            dataController.addJournalEntry(for: trip, date: currentDay)
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NewTripView()
        .environmentObject(DataController())
}

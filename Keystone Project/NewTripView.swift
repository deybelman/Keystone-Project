import SwiftUI
import PhotosUI

struct NewTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7) // One week from current date
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var tripImage: Data?
    @FocusState private var isTextFieldFocused: Bool
    
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
                    
                    DatePicker("End Date",
                              selection: $endDate,
                              in: startDate...,
                              displayedComponents: .date)
                        .onTapGesture {
                            hideKeyboard()
                            isTextFieldFocused = false
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
                        
                        if selectedPhotoItem != nil {
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
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTrip()
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
    
    private func saveTrip() {
        // If user didn't enter a name, use "Untitled Trip" as fallback
        let finalName = tripName.isEmpty ? "Untitled Trip" : tripName
        
        dataController.addTrip(
            name: finalName,
            startDate: startDate,
            endDate: endDate,
            tripImage: tripImage
        )
    }
    
    private func checkSelectedImageExists() -> Bool {
        return selectedPhotoItem != nil
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

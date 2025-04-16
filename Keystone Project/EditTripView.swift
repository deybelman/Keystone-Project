import SwiftUI
import PhotosUI

struct EditTripView: View {
    let trip: TripEntity
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NewTripView(
            tripName: trip.name ?? "",
            startDate: trip.startDate ?? Date(),
            endDate: trip.endDate ?? Date().addingTimeInterval(86400 * 7),
            tripImage: trip.tripImage,
            isInfiniteDuration: trip.endDate == nil,
            title: "Edit Trip",
            onSave: { name, startDate, endDate, image in
                trip.name = name
                trip.startDate = startDate
                trip.endDate = endDate
                trip.tripImage = image
                dataController.save()
            }
        )
        .safeAreaInset(edge: .bottom) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Trip")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .alert("Delete Trip", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataController.deleteTrip(trip)
                // Dismiss the edit sheet
                dismiss()
                // Pop back to the trip list
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this trip? This action cannot be undone.")
        }
    }
}

#Preview {
    EditTripView(trip: TripEntity())
        .environmentObject(DataController())
} 
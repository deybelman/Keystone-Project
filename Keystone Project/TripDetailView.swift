import SwiftUI

struct TripDetailView: View {
    let trip: TripEntity
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Cover Image Section
                ZStack(alignment: .bottomLeading) {
                    if let imageData = trip.tripImage,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            // Make the image fill horizontally
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .overlay {
                                Image(systemName: "airplane")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                    }

                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .clear, location: 0.6),
                            .init(color: Color(.systemBackground), location: 0.9),
                            .init(color: Color(.systemBackground), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 260)

                    // Title and Date overlay
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.name ?? "Untitled Trip")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        if let startDate = trip.startDate {
                            Text(DateFormatting.tripDateRangeText(from: startDate, to: trip.endDate))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                    .padding(.bottom, 40)
                }
                .frame(height: 260)

                 
                HStack {
                    Spacer()
                    // Calendar Section with horizontal padding
                    TripCalendarView(selectedDate: .constant(nil),
                                     startDate: trip.startDate!,
                                     endDate: trip.endDate)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTripView(trip: trip)
        }
    }
}


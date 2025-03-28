import SwiftUI

struct ImageGalleryView: View {
    let note: NoteEntity?
    let imageGroup: ImageGroupEntity?
    let associatedText: String?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // Add a state property to store the fetched images
    @State private var images: [ImageAttachmentEntity] = []
    @State private var scrollID: Int?
    @State private var currentImage: ImageAttachmentEntity?
    
    // Computed property for truncated title
    private var truncatedTitle: String {
        guard let text = associatedText, !text.isEmpty else { return "" }
        
        // Maximum character length for the title before truncation
        let maxLength = 30
        
        if text.count > maxLength {
            let endIndex = text.index(text.startIndex, offsetBy: maxLength)
            return String(text[..<endIndex]) + "..."
        }
        
        return text
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(0..<images.count, id: \.self) { index in
                        let currentImage = images[index]
                            Image(uiImage: UIImage(data: currentImage.imageData!)!)
                                    .resizable()
                                    .scaledToFit()
                                    .shadow(radius: 10)
                                    .cornerRadius(10)
                                    .padding()
                                    .containerRelativeFrame(.horizontal)
                                    .scrollTransition(.animated, axis: .horizontal) { content, phase in
                                        content
                                            .opacity(phase.isIdentity ? 1.0 : 0.6)
                                            .scaleEffect(phase.isIdentity ? 1.0 : 0.6)
                                    }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrollID)
                .scrollTargetBehavior(.paging)
                
                // Only show the indicator if there's more than one image
                if images.count > 1 {
                    IndicatorView(imageCount: images.count, scrollID: $scrollID)
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle(truncatedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(truncatedTitle)
                        .font(.headline.weight(.regular)) // Regular weight instead of bold
                        .foregroundColor(.orange)
                        .underline()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .onAppear {
            // When the view appears, fetch the images for the imageGroup
            if let imageGroup = imageGroup {
                images = dataController.fetchImagesinGroup(imageGroup)
            }
        }
    }
}


struct IndicatorView: View {
    let imageCount: Int
    @Binding var scrollID: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<imageCount, id: \.self) { indicatorIndex in
                let isSelected = indicatorIndex == (scrollID ?? 0)
                Button {
                    withAnimation {
                        scrollID = indicatorIndex
                    }
                } label: {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.secondary.opacity(0.5))
//                        .frame(width: isSelected ? 10 : 8, height: isSelected ? 10 : 8)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(8)
        .background(Capsule().fill(Color.secondary.opacity(0.2)))
        .animation(.easeInOut, value: scrollID)
    }
}

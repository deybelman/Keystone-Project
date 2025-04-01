import SwiftUI
import PhotosUI

struct EditNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataController: DataController
    
    var note: JournalEntryEntity?
    
    @State private var attributedContent = NSAttributedString(string: "")
    @State private var showingFormatting = false
    @State private var selectedRange = NSRange()
    @State private var currentStyle = TextStyle()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
//    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedTextRange: NSRange?  // Needed to make sure image is attributed to correct text, not the text highlighted when async image loading completes
    @StateObject var imageViewerManager = ImageViewerManager()
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: note?.date ?? Date())
    }
    
    class ImageViewerManager: ObservableObject {
        @Published var selectedAssociatedID: String?
        @Published var showingImageViewer: Bool = false
    }
    
    var body: some View {
        let richTextEditor = RichTextEditor(
            text: $attributedContent,
            selectedRange: $selectedRange,
            currentStyle: $currentStyle,
            onImageLinkTap: {url in
                handleLinkTap(url)
                return true // Tell rich text editor that we've handled the tap
            }
        )
        
        richTextEditor
            .padding(.horizontal)
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if let note = note {
                            dataController.editNote(note, newAttributedContent: attributedContent)
                        } else {
                            dataController.addNote(attributedContent: attributedContent)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        let hasAttachmentInRange = selectedRange.length > 0 ? checkForAttachmentInRange(attributedContent, range: selectedRange) : false
                        
                        PhotosPicker(selection: $selectedPhotoItems,
                                     maxSelectionCount: 10,
                                     matching: .images) {
                            Image(systemName: "photo.badge.plus")
                                .foregroundColor(
                                    // Only blue when text is selected AND has no image attachment in the entire range
                                    selectedRange.length > 0 && !hasAttachmentInRange ? 
                                    .blue : .gray
                                )
                        }
                        .disabled(
                            // Disable the button if no text is selected OR any part of the range has an attachment
                            selectedRange.length == 0 || hasAttachmentInRange
                        )
                        
                        Button(action: {
                            showingFormatting.toggle()
                        }) {
                            Image(systemName: "textformat")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFormatting) {
                FormatToolbar(
                    attributedText: $attributedContent,
                    selectedRange: selectedRange,
                    currentStyle: $currentStyle,
                    richTextEditor: richTextEditor
                )
                .presentationDetents([.height(70)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.ultraThinMaterial)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
                .edgesIgnoringSafeArea(.bottom)
            }
            .sheet(isPresented: $imageViewerManager.showingImageViewer) {
                if let associatedGroupID = imageViewerManager.selectedAssociatedID, 
                    let journalEntryEntity = note {
                    
                    let imageGroup = dataController.fetchImageGroup(for: journalEntryEntity, associatedID: associatedGroupID)
                    let associatedText = imageGroup?.associatedText ?? ""
                    
                    ImageGalleryView(note: journalEntryEntity, imageGroup: imageGroup, associatedText: associatedText)
                        .environmentObject(dataController)
                } else {
                    // Fallback view if either value is nil
                    Text("Cannot display image viewer - missing required information")
                }
            }
            .onAppear {
                if let note = note, let data = note.attributedContent,
                   let attributedString = try? NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtfd],
                    documentAttributes: nil) {
                    attributedContent = attributedString
                } else {
                    attributedContent = NSAttributedString(
                        string: note?.content ?? "",
                        attributes: [.font: UIFont.systemFont(ofSize: 17)]
                    )
                }
            }
            .onChange(of: selectedPhotoItems) { oldItems, newItems in
                guard !newItems.isEmpty, let note = note else { return }
                
                let associatedID = UUID().uuidString
                selectedTextRange = selectedRange
                let selectedText = attributedContent.attributedSubstring(from: selectedTextRange ?? NSRange()).string
                
                let imageGroup = dataController.createImageGroup(for: note,
                                                associatedID: associatedID,
                                                associatedText: selectedText)
                
                let mutableAttributedContent = NSMutableAttributedString(attributedString: attributedContent)
                
                // Add the associatedID first
                mutableAttributedContent.addAttribute(NSAttributedString.Key("associatedID"),
                                                      value: associatedID,
                                                      range: selectedTextRange ?? selectedRange)
                
                // Add the color separately
                mutableAttributedContent.addAttribute(.foregroundColor,
                                                      value: UIColor.orange,
                                                      range: selectedTextRange ?? selectedRange)
                
                // Add underline for links - using a custom key to distinguish from regular underline
                mutableAttributedContent.addAttribute(.underlineStyle,
                                                      value: NSUnderlineStyle.single.rawValue,
                                                      range: selectedTextRange ?? selectedRange)

                mutableAttributedContent.addAttribute(NSAttributedString.Key("linkUnderline"),
                                                      value: true,
                                                      range: selectedTextRange ?? selectedRange)
                
                // Add the link attribute for the selected text
                let associatedImageURL = URL(string: "image://\(associatedID)")!
                mutableAttributedContent.addAttribute(.link,
                                                      value: associatedImageURL,
                                                      range: selectedTextRange ?? selectedRange)
                

                attributedContent = mutableAttributedContent
                    
                    // Process each selected photo item
                    Task {
                        // Process each photo asynchronously
                        for item in selectedPhotoItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                // Add each image to the group
                                dataController.addImageToGroup(imageData: data, group: imageGroup)
                            }
                        }
    
                        // Reset selection when done
                        DispatchQueue.main.async {
                            selectedPhotoItems = []
                        }
                        
                        dataController.save()
                    }
                }
            }
    
    private func handleLinkTap(_ url: URL) -> Bool {
        guard url.scheme == "image" else {
            return false
        }
        
        let associatedImageGroupID = url.host ?? ""
        imageViewerManager.selectedAssociatedID = associatedImageGroupID
        print("associatedImageID: \(associatedImageGroupID)")
        print("selectedAssociatedID")
        imageViewerManager.showingImageViewer = true
        
        return true
    }
    
    private func checkForAttachmentInRange(_ attributedString: NSAttributedString, range: NSRange) -> Bool {
        var hasAttachment = false
        attributedString.enumerateAttributes(in: range, options: []) { attributes, _, stop in
            if attributes[NSAttributedString.Key("associatedID")] != nil || 
               attributes[NSAttributedString.Key("linkUnderline")] != nil ||
               attributes[.link] != nil {
                hasAttachment = true
                stop.pointee = true
            }
        }
        return hasAttachment
    }
    
}


struct FormatToolbar: View {
    @Binding var attributedText: NSAttributedString
    let selectedRange: NSRange
    @Binding var currentStyle: TextStyle
    @Environment(\.dismiss) var dismiss
    let richTextEditor: RichTextEditor
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: 30) {
                    Button(action: { 
                        if selectedRange.length > 0 {
                            richTextEditor.toggleBold()
                        } else {
                            currentStyle.isBold.toggle()
                        }
                    }) {
                        Image(systemName: "bold")
                            .font(.system(size: 24))
                            .foregroundColor(currentStyle.isBold ? .blue : .primary)
                    }
                    
                    Button(action: { 
                        if selectedRange.length > 0 {
                            richTextEditor.toggleItalic()
                        } else {
                            currentStyle.isItalic.toggle()
                        }
                    }) {
                        Image(systemName: "italic")
                            .font(.system(size: 24))
                            .foregroundColor(currentStyle.isItalic ? .blue : .primary)
                    }
                    
                    Button(action: { 
                        if selectedRange.length > 0 {
                            richTextEditor.toggleUnderline()
                        } else {
                            currentStyle.isUnderlined.toggle()
                        }
                    }) {
                        Image(systemName: "underline")
                            .font(.system(size: 24))
                            .foregroundColor(currentStyle.isUnderlined ? .blue : .primary)
                    }
                    
                    Button(action: { 
                        if selectedRange.length > 0 {
                            richTextEditor.toggleStrikethrough()
                        } else {
                            currentStyle.isStrikethrough.toggle()
                        }
                    }) {
                        Image(systemName: "strikethrough")
                            .font(.system(size: 24))
                            .foregroundColor(currentStyle.isStrikethrough ? .blue : .primary)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                        Text("Format")
                            .font(.title2)
                            .fontWeight(.semibold)
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
    }
}

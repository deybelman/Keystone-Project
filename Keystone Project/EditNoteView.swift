import SwiftUI
import PhotosUI

struct NoteDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataController: DataController
    
    var note: NoteEntity?
    
    @State private var attributedContent = NSAttributedString(string: "")
    @State private var showingFormatting = false
    @State private var selectedRange = NSRange()
    @State private var currentStyle = TextStyle()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedTextRange: NSRange?  // Needed to make sure image is attributed to correct text, not the text highlighted when async image loading completes
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: note?.date ?? Date())
    }
    
    var body: some View {
        let richTextEditor = RichTextEditor(
            text: $attributedContent,
            selectedRange: $selectedRange,
            currentStyle: $currentStyle
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
                        PhotosPicker(selection: $selectedPhotoItem,
                                   matching: .images) {
                            Image(systemName: "photo.badge.plus")
                        }
                        
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
            .onChange(of: selectedPhotoItem) { oldValue, newItem in
                if let item = newItem {
                    let associatedID = UUID().uuidString
                    selectedTextRange = selectedRange
                    
                    let mutableAttributedContent = NSMutableAttributedString(attributedString: attributedContent)
                    // Add the associatedID first
                    mutableAttributedContent.addAttribute(NSAttributedString.Key("associatedID"), 
                                                        value: associatedID, 
                                                        range: selectedTextRange ?? selectedRange)
                    // Add the color separately
                    mutableAttributedContent.addAttribute(.foregroundColor, 
                                                        value: UIColor.orange, 
                                                        range: selectedTextRange ?? selectedRange)
                    attributedContent = mutableAttributedContent
                    
                    Task {
                        guard let data = try? await item.loadTransferable(type: Data.self),
                              let note = note else { return }
                        
                        // Get the selected text
                        let selectedText = attributedContent.attributedSubstring(
                            from: selectedTextRange ?? NSRange()
                        ).string
                        
                        // Add the image attachment
                        dataController.addImageAttachment(
                            for: note,
                            imageData: data,
                            associatedText: selectedText,
                            associatedID: associatedID
                        )
                        
                        selectedPhotoItem = nil
                    }
                }
            }
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

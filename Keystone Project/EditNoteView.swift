import SwiftUI

struct NoteDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataController: DataController
    
    var note: FetchedResults<NoteEntity>.Element?
    
    @State private var attributedContent = NSAttributedString(string: "")
    @State private var showingFormatting = false
    @State private var selectedRange = NSRange()
    @State private var currentStyle = TextStyle()
    
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
                    Button(action: {
                        showingFormatting.toggle()
                    }) {
                        Image(systemName: "textformat")
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
                Spacer()
            }
            .navigationTitle("Format")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

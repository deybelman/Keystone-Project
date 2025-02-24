import Foundation
import CoreData
import SwiftUI

class DataController: ObservableObject {
    // Core Data container
    let container = NSPersistentContainer(name: "NotesDatabase")
    
    // Published property to notify views of changes
    @Published var savedNotes: [NoteEntity] = []
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Failed to load data in DataController \(error.localizedDescription)")
            }
            self.fetchNotes()
        }
    }
    
    
    func fetchNotes() {
        let request = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
        
        do {
            savedNotes = try container.viewContext.fetch(request)
        } catch {
            print("Error fetching notes: \(error.localizedDescription)")
        }
    }
    
    func addNote(content: String) {
        let note = NoteEntity(context: container.viewContext)
        note.id = UUID()
        note.content = content
        note.date = Date()
        
        save()
    }
    
    func editNote(_ note: NoteEntity, newContent: String) {
        note.content = newContent
        save()
    }
    
    func deleteNote(_ note: NoteEntity) {
        container.viewContext.delete(note)
        save()
    }
    
    func deleteNote(at offsets: IndexSet) {
        for index in offsets {
            let note = savedNotes[index]
            container.viewContext.delete(note)
        }
        save()
    }
    
    func editNote(_ note: NoteEntity, newAttributedContent: NSAttributedString) {
        note.content = newAttributedContent.string
        note.attributedContent = try? newAttributedContent.data(
            from: NSRange(location: 0, length: newAttributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
        save()
    }
    
    func addNote(attributedContent: NSAttributedString) {
        let note = NoteEntity(context: container.viewContext)
        note.id = UUID()
        note.date = Date()
        note.content = attributedContent.string
        note.attributedContent = try? attributedContent.data(
            from: NSRange(location: 0, length: attributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
        save()
    }
    
    func save() {
        do {
            try container.viewContext.save()
            fetchNotes() // Refresh the notes after saving
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}

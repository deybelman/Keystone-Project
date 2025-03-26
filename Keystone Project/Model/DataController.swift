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
    
    func addImageAttachment(for note: NoteEntity, imageData: Data, associatedText: String, associatedID: String) {
            let attachment = ImageAttachmentEntity(context: container.viewContext)
            attachment.id = UUID()
            attachment.imageData = imageData
    
            save()
        }
    
        func fetchImageAttachment(for note: NoteEntity, withID associatedID: String) -> ImageAttachmentEntity? {
            guard let attachments = note.attachments?.allObjects as? [ImageAttachmentEntity] else {
                print("No attachments found for note")
                return nil
            }
    
            let matchingAttachment = attachments.first { attachment in
                attachment.associatedID == associatedID
            }
    
            if matchingAttachment != nil {
                print("Found attachment with ID: \(associatedID)")
            } else {
                print("No attachment found with ID: \(associatedID)")
            }
    
            return matchingAttachment
        }
    
    func createImageGroup(for note: NoteEntity, associatedID: String, associatedText: String) {
        let imageGroup = ImageGroupEntity(context: container.viewContext)
        imageGroup.id = UUID()
        imageGroup.associatedID = associatedID
        imageGroup.associatedText = associatedText
        imageGroup.toNote = note
        
        save()
    }
    
    func addImageToGroup(imageData: Data, group: ImageGroupEntity) {
        let attachment = ImageAttachmentEntity(context: container.viewContext)
        attachment.id = UUID()
        attachment.imageData = imageData
        attachment.group = group

        save()
    }

    func fetchImageGroup(for note: NoteEntity, associatedID: String) -> ImageGroupEntity? {
        let request = NSFetchRequest<ImageGroupEntity>(entityName: "ImageGroupEntity")
        request.predicate = NSPredicate(format: "toNote == %@ AND associatedID == %@", note, associatedID)
        request.fetchLimit = 1
        
        do {
            let results = try container.viewContext.fetch(request)
            return results.first
        } catch {
            print("Error fetching image group: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchImagesinGroup(_ imageGroup: ImageGroupEntity) -> [ImageAttachmentEntity] {
        let request = NSFetchRequest<ImageAttachmentEntity>(entityName: "ImageAttachmentEntity")
        request.predicate = NSPredicate(format: "group == %@", imageGroup)
        
        do {
            let results = try container.viewContext.fetch(request)
            return results
        } catch {
            print("Error fetching images in group: \(error.localizedDescription)")
            return []
        }
    }
}


    

import Foundation
import CoreData

extension DataController {
    // CRUD operations for image attachments
    func addImageAttachment(for note: NoteEntity, imageData: Data, associatedText: String, associatedID: String) {
        let attachment = ImageAttachmentEntity(context: container.viewContext)
        attachment.id = UUID()
        attachment.imageData = imageData
        attachment.attachedAt = Date()
        attachment.associatedText = associatedText
        attachment.associatedID = associatedID
        attachment.note = note
        
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
}

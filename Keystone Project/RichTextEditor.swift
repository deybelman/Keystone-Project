import SwiftUI
import UIKit

struct TextStyle {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderlined: Bool = false
    var isStrikethrough: Bool = false
    var hasImageAttachment: Bool = false
    var isLinkUnderlined: Bool = false
    
    func apply(to font: UIFont) -> UIFont {
        var traits = font.fontDescriptor.symbolicTraits
        if isBold {
            traits.insert(.traitBold)
        }
        if isItalic {
            traits.insert(.traitItalic)
        }
        if let newDescriptor = font.fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: newDescriptor, size: font.pointSize)
        }
        return font
    }
    
    static func current(for attributes: [NSAttributedString.Key: Any]) -> TextStyle {
        let font = attributes[.font] as? UIFont
        let traits = font?.fontDescriptor.symbolicTraits ?? []
        let underlineStyle = attributes[.underlineStyle] as? Int
        let strikethroughStyle = attributes[.strikethroughStyle] as? Int
        let hasAssociatedImageID = attributes[NSAttributedString.Key("associatedID")] != nil
        let isLinkUnderlined = attributes[NSAttributedString.Key("linkUnderline")] != nil
        
        return TextStyle(
            isBold: traits.contains(.traitBold),
            isItalic: traits.contains(.traitItalic),
            isUnderlined: underlineStyle != nil && !isLinkUnderlined,
            isStrikethrough: strikethroughStyle != nil,
            hasImageAttachment: hasAssociatedImageID,
            isLinkUnderlined: isLinkUnderlined
        )
    }
}

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: NSAttributedString
    @Binding var selectedRange: NSRange
    @Binding var currentStyle: TextStyle
    var onImageLinkTap: ((URL) -> Bool)?
    
    private let defaultFont = UIFont.systemFont(ofSize: 17)
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear
        textView.font = defaultFont
        textView.textColor = .label
        textView.delegate = context.coordinator
        textView.typingAttributes = defaultTypingAttributes()
        textView.linkTextAttributes = [:]
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = text
        uiView.selectedRange = selectedRange
        uiView.typingAttributes = defaultTypingAttributes()
    }
    
    private func defaultTypingAttributes() -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        
        // Apply font with bold/italic
        let font = currentStyle.apply(to: defaultFont)
        attributes[.font] = font
        
        // Set text color to automatically adapt to light/dark mode
        attributes[.foregroundColor] = UIColor.label
        
        // Apply underline if needed
        if currentStyle.isUnderlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        
        // Apply strikethrough if needed
        if currentStyle.isStrikethrough {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }

        return attributes
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func toggleBold() {
        guard selectedRange.length > 0 else { return }
        
        let mutable = NSMutableAttributedString(attributedString: text)
        let currentAttributes = mutable.attributes(at: selectedRange.location, effectiveRange: nil)
        
        var newStyle = TextStyle.current(for: currentAttributes)
        newStyle.isBold.toggle()
        
        let newFont = newStyle.apply(to: defaultFont)
        mutable.addAttribute(.font, value: newFont, range: selectedRange)
        
        text = mutable
        currentStyle = newStyle
    }
    
    func toggleItalic() {
        guard selectedRange.length > 0 else { return }
        
        let mutable = NSMutableAttributedString(attributedString: text)
        let currentAttributes = mutable.attributes(at: selectedRange.location, effectiveRange: nil)
        
        var newStyle = TextStyle.current(for: currentAttributes)
        newStyle.isItalic.toggle()
        
        let newFont = newStyle.apply(to: defaultFont)
        mutable.addAttribute(.font, value: newFont, range: selectedRange)
        
        text = mutable
        currentStyle = newStyle
    }
    
    func toggleUnderline() {
        guard selectedRange.length > 0 else { return }
        
        let mutable = NSMutableAttributedString(attributedString: text)
        let currentAttributes = mutable.attributes(at: selectedRange.location, effectiveRange: nil)
        
        // Check if this is a link underline - if so, don't toggle it
        if currentAttributes[NSAttributedString.Key("linkUnderline")] != nil {
            return
        }
        
        var newStyle = TextStyle.current(for: currentAttributes)
        newStyle.isUnderlined.toggle()
        
        // Preserve existing font
        let font = newStyle.apply(to: defaultFont)
        mutable.addAttribute(.font, value: font, range: selectedRange)
        
        // Toggle underline
        if newStyle.isUnderlined {
            mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        } else {
            mutable.removeAttribute(.underlineStyle, range: selectedRange)
        }
        
        text = mutable
        currentStyle = newStyle
    }
    
    func toggleStrikethrough() {
        guard selectedRange.length > 0 else { return }
        
        let mutable = NSMutableAttributedString(attributedString: text)
        let currentAttributes = mutable.attributes(at: selectedRange.location, effectiveRange: nil)
        
        var newStyle = TextStyle.current(for: currentAttributes)
        newStyle.isStrikethrough.toggle()
        
        // Preserve existing font
        let font = newStyle.apply(to: defaultFont)
        mutable.addAttribute(.font, value: font, range: selectedRange)
        
        // Toggle strikethrough
        if newStyle.isStrikethrough {
            mutable.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        } else {
            mutable.removeAttribute(.strikethroughStyle, range: selectedRange)
        }
        
        text = mutable
        currentStyle = newStyle
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
            
            if textView.selectedRange.length > 0 {
                let attributedText = textView.attributedText ?? NSAttributedString()
                let range = textView.selectedRange
                
                // Get style of first character in selection
                let attributes = attributedText.attributes(at: range.location, effectiveRange: nil)
                parent.currentStyle = TextStyle.current(for: attributes)
            } else if textView.selectedRange.location > 0 {
                let attributedText = textView.attributedText ?? NSAttributedString()
                let attributes = attributedText.attributes(at: max(textView.selectedRange.location - 1, 0), effectiveRange: nil)
                parent.currentStyle = TextStyle.current(for: attributes)
            }
        }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            print("Link tapped with URL: \(URL)")
            print("URL scheme: \(URL.scheme ?? "nil")")
            
            // If it's our custom image URL scheme, handle it ourselves
            if URL.scheme == "image" {
//                let associatedID = URL.host ?? ""
//                print("Image link tapped with ID: \(associatedID)")
                
                return parent.onImageLinkTap?(URL) ?? false
            }
            
            // For all other URLs, let the system handle them
            return true
        }
    }
} 

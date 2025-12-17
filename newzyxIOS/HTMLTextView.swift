//
//  HTMLTextView.swift
//  newzyxIOS
//
//  Helper view for rendering HTML content
//

import SwiftUI

struct HTMLTextView: View {
    let htmlString: String
    @State private var attributedString: AttributedString?
    
    var body: some View {
        if let attributedString = attributedString {
            Text(attributedString)
        } else {
            Text(htmlString)
                .onAppear {
                    Task {
                        attributedString = await convertHTMLToAttributedString(htmlString)
                    }
                }
        }
    }
    
    private func convertHTMLToAttributedString(_ html: String) async -> AttributedString? {
        // Add basic HTML structure and styling
        let styledHtml = """
        <html>
        <head>
            <style>
                body {
                    font-family: -apple-system, system-ui;
                    font-size: 17px;
                    line-height: 1.7;
                    color: #FFFFFF;
                }
                b, strong {
                    font-weight: 700;
                    color: #60a5fa;
                }
                a {
                    color: #22d3ee;
                    text-decoration: none;
                }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
        
        guard let data = styledHtml.data(using: .utf8) else {
            return nil
        }
        
        do {
            let nsAttributedString = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            
            return try AttributedString(nsAttributedString, including: \.uiKit)
        } catch {
            print("Error converting HTML: \(error)")
            return nil
        }
    }
}

#Preview {
    HTMLTextView(htmlString: "<B>Test Bold</B> and <a href='https://example.com'>Link</a>")
        .padding()
        .background(Color.black)
}


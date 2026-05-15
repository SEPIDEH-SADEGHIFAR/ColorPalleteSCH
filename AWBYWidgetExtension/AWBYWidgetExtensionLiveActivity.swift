//
//  AWBYWidgetExtensionLiveActivity.swift
//  AWBYWidgetExtension
//
//  Created by seyedeh sepideh sadeghi far on 15/05/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AWBYWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AWBYWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AWBYWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension AWBYWidgetExtensionAttributes {
    fileprivate static var preview: AWBYWidgetExtensionAttributes {
        AWBYWidgetExtensionAttributes(name: "World")
    }
}

extension AWBYWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: AWBYWidgetExtensionAttributes.ContentState {
        AWBYWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AWBYWidgetExtensionAttributes.ContentState {
         AWBYWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AWBYWidgetExtensionAttributes.preview) {
   AWBYWidgetExtensionLiveActivity()
} contentStates: {
    AWBYWidgetExtensionAttributes.ContentState.smiley
    AWBYWidgetExtensionAttributes.ContentState.starEyes
}

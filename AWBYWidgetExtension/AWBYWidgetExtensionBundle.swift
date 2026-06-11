//
//  AWBYWidgetExtensionBundle.swift
//  AWBYWidgetExtension
//
//  Created by seyedeh sepideh sadeghi far on 15/05/26.
//

import WidgetKit
import SwiftUI

@main
struct AWBYWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        PaletteWidget()
        AWBYWidgetExtensionControl()
        AWBYWidgetExtensionLiveActivity()
    }
}

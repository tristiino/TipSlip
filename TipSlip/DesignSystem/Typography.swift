//
//  Typography.swift
//  TipSlip
//
//  Created by Tristan Barnett on 5/13/26.
//

import Foundation
import SwiftUI

extension Font {
    enum TipSlipStyle {
        case display
        case title
        case heading
        case body
        case bodyEmphasis
        case footnote
        case caption
        case numericLarge
        case numericMedium
    }

    static func tipSlip(_ style: TipSlipStyle) -> Font {
        switch style {
        case .display:
            return .system(.largeTitle, design: .default).bold()
        case .title:
            return .system(.title2, design: .default).weight(.semibold)
        case .heading:
            return .system(.headline, design: .default).weight(.semibold)
        case .body:
            return .system(.body, design: .default)
        case .bodyEmphasis:
            return .system(.body, design: .default).weight(.semibold)
        case .footnote:
            return .system(.footnote, design: .default)
        case .caption:
            return .system(.caption, design: .default)
        case .numericLarge:
            return .system(.largeTitle, design: .rounded).bold().monospacedDigit()
        case .numericMedium:
            return .system(.title, design: .monospaced).weight(.semibold)
        }
    }
}

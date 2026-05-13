//
//  PlaceholderView.swift
//  TipSlip
//
//  Created by Tristan Barnett on 5/13/26.
//

import Foundation
import SwiftUI

struct PlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: Spacing.s16) {
                Text(title)
                    .font(.tipSlip(.title))
                    .foregroundStyle(Colors.textPrimary)

                Text("Coming in Phase 2")
                    .font(.tipSlip(.footnote))
                    .foregroundStyle(Colors.textSecondary)
            }
        }
    }
}

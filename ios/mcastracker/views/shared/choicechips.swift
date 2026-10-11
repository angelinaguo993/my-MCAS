import SwiftUI

/// Wrapping grid of tappable chips. It has its own file so no screen depends on
/// another screen's file (it used to live at the bottom of onboarding-view.swift).
struct ChoiceChips<Item: Hashable>: View {
    let items: [Item]
    let isSelected: (Item) -> Bool
    let label: (Item) -> String
    let onTap: (Item) -> Void

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    onTap(item)
                } label: {
                    Text(label(item))
                        .font(.nCaption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(isSelected(item) ? Theme.primary : Color.gray.opacity(0.12))
                        .foregroundColor(isSelected(item) ? .white : Theme.textPrimary)
                        .cornerRadius(10)
                }
            }
        }
    }
}

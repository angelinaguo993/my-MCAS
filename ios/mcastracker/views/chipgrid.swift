import SwiftUI

/// A robust, generic multi-select chip grid with explicit initializers
struct ChipGrid<T: Hashable>: View {
    let items: [T]
    @Binding var selectedItems: Set<T>
    let titleKeyPath: (T) -> String

    // MARK: - Initializer Overloads (No Optional Bindings)

    init(items: [T], selectedItems: Binding<Set<T>>, titleKeyPath: @escaping (T) -> String = { "\($0)" }) {
        self.items = items
        self._selectedItems = selectedItems
        self.titleKeyPath = titleKeyPath
    }

    init(titles: [T], selectedItems: Binding<Set<T>>, titleKeyPath: @escaping (T) -> String = { "\($0)" }) {
        self.items = titles
        self._selectedItems = selectedItems
        self.titleKeyPath = titleKeyPath
    }

    init(items: [T], selected: Binding<Set<T>>, titleKeyPath: @escaping (T) -> String = { "\($0)" }) {
        self.items = items
        self._selectedItems = selected
        self.titleKeyPath = titleKeyPath
    }

    init(titles: [T], selected: Binding<Set<T>>, titleKeyPath: @escaping (T) -> String = { "\($0)" }) {
        self.items = titles
        self._selectedItems = selected
        self.titleKeyPath = titleKeyPath
    }

    init(_ items: [T], _ selectedItems: Binding<Set<T>>, titleKeyPath: @escaping (T) -> String = { "\($0)" }) {
        self.items = items
        self._selectedItems = selectedItems
        self.titleKeyPath = titleKeyPath
    }

    // MARK: - View Body

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                let isSelected = selectedItems.contains(item)
                let displayText = titleKeyPath(item)
                
                Button {
                    if isSelected {
                        selectedItems.remove(item)
                    } else {
                        selectedItems.insert(item)
                    }
                } label: {
                    Text(displayText)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Theme.accent : Color.gray.opacity(0.15))
                        .foregroundColor(isSelected ? .white : Theme.textPrimary)
                        .cornerRadius(20)
                }
            }
        }
    }
}

//

import SwiftUI

extension View {
    func measureWidth(_ onChange: @escaping (CGFloat) -> ()) -> some View {
        background {
            GeometryReader { proxy in
                let width = proxy.size.width
                Color.clear
                    .onAppear {
                        onChange(width)
                    }.onChange(of: width) {
                        onChange($0)
                    }
            }
        }
    }
}

struct Marquee<Content: View>: View {
    var velocity: Double = 50
    var spacing: CGFloat = 10
    @ViewBuilder var content: Content
    @State private var previousTick = Date.now
    @State private var contentWidth: CGFloat? = nil
    @State private var containerWidth: CGFloat? = nil
    @State private var offset: CGFloat = 0

    func tick(at time: Date) {
        let delta = time.timeIntervalSince(previousTick)
        defer { previousTick = time }
        if let dragStartOffset {
            offset = dragStartOffset + dragTranslation
        } else {
            offset -= delta * velocity
        }
        if let c = contentWidth {
            offset.formTruncatingRemainder(dividingBy: c + spacing)
            while offset > 0 {
                offset -= c + spacing
            }

        }
    }

    var body: some View {
        TimelineView(.animation) { context in
            HStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    content
                }
                .measureWidth { contentWidth = $0 }
                let contentPlusSpacing = ((contentWidth ?? 0) + spacing)
                if contentPlusSpacing != 0 {
                    let numberOfInstances = Int(((containerWidth ?? 0) / contentPlusSpacing).rounded(.up))
                    ForEach(Array(0..<numberOfInstances), id: \.self) { _ in
                        content
                    }
                }
            }
            .offset(x: offset)
            .fixedSize()
            .onChange(of: context.date) { newDate in
                tick(at: newDate)
            }
        }
        .onAppear { previousTick = .now }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .overlay {
            Text("\(offset)")
                .font(.caption)
                .foregroundColor(.white)
                .background(Color.black)
        }
        .measureWidth { containerWidth = $0 }
        .gesture(dragGesture)
    }

    @State private var dragStartOffset: CGFloat? = nil
    @State private var dragTranslation: CGFloat = 0

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStartOffset == nil {
                    dragStartOffset = offset
                }
                dragTranslation = value.translation.width
            }.onEnded { value in
                offset = dragStartOffset! + value.translation.width
                dragStartOffset = nil
            }
    }
}

struct ContentView: View {
    @State var velocity: CGFloat = 50
    @State var numberOfItems: Double = 5
    var body: some View {
        VStack {
            Slider(value: $velocity, in: -300...300, label: { Text("Velocity") })
            Slider(value: $numberOfItems, in: 1...20, label: { Text("Number Of Items")})

            Marquee(velocity: velocity) {
                ForEach(Array(0..<(Int(numberOfItems))), id: \.self) { i in
                    Text("Item \(i)")
                        .padding()
                        .foregroundColor(.white)
                        .background {
                            Capsule()
                                .fill(.blue)
                        }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}

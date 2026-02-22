# Flip Transition

## Effect

The image rotates 180 degrees around its vertical axis, like flipping a card or photograph face-down and revealing a new one on the other side. The rotation is fully 3D — the image visually recedes at its center, exposing the back face as it swings through, then the new image lands face-up.

## Why This Transition

Flip is the most immediately recognizable transition in the set. It communicates "next item" without any ambiguity — the spatial metaphor is a stack of cards or prints being flipped through. For a picture viewer, this maps directly to the user's mental model: I have a pile of photos and I'm turning them over one by one.

It also serves as the baseline transition. Where curl, bend, and book all play on the "page" metaphor, flip is purely geometric. This variety prevents the slideshow from feeling monotonous when transitions cycle.

## Core Animation Implementation

Flip uses `oglFlip`, a private but long-stable `CATransitionType` that delegates the entire 3D rotation to the GPU render server. The "ogl" prefix refers to OpenGL (now Metal under the hood), meaning the perspective projection, lighting, and back-face rendering all happen in the compositor process — not on the app's main thread.

```swift
let transition = CATransition()
transition.type = CATransitionType(rawValue: "oglFlip")
transition.subtype = .fromRight
transition.duration = DesignSystem.flipDuration  // 1.0s
transition.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
imageLayer.add(transition, forKey: "slideTransition")
```

### Why `oglFlip` instead of SwiftUI `.rotation3DEffect`

SwiftUI's `.rotation3DEffect` animates a `CATransform3D` on the view's layer, which works but has two problems:

1. **No back-face rendering**. SwiftUI doesn't natively show a second view on the back face mid-rotation. You'd need to swap views at the 90-degree midpoint using an `AnimatableModifier` or geometry effect, which is fragile and timing-sensitive.
2. **Main-thread composition**. SwiftUI animations run through the SwiftUI render loop, which schedules on the main thread. During complex view updates (e.g., preloading the next image), this can cause dropped frames.

`oglFlip` handles both: it composites the old and new layer contents as front/back faces of a single 3D surface, and it runs entirely on the render server.

### Subtype and Direction

The transition always uses `.fromRight`, meaning the right edge lifts toward the viewer and swings left. This matches the natural reading direction (left-to-right), reinforcing "forward progress" through the slideshow. The direction doesn't change for backward navigation — flip is a symmetric effect, so reversing the subtype would feel arbitrary rather than meaningful (unlike `book`, where direction matters).

### Timing

Duration is 1.0s at normal speed, 0.5s in speedy mode. The ease curve `(0.25, 0.1, 0.25, 1.0)` is a slightly modified ease-out that starts with a gentle push and decelerates smoothly. This avoids the mechanical feel of linear timing while keeping the flip from feeling sluggish.

## Layer Sizing

The transition is applied to `imageLayer`, which is sized to the aspect-fitted rect (`fittedImageRect`) rather than the full container bounds. This ensures the 3D flip rotation happens around the visible image's center — not the center of a larger invisible rectangle, which would make the image appear to orbit an off-center axis.

## File References

- Transition type selection: `SlideshowImageView.swift:128`
- Duration constant: `DesignSystem.swift:109`
- Layer frame sizing: `SlideshowImageView.swift:86-89`

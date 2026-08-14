//
//  AzFluxEditorTests.swift
//  AzFluxEditorTests
//
//  Created by Eduardo Fabio Ayaviri Zuna on 10/08/2026.
//

import CoreGraphics
import Foundation
import Testing
@testable import AzFluxEditor

// MARK: - Common helpers

private func makeImage(width: Int = 4, height: Int = 2) -> CGImage {
    let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    return context.makeImage()!
}

// MARK: - CoordinateSystem


@MainActor
struct CoordinateSystemTests {

    @Test func imageToScreenRoundTrips() {
        let coordinateSystem = CoordinateSystem(
            viewportSize: CGSize(width: 800, height: 600),
            camera: Camera(zoom: 2, offset: CGPoint(x: 100, y: 50))
        )
        let point = CGPoint(x: 123, y: 45)
        let back = coordinateSystem.screenToImage(coordinateSystem.imageToScreen(point))
        #expect(abs(back.x - point.x) < 1e-9)
        #expect(abs(back.y - point.y) < 1e-9)
    }

    @Test func zoomKeepsAnchorPointFixedInImageSpace() {
        var coordinateSystem = CoordinateSystem(
            viewportSize: CGSize(width: 800, height: 600),
            camera: .identity
        )
        let anchor = CGPoint(x: 300, y: 200)
        let before = coordinateSystem.screenToImage(anchor)
        coordinateSystem.zoom(by: 2, anchoredAt: anchor)
        let after = coordinateSystem.screenToImage(anchor)
        #expect(abs(before.x - after.x) < 1e-6)
        #expect(abs(before.y - after.y) < 1e-6)
        #expect(abs(coordinateSystem.camera.zoom - 2) < 1e-9)
    }

    @Test func zoomIsClamped() {
        var coordinateSystem = CoordinateSystem(
            viewportSize: CGSize(width: 800, height: 600),
            camera: .identity
        )
        coordinateSystem.zoom(by: 100_000, anchoredAt: .zero)
        #expect(coordinateSystem.camera.zoom <= Camera.maximumZoom)

        coordinateSystem.camera.zoom = Camera.minimumZoom
        coordinateSystem.zoom(by: 0.0001, anchoredAt: .zero)
        #expect(coordinateSystem.camera.zoom >= Camera.minimumZoom)
    }

    @Test func fitCentersAndNeverUpscales() {
        var coordinateSystem = CoordinateSystem(
            viewportSize: CGSize(width: 800, height: 600),
            camera: .identity
        )
        coordinateSystem.fit(imageSize: CGSize(width: 200, height: 300))

        #expect(abs(coordinateSystem.camera.zoom - 1) < 1e-9)
        #expect(abs(coordinateSystem.camera.offset.x - 300) < 1e-9)
        #expect(abs(coordinateSystem.camera.offset.y - 150) < 1e-9)
    }
}

// MARK: - LayerTransform


@MainActor
struct LayerTransformTests {

    @Test func identityMapsCornersUnchanged() {
        let size = CGSize(width: 100, height: 50)
        let affine = LayerTransform.identity.affineTransform(size: size)
        let moved = CGPoint(x: 0, y: 0).applying(affine)
        let corner = CGPoint(x: 100, y: 50).applying(affine)
        #expect(abs(moved.x - 0) < 1e-9 && abs(moved.y - 0) < 1e-9)
        #expect(abs(corner.x - 100) < 1e-9 && abs(corner.y - 50) < 1e-9)
    }

    @Test func translationShiftsTheOrigin() {
        let size = CGSize(width: 100, height: 50)
        var transform = LayerTransform.identity
        transform.translation = CGPoint(x: 10, y: -5)
        let moved = CGPoint(x: 0, y: 0).applying(transform.affineTransform(size: size))
        #expect(abs(moved.x - 10) < 1e-9)
        #expect(abs(moved.y - (-5)) < 1e-9)
    }
}

// MARK: - LayerStack


@MainActor
struct LayerStackTests {

    private func layer(_ name: String) -> Layer {
        Layer(name: name)
    }

    @Test func addKeepsBottomToTopOrder() {
        var stack = LayerStack()
        let a = layer("a")
        let b = layer("b")
        let c = layer("c")
        stack.add(a)
        stack.add(b)
        stack.add(c)
        #expect(stack.layersFromBottom.map(\.name) == ["a", "b", "c"])
        #expect(stack.layersFromTop.map(\.name) == ["c", "b", "a"])
    }

    @Test func addMakesLayerActive() {
        var stack = LayerStack()
        let a = layer("a")
        stack.add(a)
        #expect(stack.activeLayerID == a.id)
    }

    @Test func removingActiveFallsBackToLastLayer() {
        var stack = LayerStack()
        let a = layer("a")
        let b = layer("b")
        stack.add(a)
        stack.add(b)
        stack.remove(id: b.id)
        #expect(stack.activeLayerID == a.id)
    }

    @Test func updateMutatesLayerInPlace() {
        var stack = LayerStack()
        let a = layer("a")
        stack.add(a)
        stack.update(id: a.id) { $0.opacity = 0.5 }
        #expect(stack.layer(id: a.id)?.opacity == 0.5)
    }

    @Test func moveReorders() {
        var stack = LayerStack()
        let a = layer("a")
        let b = layer("b")
        let c = layer("c")
        stack.add(a)
        stack.add(b)
        stack.add(c)
        stack.move(id: c.id, to: 0)
        #expect(stack.layersFromBottom.map(\.name) == ["c", "a", "b"])
    }

    @Test func applyOrderFromTopReordersAndKeepsActive() {
        var stack = LayerStack()
        let a = layer("a")
        let b = layer("b")
        let c = layer("c")
        stack.add(a)
        stack.add(b)
        stack.add(c)
        stack.select(id: b.id)
        stack.applyOrderFromTop([c, a, b])
        #expect(stack.layersFromTop.map(\.name) == ["c", "a", "b"])
        #expect(stack.activeLayerID == b.id)
    }

    @Test func applyOrderFromTopIgnoresForeignLayers() {
        var stack = LayerStack()
        let a = layer("a")
        stack.add(a)
        stack.applyOrderFromTop([layer("x")])
        #expect(stack.layersFromBottom.map(\.name) == ["a"])
    }
}

// MARK: - EditorDocument

@MainActor

struct EditorDocumentTests {

    @Test func documentFromImageSetsCanvasAndLayer() {
        let image = makeImage(width: 4, height: 2)
        let document = EditorDocument(image: image, name: "foto")
        #expect(document.canvasSize == CGSize(width: 4, height: 2))
        #expect(document.layerStack.count == 1)
        #expect(document.layerStack.activeLayer?.image != nil)
    }
}

// MARK: - HistoryManager

@MainActor

struct HistoryManagerTests {

    @Test func registerUndoesAndRedoes() {
        let history = HistoryManager()
        let callbacks = ActorRef()
        history.register(name: "test", before: 1, after: 2) { value in
            callbacks.apply(value)
        }
        #expect(history.canUndo)

        history.undo()
        #expect(callbacks.value == 1)

        history.redo()
        #expect(callbacks.value == 2)

        history.undo()
        #expect(callbacks.value == 1)
    }
}

// MARK: - EditorState (undoable layer ops)

@MainActor
struct EditorStateHistoryTests {

    @Test func opacityChangeIsUndoableAndRedoable() {
        let editor = EditorState()
        let layer = Layer(name: "capa")
        editor.addLayer(layer)

        editor.setLayerOpacity(layer.id, opacity: 0.4)
        #expect(editor.document.layerStack.layer(id: layer.id)?.opacity == 0.4)

        editor.undo()
        #expect(editor.document.layerStack.layer(id: layer.id)?.opacity == 1)

        editor.redo()
        #expect(editor.document.layerStack.layer(id: layer.id)?.opacity == 0.4)
    }

    @Test func reorderIsUndoable() {
        let editor = EditorState()
        let a = Layer(name: "a")
        let b = Layer(name: "b")
        let c = Layer(name: "c")
        editor.addLayer(a)
        editor.addLayer(b)
        editor.addLayer(c)

        // top order is [c, b, a]; move "c" to the end -> top order [b, a, c]
        editor.moveLayer(from: IndexSet(integer: 0), to: 3)
        #expect(editor.document.layerStack.layersFromTop.map(\.name) == ["b", "a", "c"])

        editor.undo()
        #expect(editor.document.layerStack.layersFromTop.map(\.name) == ["c", "b", "a"])
    }
}

// MARK: - Mask

@MainActor
struct MaskTests {

    @Test func paintCreatesContentAndAccumulates() {
        var mask = Mask.empty(size: CGSize(width: 32, height: 32))
        let brush = BrushSettings(radius: 6, hardness: 0.8, opacity: 1)

        mask.paint(center: CGPoint(x: 16, y: 16), brush: brush)
        #expect(mask.hasContent)

        let first = mask.byte(x: 16, y: 16)
        mask.paint(center: CGPoint(x: 16, y: 16), brush: brush)
        let second = mask.byte(x: 16, y: 16)
        #expect(second >= first)
    }

    @Test func paintIsClippedToMaskBounds() {
        var mask = Mask.empty(size: CGSize(width: 16, height: 16))
        let brush = BrushSettings(radius: 6, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: -5, y: -5), brush: brush)
        #expect(!mask.hasContent)
        mask.paint(center: CGPoint(x: 100, y: 100), brush: brush)
        #expect(!mask.hasContent)
    }

    @Test func eraseLowersPaintedArea() {
        var mask = Mask.empty(size: CGSize(width: 32, height: 32))
        let brush = BrushSettings(radius: 6, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: 16, y: 16), brush: brush)
        let painted = mask.byte(x: 16, y: 16)
        #expect(painted == 255)

        mask.erase(center: CGPoint(x: 16, y: 16), brush: brush)
        #expect(mask.byte(x: 16, y: 16) == 0)
    }

    @Test func invertFlipsEveryPixelAndIsInvolutive() {
        var mask = Mask.empty(size: CGSize(width: 32, height: 32))
        let brush = BrushSettings(radius: 6, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: 16, y: 16), brush: brush)
        let originalPainted = mask.byte(x: 16, y: 16)
        let originalUnpainted = mask.byte(x: 2, y: 2)
        #expect(originalPainted == 255 && originalUnpainted == 0)

        let before = mask
        mask.invert()
        #expect(mask.byte(x: 16, y: 16) == 255 - originalPainted)
        #expect(mask.byte(x: 2, y: 2) == 255)

        mask.invert()
        #expect(mask == before)
    }

    @Test func clearEmptiesMask() {
        var mask = Mask.empty(size: CGSize(width: 32, height: 32))
        let brush = BrushSettings(radius: 6, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: 16, y: 16), brush: brush)
        #expect(mask.hasContent)

        mask.clear()
        #expect(!mask.hasContent)
        #expect(mask.byte(x: 16, y: 16) == 0)
    }

    @Test func mutationsBumpRevision() {
        var mask = Mask.empty(size: CGSize(width: 8, height: 8))
        let brush = BrushSettings(radius: 2, hardness: 1, opacity: 1)
        let original = mask.revision
        mask.paint(center: CGPoint(x: 4, y: 4), brush: brush)
        #expect(mask.revision > original)
    }

    @Test func boundingRectFitsPaintedPixels() {
        var mask = Mask.empty(size: CGSize(width: 32, height: 32))
        #expect(mask.boundingRect == nil)

        let brush = BrushSettings(radius: 3, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: 10, y: 12), brush: brush)
        let rect = mask.boundingRect
        #expect(rect != nil)
        if let rect {
            #expect(rect.contains(CGPoint(x: 10, y: 12)))
            #expect(rect.minX >= 0 && rect.minY >= 0)
            #expect(rect.maxX <= 32 && rect.maxY <= 32)
        }
    }

    @Test func grayscaleRoundTripPreservesBytes() {
        var mask = Mask.empty(size: CGSize(width: 4, height: 3))
        let brush = BrushSettings(radius: 2, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: 2, y: 1), brush: brush)

        guard let image = mask.grayscaleImage(), let back = Mask(grayscale: image) else {
            Issue.record("grayscale round trip failed")
            return
        }
        #expect(back == mask)
    }

    @Test func overlayImageEncodesOpaqueAsRed() {
        var mask = Mask.empty(size: CGSize(width: 4, height: 2))
        let brush = BrushSettings(radius: 1, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: 0, y: 0), brush: brush)

        let image = mask.overlayImage()
        #expect(image != nil)
        #expect(image?.width == 4)
        #expect(image?.height == 2)

        guard
            let image,
            let data = image.dataProvider?.data as Data?,
            data.count >= 4 * 2 * 4
        else {
            Issue.record("overlay image data unavailable")
            return
        }
        // Pixel (0,0) is fully opaque red.
        data.withUnsafeBytes { buffer in
            let bytes = [UInt8](buffer)
            #expect(bytes[0] == 255)
            #expect(bytes[1] == 0)
            #expect(bytes[2] == 0)
            #expect(bytes[3] == 255)
        }
    }
@Test func grayscaleImageMatchesMaskBytes() {
        var mask = Mask.empty(size: CGSize(width: 3, height: 2))
        let brush = BrushSettings(radius: 1, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: 1, y: 0), brush: brush)
        mask.invert()

        let image = mask.grayscaleImage()
        #expect(image != nil)
        #expect(image?.width == 3)
        #expect(image?.height == 2)
        #expect(image?.bitsPerPixel == 8)

        guard
            let image,
            let data = image.dataProvider?.data as Data?,
            data.count == 3 * 2
        else {
            Issue.record("grayscale image data unavailable")
            return
        }
        // The engine input is a straight copy of the mask bytes.
        data.withUnsafeBytes { buffer in
            let bytes = [UInt8](buffer)
            for y in 0..<2 {
                for x in 0..<3 {
                    #expect(bytes[y * 3 + x] == mask.byte(x: x, y: y))
                }
            }
        }
    }
}

// MARK: - MaskCrop

@MainActor
struct MaskCropTests {

    private func solidImage(_ color: CGColor, width: Int, height: Int) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    @Test func cropRectUsesMaskContent() {
        var mask = Mask.empty(size: CGSize(width: 64, height: 64))
        let brush = BrushSettings(radius: 2, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: 30, y: 40), brush: brush)

        let rect = MaskCrop.cropRect(mask: mask, canvasSize: CGSize(width: 64, height: 64))
        #expect(rect != nil)
        if let rect {
            #expect(rect.contains(CGPoint(x: 30, y: 40)))
            #expect(rect.minX >= 0 && rect.minY >= 0)
            #expect(rect.maxX <= 64 && rect.maxY <= 64)
            #expect(Int(rect.minX) % MaskCrop.alignment == 0)
            #expect(Int(rect.minY) % MaskCrop.alignment == 0)
        }
    }

    @Test func cropRectIsNilForEmptyMask() {
        let mask = Mask.empty(size: CGSize(width: 64, height: 64))
        #expect(MaskCrop.cropRect(mask: mask, canvasSize: CGSize(width: 64, height: 64)) == nil)
    }

    @Test func cropReturnsSubimage() {
        let source = solidImage(CGColor(gray: 0.5, alpha: 1), width: 32, height: 32)
        let rect = CGRect(x: 8, y: 8, width: 16, height: 16)
        let cropped = MaskCrop.crop(source, to: rect)
        #expect(cropped?.width == 16)
        #expect(cropped?.height == 16)
    }

    @Test func composeKeepsOriginalOutsideMask() {
        let original = solidImage(CGColor(gray: 0.1, alpha: 1), width: 64, height: 64)
        let patch = solidImage(CGColor(red: 1, green: 0, blue: 0, alpha: 1), width: 64, height: 64)

        var mask = Mask.empty(size: CGSize(width: 64, height: 64))
        let brush = BrushSettings(radius: 2, hardness: 1, opacity: 1)
        mask.paint(center: CGPoint(x: 32, y: 32), brush: brush)
        guard let rect = MaskCrop.cropRect(mask: mask, canvasSize: CGSize(width: 64, height: 64)) else {
            Issue.record("no crop rect")
            return
        }

        guard let result = MaskCrop.compose(original: original, patch: patch, rect: rect, mask: mask) else {
            Issue.record("compose failed")
            return
        }
        guard let resultData = result.dataProvider?.data as Data? else {
            Issue.record("no result data")
            return
        }

        // Pixel at mask center must come from the red patch.
        resultData.withUnsafeBytes { buffer in
            let bytes = [UInt8](buffer)
            func pixel(_ x: Int, _ y: Int) -> (r: UInt8, g: UInt8, b: UInt8) {
                let i = (y * result.width + x) * 4
                return (bytes[i], bytes[i + 1], bytes[i + 2])
            }
            let center = pixel(32, 32)
            #expect(center.r > 200 && center.g < 60)
            // Far corner outside the mask stays original (dark gray).
            let corner = pixel(4, 4)
            #expect(corner.r < 100)
        }
    }
}

// MARK: - EditorState mask strokes

@MainActor
struct EditorStateMaskTests {

    @Test func maskStrokeRegistersSingleHistoryOperation() {
        let editor = EditorState()
        let layer = Layer(name: "capa")
        editor.addLayer(layer)
        editor.tool = .brush
        editor.brush = BrushSettings(radius: 6, hardness: 1, opacity: 1)

        editor.beginMaskStroke(at: CGPoint(x: 0, y: 0))
        editor.updateMaskStroke(to: CGPoint(x: 6, y: 6))
        editor.endMaskStroke()

        let painted = editor.document.layerStack.activeLayer?.mask
        #expect(painted != nil)
        #expect(painted?.hasContent == true)

        // Undo reverts the whole stroke in one step, restoring the
        // pre-stroke state where the layer had no mask.
        editor.undo()
        #expect(editor.document.layerStack.activeLayer?.mask == nil)

        // And redo restores it.
        editor.redo()
        #expect(editor.document.layerStack.activeLayer?.mask?.hasContent == true)
    }

    @Test func panToolDoesNotPaintMask() {
        let editor = EditorState()
        let layer = Layer(name: "capa")
        editor.addLayer(layer)
        editor.brush = BrushSettings(radius: 6, hardness: 1, opacity: 1)

        editor.tool = .pan
        editor.beginMaskStroke(at: CGPoint(x: 0, y: 0))
        editor.updateMaskStroke(to: CGPoint(x: 6, y: 6))
        editor.endMaskStroke()
        #expect(editor.document.layerStack.activeLayer?.mask == nil)
        // The pan stroke must not register a history operation: undo
        // only reverts the layer addition, leaving the stack empty.
        editor.undo()
        #expect(editor.document.layerStack.layers.isEmpty)
    }

    @Test func eraseToolBuildsAMask() {
        let editor = EditorState()
        let layer = Layer(name: "capa")
        editor.addLayer(layer)
        editor.brush = BrushSettings(radius: 6, hardness: 1, opacity: 0.4)

        editor.tool = .erase
        editor.beginMaskStroke(at: CGPoint(x: 0, y: 0))
        editor.updateMaskStroke(to: CGPoint(x: 4, y: 4))
        editor.endMaskStroke()

        let mask = editor.document.layerStack.activeLayer?.mask
        #expect(mask != nil)
        #expect(mask?.hasContent == false)  // erasing on empty mask keeps it empty
    }

    @Test func invertAndClearAreUndoable() {
        let editor = EditorState()
        let layer = Layer(name: "capa")
        editor.addLayer(layer)
        editor.tool = .brush
        editor.brush = BrushSettings(radius: 10, hardness: 1, opacity: 1)
        editor.beginMaskStroke(at: CGPoint(x: 0, y: 0))
        editor.endMaskStroke()
        #expect(editor.document.layerStack.activeLayer?.mask?.hasContent == true)

        editor.invertActiveMask()
        let cleared = editor.document.layerStack.activeLayer?.mask
        #expect(cleared?.byte(x: 30, y: 30) == 255)  // inverted area is opaque
        editor.undo()
        #expect(editor.document.layerStack.activeLayer?.mask?.byte(x: 30, y: 30) == 0)
    }
}

@MainActor
private final class ActorRef {
    var value: Int = 0
    func apply(_ newValue: Int) {
        value = newValue
    }
}
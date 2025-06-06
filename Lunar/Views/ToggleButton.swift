//
//  ToggleButton.swift
//  Lunar
//
//  Created by Alin on 23/12/2017.
//  Copyright © 2017 Alin. All rights reserved.
//

import Cocoa
import Defaults
import SwiftyAttributes

// MARK: - HoverState

enum HoverState: Int {
    case hover
    case noHover
}

// MARK: - Page

enum Page: Int {
    case hotkeys = 0
    case settings
    case display
    case hotkeysReset
    case settingsReset
    case displayReset
    case displayBrightnessRange
    case displayAlgorithm
    case quickMenu
    case quickMenuReset
}

// MARK: - ToggleButton

class ToggleButton: NSButton {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override var isEnabled: Bool {
        didSet { fade() }
    }

    var hoverState = HoverState.noHover
    weak var notice: NSTextField?
    lazy var highlighterKey = "highlighter-\(accessibilityIdentifier())"

    lazy var initialHeight = frame.height

    var highligherTask: Repeater?

    var highlighting: Bool { highligherTask != nil }
    @IBInspectable dynamic var verticalPadding: CGFloat = 10 {
        didSet {
            setFrameSize(NSSize(width: frame.width, height: initialHeight + verticalPadding))
            radius = circle ? (frame.height / 2).ns : roundedness.ns
            trackHover(cursor: true)
        }
    }

    @IBInspectable dynamic var circle = true {
        didSet {
            setFrameSize(NSSize(width: frame.width, height: initialHeight + verticalPadding))
            radius = circle ? (frame.height / 2).ns : roundedness.ns
            trackHover(cursor: true)
        }
    }

    @IBInspectable dynamic var roundedness: CGFloat = 4 {
        didSet {
            setFrameSize(NSSize(width: frame.width, height: initialHeight + verticalPadding))
            radius = circle ? (frame.height / 2).ns : roundedness.ns
            trackHover(cursor: true)
        }
    }

    var page: Page {
        get { Page(rawValue: pageType)! }
        set { pageType = newValue.rawValue }
    }

    @IBInspectable dynamic var pageType = Page.display.rawValue {
        didSet {
            setColors()
        }
    }

    var bgColor: NSColor {
        if !isEnabled {
            if highlighting { stopHighlighting() }
            return (offStateButtonColor[hoverState]![page] ?? offStateButtonColor[hoverState]![.display]!)
                .with(saturation: -0.2, brightness: -0.1)
        } else if state == .on {
            return onStateButtonColor[hoverState]![page] ?? onStateButtonColor[hoverState]![.display]!
        } else {
            return offStateButtonColor[hoverState]![page] ?? offStateButtonColor[hoverState]![.display]!
        }
    }

    var labelColor: NSColor {
        if !isEnabled {
            (offStateButtonLabelColor[hoverState]![page] ?? offStateButtonLabelColor[hoverState]![.display]!)
                .highlight(withLevel: 0.3)!.with(alpha: -0.4)
        } else if state == .on {
            onStateButtonLabelColor[hoverState]![page] ?? offStateButtonLabelColor[hoverState]![.display]!
        } else {
            offStateButtonLabelColor[hoverState]![page] ?? offStateButtonLabelColor[hoverState]![.display]!
        }
    }

    override func mouseEntered(with _: NSEvent) {
        if isEnabled {
            hover()
        } else if highlighting {
            stopHighlighting()
        }
    }

    override func mouseExited(with _: NSEvent) {
        defocus()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func cursorUpdate(with _: NSEvent) {
        if isEnabled {
            NSCursor.pointingHand.set()
        }
    }

    func highlight() {
        mainAsync { [weak self] in
            guard let self, !self.isHidden, window?.isVisible ?? false, highligherTask == nil
            else { return }

            highligherTask = Repeater(
                every: 5,
                name: highlighterKey
            ) { [weak self] in
                guard let self else { return }

                guard window?.isVisible ?? false, let notice
                else {
                    highligherTask = nil
                    return
                }

                if notice.alphaValue <= 0.02 {
                    notice.transition(1)
                    notice.alphaValue = 0.9
                    notice.needsDisplay = true

                    hover(fadeDuration: 1)
                    needsDisplay = true
                } else {
                    notice.transition(3)
                    notice.alphaValue = 0.01
                    notice.needsDisplay = true

                    defocus(fadeDuration: 3)
                    needsDisplay = true
                }
            }
        }
    }

    func stopHighlighting() {
        mainAsync { [weak self] in
            guard let self else { return }
            highligherTask = nil

            if let notice {
                notice.transition(0.3)
                notice.alphaValue = 0.0
                notice.needsDisplay = true
            }

            defocus(fadeDuration: 0.3)
            needsDisplay = true
        }
    }

    func setColors(fadeDuration: TimeInterval = 0.2) {
        layer?.add(fadeTransition(duration: fadeDuration), forKey: "transition")
        bg = bgColor
        attributedTitle = attributedTitle.string.withAttribute(.textColor(labelColor))
        attributedAlternateTitle = attributedAlternateTitle.string.withAttribute(.textColor(labelColor))
    }

    func fade() {
        setColors()
    }

    func defocus(fadeDuration: TimeInterval = 0.2) {
        hoverState = .noHover
        setColors(fadeDuration: fadeDuration)
    }

    func hover(fadeDuration: TimeInterval = 0.1) {
        hoverState = .hover
        setColors(fadeDuration: fadeDuration)
    }

    func setup() {
        wantsLayer = true

        setFrameSize(NSSize(width: frame.width, height: initialHeight + verticalPadding))
        radius = circle ? (frame.height / 2).ns : roundedness.ns
        allowsMixedState = false
        setColors()

        trackHover(cursor: true)
    }

}

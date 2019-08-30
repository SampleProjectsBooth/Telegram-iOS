import Foundation
import UIKit
import AsyncDisplayKit
import SwiftSignalKit

public let displayLinkDispatcher = DisplayLinkDispatcher()
private let dispatcher = displayLinkDispatcher

public enum ImageCorner: Equatable {
    case Corner(CGFloat)
    case Tail(CGFloat, Bool)
    
    public var extendedInsets: CGSize {
        switch self {
            case .Tail:
                return CGSize(width: 3.0, height: 0.0)
            default:
                return CGSize()
        }
    }
    
    public var withoutTail: ImageCorner {
        switch self {
            case .Corner:
                return self
            case let .Tail(radius, _):
                return .Corner(radius)
        }
    }
    
    public var radius: CGFloat {
        switch self {
            case let .Corner(radius):
                return radius
            case let .Tail(radius, _):
                return radius
        }
    }
    
    public func scaledBy(_ scale: CGFloat) -> ImageCorner {
        switch self {
            case let .Corner(radius):
                return .Corner(radius * scale)
            case let .Tail(radius, enabled):
                return .Tail(radius * scale, enabled)
        }
    }
}

public func ==(lhs: ImageCorner, rhs: ImageCorner) -> Bool {
    switch lhs {
        case let .Corner(lhsRadius):
            switch rhs {
                case let .Corner(rhsRadius) where abs(lhsRadius - rhsRadius) < CGFloat.ulpOfOne:
                    return true
                default:
                    return false
            }
        case let .Tail(lhsRadius, lhsEnabled):
            if case let .Tail(rhsRadius, rhsEnabled) = rhs, lhsRadius.isEqual(to: rhsRadius), lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
    }
}

public func isRoundEqualCorners(_ corners: ImageCorners) -> Bool {
    if case .Corner = corners.topLeft, case .Corner = corners.topRight, case .Corner = corners.bottomLeft, case .Corner = corners.bottomRight {
        if corners.topLeft.radius == corners.topRight.radius && corners.topRight.radius == corners.bottomLeft.radius && corners.bottomLeft.radius == corners.bottomRight.radius {
            return true
        }
    }
    return false
}

public struct ImageCorners: Equatable {
    public let topLeft: ImageCorner
    public let topRight: ImageCorner
    public let bottomLeft: ImageCorner
    public let bottomRight: ImageCorner
    
    public var isEmpty: Bool {
        if self.topLeft != .Corner(0.0) {
            return false
        }
        if self.topRight != .Corner(0.0) {
            return false
        }
        if self.bottomLeft != .Corner(0.0) {
            return false
        }
        if self.bottomRight != .Corner(0.0) {
            return false
        }
        return true
    }
    
    public init(radius: CGFloat) {
        self.topLeft = .Corner(radius)
        self.topRight = .Corner(radius)
        self.bottomLeft = .Corner(radius)
        self.bottomRight = .Corner(radius)
    }
    
    public init(topLeft: ImageCorner, topRight: ImageCorner, bottomLeft: ImageCorner, bottomRight: ImageCorner) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }
    
    public init() {
        self.init(topLeft: .Corner(0.0), topRight: .Corner(0.0), bottomLeft: .Corner(0.0), bottomRight: .Corner(0.0))
    }
    
    public var extendedEdges: UIEdgeInsets {
        let left = self.bottomLeft.extendedInsets.width
        let right = self.bottomRight.extendedInsets.width
        
        return UIEdgeInsets(top: 0.0, left: left, bottom: 0.0, right: right)
    }
    
    public func withRemovedTails() -> ImageCorners {
        return ImageCorners(topLeft: self.topLeft.withoutTail, topRight: self.topRight.withoutTail, bottomLeft: self.bottomLeft.withoutTail, bottomRight: self.bottomRight.withoutTail)
    }
    
    public func scaledBy(_ scale: CGFloat) -> ImageCorners {
        return ImageCorners(topLeft: self.topLeft.scaledBy(scale), topRight: self.topRight.scaledBy(scale), bottomLeft: self.bottomLeft.scaledBy(scale), bottomRight: self.bottomRight.scaledBy(scale))
    }
}

public func ==(lhs: ImageCorners, rhs: ImageCorners) -> Bool {
    return lhs.topLeft == rhs.topLeft && lhs.topRight == rhs.topRight && lhs.bottomLeft == rhs.bottomLeft && lhs.bottomRight == rhs.bottomRight
}

public class ImageNode: ASDisplayNode {
    private var disposable = MetaDisposable()
    private let hasImage: ValuePromise<Bool>?
    private var first = true
    private let enableEmpty: Bool
    
    public var ready: Signal<Bool, NoError> {
        if let hasImage = self.hasImage {
            return hasImage.get()
        } else {
            return .single(true)
        }
    }
    
    public init(enableHasImage: Bool = false, enableEmpty: Bool = false) {
        if enableHasImage {
            self.hasImage = ValuePromise(false, ignoreRepeated: true)
        } else {
            self.hasImage = nil
        }
        self.enableEmpty = enableEmpty
        super.init()
    }
    
    deinit {
        self.disposable.dispose()
    }
    
    public func setSignal(_ signal: Signal<UIImage?, NoError>) {
        var reportedHasImage = false
        self.disposable.set((signal |> deliverOnMainQueue).start(next: {[weak self] next in
            dispatcher.dispatch {
                if let strongSelf = self {
                    if let image = next?.cgImage {
                        strongSelf.contents = image
                    } else if strongSelf.enableEmpty {
                        strongSelf.contents = nil
                    }
                    if strongSelf.first && next != nil {
                        strongSelf.first = false
                        if strongSelf.isNodeLoaded {
                            strongSelf.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.18)
                        }
                    }
                    if !reportedHasImage {
                        if let hasImage = strongSelf.hasImage {
                            reportedHasImage = true
                            hasImage.set(true)
                        }
                    }
                }
            }
        }))
    }
    
    public override func clearContents() {
        super.clearContents()
        
        self.contents = nil
        self.disposable.set(nil)
    }
}


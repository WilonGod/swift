//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
@_exported import UIKit


//===----------------------------------------------------------------------===//
// Equatable types.
//===----------------------------------------------------------------------===//

@_transparent // @fragile
@warn_unused_result
public func == (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> Bool {
  return lhs.top == rhs.top &&
         lhs.left == rhs.left &&
         lhs.bottom == rhs.bottom &&
         lhs.right == rhs.right
}

extension UIEdgeInsets : Equatable {}

@_transparent // @fragile
@warn_unused_result
public func == (lhs: UIOffset, rhs: UIOffset) -> Bool {
  return lhs.horizontal == rhs.horizontal &&
         lhs.vertical == rhs.vertical
}

extension UIOffset : Equatable {}

// These are un-imported macros in UIKit.

//===----------------------------------------------------------------------===//
// UIDeviceOrientation
//===----------------------------------------------------------------------===//

#if !os(watchOS) && !os(tvOS)
public extension UIDeviceOrientation {
  var isLandscape: Bool {
    return self == .LandscapeLeft || self == .LandscapeRight
  }

  var isPortrait: Bool {
    return self == .Portrait || self == .PortraitUpsideDown
  }

  var isFlat: Bool {
    return self == .FaceUp || self == .FaceDown
  }

  var isValidInterfaceOrientation: Bool {
    switch (self) {
    case .Portrait, .PortraitUpsideDown, .LandscapeLeft, .LandscapeRight:
      return true
    default:
      return false
    }
  }
}

@warn_unused_result
public func UIDeviceOrientationIsLandscape(
  orientation: UIDeviceOrientation
) -> Bool {
  return orientation.isLandscape
}

@warn_unused_result
public func UIDeviceOrientationIsPortrait(
  orientation: UIDeviceOrientation
) -> Bool {
  return orientation.isPortrait
}

@warn_unused_result
public func UIDeviceOrientationIsValidInterfaceOrientation(
  orientation: UIDeviceOrientation) -> Bool
{
  return orientation.isValidInterfaceOrientation
}
#endif

//===----------------------------------------------------------------------===//
// UIInterfaceOrientation
//===----------------------------------------------------------------------===//

#if !os(watchOS) && !os(tvOS)
public extension UIInterfaceOrientation {
  var isLandscape: Bool {
    return self == .LandscapeLeft || self == .LandscapeRight
  }

  var isPortrait: Bool {
    return self == .Portrait || self == .PortraitUpsideDown
  }
}

@warn_unused_result
public func UIInterfaceOrientationIsPortrait(
  orientation: UIInterfaceOrientation) -> Bool {
  return orientation.isPortrait
}

@warn_unused_result
public func UIInterfaceOrientationIsLandscape(
  orientation: UIInterfaceOrientation
) -> Bool {
  return orientation.isLandscape
}
#endif

// Overlays for variadic initializers.

#if !os(watchOS) && !os(tvOS)
public extension UIActionSheet {
  convenience init(title: String?,
       delegate: UIActionSheetDelegate?,
       cancelButtonTitle: String?,
       destructiveButtonTitle: String?,
       // Hack around overload ambiguity with non-variadic constructor.
       // <rdar://problem/16704770>
       otherButtonTitles firstButtonTitle: String,
       _ moreButtonTitles: String...) {
    self.init(title: title,
              delegate: delegate,
              cancelButtonTitle: cancelButtonTitle,
              destructiveButtonTitle: destructiveButtonTitle)
    self.addButtonWithTitle(firstButtonTitle)
    for buttonTitle in moreButtonTitles {
      self.addButtonWithTitle(buttonTitle)
    }
  }
}
#endif

#if !os(watchOS) && !os(tvOS)
public extension UIAlertView {
  convenience init(title: String,
       message: String,
       delegate: UIAlertViewDelegate?,
       cancelButtonTitle: String?,
       // Hack around overload ambiguity with non-variadic constructor.
       // <rdar://problem/16704770>
       otherButtonTitles firstButtonTitle: String,
       _ moreButtonTitles: String...) {
    self.init(title: title,
              message: message,
              delegate: delegate,
              cancelButtonTitle: cancelButtonTitle)
    self.addButtonWithTitle(firstButtonTitle)
    for buttonTitle in moreButtonTitles {
      self.addButtonWithTitle(buttonTitle)
    }
  }
}
#endif

#if !os(watchOS)
internal struct _UIViewQuickLookState {
  static var views = Set<UIView>()
}

extension UIView : CustomPlaygroundQuickLookable {
  public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
    if _UIViewQuickLookState.views.contains(self) {
      return .View(UIImage())
    } else {
      _UIViewQuickLookState.views.insert(self)
      // in case of an empty rectangle abort the logging
      if (bounds.size.width == 0) || (bounds.size.height == 0) {
        return .View(UIImage())
      }
  
      UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
      // UIKit is about to update this to be optional, so make it work
      // with both older and newer SDKs. (In this context it should always
      // be present.)
      let ctx: CGContext! = UIGraphicsGetCurrentContext()
      UIColor(white:1.0, alpha:0.0).set()
      CGContextFillRect(ctx, bounds)
      layer.renderInContext(ctx)

      let image: UIImage! = UIGraphicsGetImageFromCurrentImageContext()
  
      UIGraphicsEndImageContext()
  
      _UIViewQuickLookState.views.remove(self)
      return .View(image)
    }
  }
}
#endif

extension UIColor : _ColorLiteralConvertible {
  public required convenience init(colorLiteralRed red: Float, green: Float,
                                   blue: Float, alpha: Float) {
    self.init(red: CGFloat(red), green: CGFloat(green),
              blue: CGFloat(blue), alpha: CGFloat(alpha))
  }
}

public typealias _ColorLiteralType = UIColor

extension UIImage : _ImageLiteralConvertible {
  private convenience init!(failableImageLiteral name: String) {
    self.init(named: name)
  }

  public required convenience init(imageLiteral name: String) {
    self.init(failableImageLiteral: name)
  }
}

public typealias _ImageLiteralType = UIImage

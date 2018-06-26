/*******************************************************************************
 
 µBlock - the most powerful, FREE ad blocker.
 Copyright (C) 2018 The µBlock authors
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see {http://www.gnu.org/licenses/}.
 
 Home: https://github.com/uBlock-LLC/uBlock-Mac
 */

import Cocoa

class AlertUtil {
    private init() {}
    
    static func displayUndertDevelopmentAlert() {
        infoAlert(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("This feature is under development.", comment: ""))
    }
    
    public static func infoAlert(title: String, message: String) {
        displayAlert(title: title, message: message, style: .informational)
    }
    
    public static func errorAlert(title: String, message: String) {
        displayAlert(title: title, message: message, style: .critical)
    }
   
    private static func displayAlert(title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.alertStyle = style
        alert.runModal()
    }
    
    public static func displayNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.identifier = message
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.deliveryDate = Date() + 0.1
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private static let toastFont = NSFont(name: "LucidaGrande", size: 14.0)
    public enum ToastType {
        case info
        case error
    }
    public static func toast(in view: NSView, message: String, toastType: ToastType? = .info) {
        let viewFrame = view.frame
        let width: CGFloat = 300
        let heightPadding: CGFloat = 10.0
        let height = message.height(withConstrainedWidth: width, font: AlertUtil.toastFont!) + heightPadding
        
        let textParagraph:NSMutableParagraphStyle = NSMutableParagraphStyle()
        textParagraph.alignment = .center
        let attributedString = NSAttributedString(string: message,
                                                  attributes: [.paragraphStyle : textParagraph, .font: toastFont!])
        let messageLabel = NSTextField(labelWithAttributedString: attributedString)
        messageLabel.textColor = .white
        messageLabel.wantsLayer = true
        messageLabel.frame = CGRect(x: 0, y: 0, width: width, height: height - heightPadding)
        
        let bgColor: NSColor = {
            if toastType == .info {
                return NSColor(deviceRed: 76/255.0, green: 175/255.0, blue: 80/255.0, alpha: 1)
            } else {
                return NSColor(deviceRed: 244/255.0, green: 67/255.0, blue: 54/255.0, alpha: 1)
            }
        }()
        let container = NSBox(frame: CGRect(x: (viewFrame.size.width - width) / 2, y: viewFrame.size.height - height - 20, width: width, height: height))
        container.cornerRadius = 4
        container.wantsLayer = true
        container.boxType = .custom
        container.borderType = .noBorder
        container.titlePosition = .noTitle
        container.fillColor = bgColor
        container.alphaValue = 0.0
        
        container.addSubview(messageLabel)
        view.addSubview(container)
        
        container.animator().alphaValue = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { container.animator().removeFromSuperview() }
    }
}

import Display
import UIKit
import AsyncDisplayKit
import UIKit
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import TelegramUIPreferences
import DeviceAccess

private final class ContactsControllerNodeView: UITracingLayerView, PreviewingHostView {
    var previewingDelegate: PreviewingHostViewDelegate? {
        return PreviewingHostViewDelegate(controllerForLocation: { [weak self] sourceView, point in
            return self?.controller?.previewingController(from: sourceView, for: point)
        }, commitController: { [weak self] controller in
            self?.controller?.previewingCommit(controller)
        })
    }
    
    weak var controller: ContactsController?
}

final class ContactsControllerNode: ASDisplayNode {
    let contactListNode: ContactListNode
    
    private let context: AccountContext
    private(set) var searchDisplayController: SearchDisplayController?
    
    private var containerLayout: (ContainerViewLayout, CGFloat)?
    
    var navigationBar: NavigationBar?
    
    var requestDeactivateSearch: (() -> Void)?
    var requestOpenPeerFromSearch: ((ContactListPeer) -> Void)?
    var openPeopleNearby: (() -> Void)?
    var openInvite: (() -> Void)?
    
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    weak var controller: ContactsController?
    
    init(context: AccountContext, sortOrder: Signal<ContactsSortOrder, NoError>, present: @escaping (ViewController, Any?) -> Void, controller: ContactsController) {
        self.context = context
        self.controller = controller
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        var addNearbyImpl: (() -> Void)?
        var inviteImpl: (() -> Void)?
        let options = [ContactListAdditionalOption(title: presentationData.strings.Contacts_AddPeopleNearby, icon: .generic(UIImage(bundleImageName: "Contact List/PeopleNearbyIcon")!), action: {
            addNearbyImpl?()
        }), ContactListAdditionalOption(title: presentationData.strings.Contacts_InviteFriends, icon: .generic(UIImage(bundleImageName: "Contact List/AddMemberIcon")!), action: {
            inviteImpl?()
        })]
        
        let presentation = sortOrder
        |> map { sortOrder -> ContactListPresentation in
            switch sortOrder {
                case .presence:
                    return .orderedByPresence(options: options)
                case .natural:
                    return .natural(options: options, includeChatList: false)
            }
        }
        
        self.contactListNode = ContactListNode(context: context, presentation: presentation, displaySortOptions: true)
        
        super.init()
        
        self.setViewBlock({
            return ContactsControllerNodeView()
        })
        
        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor
        
        self.addSubnode(self.contactListNode)
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                let previousTheme = strongSelf.presentationData.theme
                let previousStrings = strongSelf.presentationData.strings
                
                strongSelf.presentationData = presentationData
                
                if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                    strongSelf.updateThemeAndStrings()
                }
            }
        })
        
        addNearbyImpl = { [weak self] in
            if let strongSelf = self {
                strongSelf.openPeopleNearby?()
            }
        }
        
        inviteImpl = { [weak self] in
            if let strongSelf = self {
                strongSelf.openInvite?()
            }
        }
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    override func didLoad() {
        super.didLoad()
        
        (self.view as? ContactsControllerNodeView)?.controller = self.controller
    }
    
    private func updateThemeAndStrings() {
        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor
        self.searchDisplayController?.updatePresentationData(self.presentationData)
    }
    
    func scrollToTop() {
        if let contentNode = self.searchDisplayController?.contentNode as? ContactsSearchContainerNode {
            contentNode.scrollToTop()
        } else {
            self.contactListNode.scrollToTop()
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, actualNavigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        self.containerLayout = (layout, navigationBarHeight)
        
        var insets = layout.insets(options: [.input])
        insets.top += navigationBarHeight
    
        var headerInsets = layout.insets(options: [.input])
        headerInsets.top += actualNavigationBarHeight
        
        if let searchDisplayController = self.searchDisplayController {
            searchDisplayController.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: transition)
        }
        
        self.contactListNode.containerLayoutUpdated(ContainerViewLayout(size: layout.size, metrics: layout.metrics, intrinsicInsets: insets, safeInsets: layout.safeInsets, statusBarHeight: layout.statusBarHeight, inputHeight: layout.inputHeight, standardInputHeight: layout.standardInputHeight, inputHeightIsInteractivellyChanging: layout.inputHeightIsInteractivellyChanging, inVoiceOver: layout.inVoiceOver), headerInsets: headerInsets, transition: transition)
        
        self.contactListNode.frame = CGRect(origin: CGPoint(), size: layout.size)
    }
    
    func activateSearch(placeholderNode: SearchBarPlaceholderNode) {
        guard let (containerLayout, navigationBarHeight) = self.containerLayout, let navigationBar = self.navigationBar, self.searchDisplayController == nil else {
            return
        }
        
        self.searchDisplayController = SearchDisplayController(presentationData: self.presentationData, contentNode: ContactsSearchContainerNode(context: self.context, onlyWriteable: false, categories: [.cloudContacts, .global, .deviceContacts], openPeer: { [weak self] peer in
            if let requestOpenPeerFromSearch = self?.requestOpenPeerFromSearch {
                requestOpenPeerFromSearch(peer)
            }
        }), cancel: { [weak self] in
            if let requestDeactivateSearch = self?.requestDeactivateSearch {
                requestDeactivateSearch()
            }
        })
        
        self.searchDisplayController?.containerLayoutUpdated(containerLayout, navigationBarHeight: navigationBarHeight, transition: .immediate)
        self.searchDisplayController?.activate(insertSubnode: { [weak self, weak placeholderNode] subnode, isSearchBar in
            if let strongSelf = self, let strongPlaceholderNode = placeholderNode {
                if isSearchBar {
                    strongPlaceholderNode.supernode?.insertSubnode(subnode, aboveSubnode: strongPlaceholderNode)
                } else {
                    strongSelf.insertSubnode(subnode, belowSubnode: navigationBar)
                }
            }
        }, placeholder: placeholderNode)
    }
    
    func deactivateSearch(placeholderNode: SearchBarPlaceholderNode, animated: Bool) {
        if let searchDisplayController = self.searchDisplayController {
            searchDisplayController.deactivate(placeholder: placeholderNode, animated: animated)
            self.searchDisplayController = nil
        }
    }
}

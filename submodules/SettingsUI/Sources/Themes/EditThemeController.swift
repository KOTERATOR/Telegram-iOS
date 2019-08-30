import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AlertUI
import LegacyMediaPickerUI
import WallpaperResources
import AccountContext

private final class EditThemeControllerArguments {
    let context: AccountContext
    let updateState: ((EditThemeControllerState) -> EditThemeControllerState) -> Void
    let openFile: () -> Void
    
    init(context: AccountContext, updateState: @escaping ((EditThemeControllerState) -> EditThemeControllerState) -> Void, openFile: @escaping () -> Void) {
        self.context = context
        self.updateState = updateState
        self.openFile = openFile
    }
}

private enum EditThemeEntryTag: ItemListItemTag {
    case title
    
    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? EditThemeEntryTag, self == other {
            return true
        } else {
            return false
        }
    }
}

private enum EditThemeControllerSection: Int32 {
    case info
    case chatPreview
}

private enum EditThemeControllerEntry: ItemListNodeEntry {
    case title(PresentationTheme, PresentationStrings, String, String, Bool)
    case slug(PresentationTheme, PresentationStrings, String, String, Bool)
    case slugInfo(PresentationTheme, String)
    case chatPreviewHeader(PresentationTheme, String)
    case chatPreview(PresentationTheme, PresentationTheme, TelegramWallpaper, PresentationFontSize, PresentationStrings, PresentationDateTimeFormat, PresentationPersonNameOrder)
    case uploadTheme(PresentationTheme, String)
    case uploadInfo(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
            case .title, .slug, .slugInfo:
                return EditThemeControllerSection.info.rawValue
            case .chatPreviewHeader, .chatPreview, .uploadTheme, .uploadInfo:
                return EditThemeControllerSection.chatPreview.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
            case .title:
                return 0
            case .slug:
                return 1
            case .slugInfo:
                return 2
            case .chatPreviewHeader:
                return 3
            case .chatPreview:
                return 4
            case .uploadTheme:
                return 5
            case .uploadInfo:
                return 6
        }
    }
    
    static func ==(lhs: EditThemeControllerEntry, rhs: EditThemeControllerEntry) -> Bool {
        switch lhs {
            case let .title(lhsTheme, lhsStrings, lhsTitle, lhsValue, lhsDone):
                if case let .title(rhsTheme, rhsStrings, rhsTitle, rhsValue, rhsDone) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsTitle == rhsTitle, lhsValue == rhsValue, lhsDone == rhsDone {
                    return true
                } else {
                    return false
                }
            case let .slug(lhsTheme, lhsStrings, lhsTitle, lhsValue, lhsEnabled):
                if case let .slug(rhsTheme, rhsStrings, rhsTitle, rhsValue, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsTitle == rhsTitle, lhsValue == rhsValue, lhsEnabled == rhsEnabled {
                    return true
                } else {
                    return false
                }
            case let .slugInfo(lhsTheme, lhsText):
                if case let .slugInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .chatPreviewHeader(lhsTheme, lhsText):
                if case let .chatPreviewHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .chatPreview(lhsTheme, lhsComponentTheme, lhsWallpaper, lhsFontSize, lhsStrings, lhsTimeFormat, lhsNameOrder):
                if case let .chatPreview(rhsTheme, rhsComponentTheme, rhsWallpaper, rhsFontSize, rhsStrings, rhsTimeFormat, rhsNameOrder) = rhs, lhsComponentTheme === rhsComponentTheme, lhsTheme === rhsTheme, lhsWallpaper == rhsWallpaper, lhsFontSize == rhsFontSize, lhsStrings === rhsStrings, lhsTimeFormat == rhsTimeFormat, lhsNameOrder == rhsNameOrder {
                    return true
                } else {
                    return false
                }
            case let .uploadTheme(lhsTheme, lhsText):
                if case let .uploadTheme(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .uploadInfo(lhsTheme, lhsText):
                if case let .uploadInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: EditThemeControllerEntry, rhs: EditThemeControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: EditThemeControllerArguments) -> ListViewItem {
        switch self {
            case let .title(theme, strings, title, text, done):
                return ItemListSingleLineInputItem(theme: theme, strings: strings, title: NSAttributedString(), text: text, placeholder: title, type: .regular(capitalization: true, autocorrection: false), returnKeyType: done ? .done : .next, clearType: .onFocus, tag: EditThemeEntryTag.title, sectionId: self.section, textUpdated: { value in
                    arguments.updateState { current in
                        var state = current
                        state.title = value
                        return state
                    }
                }, action: {
                    
                })
            case let .slug(theme, strings, title, text, enabled):
                return ItemListSingleLineInputItem(theme: theme, strings: strings, title: NSAttributedString(string: "t.me/addtheme/", textColor: theme.list.itemPrimaryTextColor), text: text, placeholder: title, type: .username, clearType: .onFocus, enabled: enabled, sectionId: self.section, textUpdated: { value in
                    arguments.updateState { current in
                        var state = current
                        state.slug = value
                        return state
                    }
                }, action: {
                    
                })
            case let .slugInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .chatPreviewHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .chatPreview(theme, componentTheme, wallpaper, fontSize, strings, dateTimeFormat, nameDisplayOrder):
                return ThemeSettingsChatPreviewItem(context: arguments.context, theme: theme, componentTheme: componentTheme, strings: strings, sectionId: self.section, fontSize: fontSize, wallpaper: wallpaper, dateTimeFormat: dateTimeFormat, nameDisplayOrder: nameDisplayOrder)
            case let .uploadTheme(theme, text):
                return ItemListActionItem(theme: theme, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                    arguments.openFile()
                })
            case let .uploadInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
        }
    }
}

public enum EditThemeControllerMode: Equatable {
    case create
    case edit(PresentationCloudTheme)
}

private struct EditThemeControllerState: Equatable {
    var mode: EditThemeControllerMode
    var title: String
    var slug: String
    var updatedTheme: PresentationTheme?
    var updating: Bool
}

private func editThemeControllerEntries(presentationData: PresentationData, state: EditThemeControllerState, previewTheme: PresentationTheme) -> [EditThemeControllerEntry] {
    var entries: [EditThemeControllerEntry] = []
    
    var isCreate = false
    if case .create = state.mode {
        isCreate = true
    }
    entries.append(.title(presentationData.theme, presentationData.strings, presentationData.strings.EditTheme_Title, state.title, isCreate))
    
    if case .edit = state.mode {
        entries.append(.slug(presentationData.theme, presentationData.strings, presentationData.strings.EditTheme_ShortLink, state.slug, true))
        entries.append(.slugInfo(presentationData.theme, presentationData.strings.EditTheme_ShortLinkInfo))
    }
    
    entries.append(.chatPreviewHeader(presentationData.theme, presentationData.strings.EditTheme_Preview.uppercased()))
    entries.append(.chatPreview(presentationData.theme, previewTheme, previewTheme.chat.defaultWallpaper, presentationData.fontSize, presentationData.strings, presentationData.dateTimeFormat, presentationData.nameDisplayOrder))
    
    let uploadText: String
    let uploadInfo: String
    switch state.mode {
        case .create:
            uploadText = presentationData.strings.EditTheme_UploadNewTheme
            uploadInfo = presentationData.strings.EditTheme_UploadNewInfo
        case let .edit(theme):
            if let _ = theme.theme.file {
                uploadText = presentationData.strings.EditTheme_UploadEditedTheme
                uploadInfo = presentationData.strings.EditTheme_UploadEditedInfo
            } else {
                uploadText = presentationData.strings.EditTheme_UploadNewTheme
                uploadInfo = presentationData.strings.EditTheme_UploadNewInfo
            }
    }
    entries.append(.uploadTheme(presentationData.theme, uploadText))
    entries.append(.uploadInfo(presentationData.theme, uploadInfo))
    
    return entries
}

public func editThemeController(context: AccountContext, mode: EditThemeControllerMode, navigateToChat: ((PeerId) -> Void)? = nil) -> ViewController {
    let initialState: EditThemeControllerState
    let previewThemePromise = Promise<PresentationTheme>()
    switch mode {
        case .create:
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            initialState = EditThemeControllerState(mode: mode, title: "", slug: "", updatedTheme: nil, updating: false)
            previewThemePromise.set(.single(presentationData.theme.withUpdated(name: "", author: nil, defaultWallpaper: presentationData.chatWallpaper)))
        case let .edit(info):
            if let file = info.theme.file, let path = context.sharedContext.accountManager.mediaBox.completedResourcePath(file.resource), let data = try? Data(contentsOf: URL(fileURLWithPath: path)), let theme = makePresentationTheme(data: data, resolvedWallpaper: info.resolvedWallpaper) {
                if case let .file(file) = theme.chat.defaultWallpaper, file.id == 0 {
                    previewThemePromise.set(cachedWallpaper(account: context.account, slug: file.slug)
                    |> map ({ wallpaper -> PresentationTheme in
                        if let wallpaper = wallpaper {
                            return theme.withUpdated(name: nil, author: nil, defaultWallpaper: wallpaper.wallpaper)
                        } else {
                            return theme.withUpdated(name: nil, author: nil, defaultWallpaper: .color(Int32(bitPattern: theme.chatList.backgroundColor.rgb)))
                        }
                    }))
                } else {
                    previewThemePromise.set(.single(theme.withUpdated(name: nil, author: nil, defaultWallpaper: info.resolvedWallpaper)))
                }
            } else {
                previewThemePromise.set(.single(context.sharedContext.currentPresentationData.with { $0 }.theme))
            }
            initialState = EditThemeControllerState(mode: mode, title: info.theme.title, slug: info.theme.slug, updatedTheme: nil, updating: false)
    }
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((EditThemeControllerState) -> EditThemeControllerState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    var dismissImpl: (() -> Void)?
    var dismissInputImpl: (() -> Void)?
    
    let arguments = EditThemeControllerArguments(context: context, updateState: { f in
        updateState(f)
    }, openFile: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let controller = legacyICloudFilePicker(theme: presentationData.theme, mode: .import, documentTypes: ["org.telegram.Telegram-iOS.theme"], completion: { urls in
            if let url = urls.first{
                if let data = try? Data(contentsOf: url), let theme = makePresentationTheme(data: data) {
                    if case let .file(file) = theme.chat.defaultWallpaper, file.id == 0 {
                        let _ = (cachedWallpaper(account: context.account, slug: file.slug)
                        |> mapToSignal { wallpaper -> Signal<TelegramWallpaper?, NoError> in
                            if let wallpaper = wallpaper, case let .file(file) = wallpaper.wallpaper {
                                var convertedRepresentations: [ImageRepresentationWithReference] = []
                                convertedRepresentations.append(ImageRepresentationWithReference(representation: TelegramMediaImageRepresentation(dimensions: CGSize(width: 100.0, height: 100.0), resource: file.file.resource), reference: .wallpaper(resource: file.file.resource)))
                                return wallpaperImage(account: context.account, accountManager: context.sharedContext.accountManager, fileReference: .standalone(media: file.file), representations: convertedRepresentations, alwaysShowThumbnailFirst: false, thumbnail: false, onlyFullSize: true, autoFetchFullSize: true, synchronousLoad: false)
                                |> map { _ -> TelegramWallpaper? in
                                    return wallpaper.wallpaper
                                }
                            } else {
                                return .single(nil)
                            }
                        }
                        |> deliverOnMainQueue).start(next: { wallpaper in
                            let updatedTheme = theme.withUpdated(name: nil, author: nil, defaultWallpaper: wallpaper)
                            updateState { current in
                                var state = current
                                previewThemePromise.set(.single(updatedTheme))
                                state.updatedTheme = updatedTheme
                                return state
                            }
                        })
                    } else {
                        updateState { current in
                            var state = current
                            previewThemePromise.set(.single(theme))
                            state.updatedTheme = theme
                            return state
                        }
                    }
                }
                else {
                    presentControllerImpl?(textAlertController(context: context, title: nil, text: presentationData.strings.EditTheme_FileReadError, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]), nil)
                }
            }
        })
        presentControllerImpl?(controller, nil)
    })
    
    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, statePromise.get(), previewThemePromise.get())
    |> map { presentationData, state, previewTheme -> (ItemListControllerState, (ItemListNodeState<EditThemeControllerEntry>, EditThemeControllerEntry.ItemGenerationArguments)) in
        let leftNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Cancel), style: .regular, enabled: true, action: {
            dismissImpl?()
        })
        
        var focusItemTag: ItemListItemTag?
        if case .create = state.mode {
            focusItemTag = EditThemeEntryTag.title
        }
        
        let rightNavigationButton: ItemListNavigationButton
        if state.updating {
            rightNavigationButton = ItemListNavigationButton(content: .none, style: .activity, enabled: true, action: {})
        } else {
            let isComplete: Bool
            if case .create = mode {
                isComplete = !state.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
            } else {
                isComplete = !state.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty && !state.slug.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
            }
            
            rightNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Done), style: .bold, enabled: isComplete, action: {
                dismissInputImpl?()
                arguments.updateState { current in
                    var state = current
                    state.updating = true
                    return state
                }
                
                let _ = (previewThemePromise.get()
                |> deliverOnMainQueue).start(next: { previewTheme in
                    let saveThemeTemplateFile: (String, LocalFileMediaResource, @escaping () -> Void) -> Void = { title, resource, completion in
                        let file = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: resource.fileId), partialReference: nil, resource: resource, previewRepresentations: [], immediateThumbnailData: nil, mimeType: "application/x-tgtheme-ios", size: nil, attributes: [.FileName(fileName: "\(title).tgios-theme")])
                        let message = EnqueueMessage.message(text: "", attributes: [], mediaReference: .standalone(media: file), replyToMessageId: nil, localGroupingKey: nil)

                        let _ = enqueueMessages(account: context.account, peerId: context.account.peerId, messages: [message]).start()

                        if let navigateToChat = navigateToChat {
                            presentControllerImpl?(textAlertController(context: context, title: nil, text: presentationData.strings.EditTheme_ThemeTemplateAlert, actions: [TextAlertAction(type: .genericAction, title: presentationData.strings.Settings_SavedMessages, action: {
                                completion()
                                navigateToChat(context.account.peerId)
                            }), TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
                                completion()
                            })], actionLayout: .vertical), nil)
                        } else {
                            completion()
                        }
                    }
                    
                    let theme: PresentationTheme?
                    let hasCustomFile: Bool
                    if let updatedTheme = state.updatedTheme {
                        theme = updatedTheme.withUpdated(name: state.title, author: "", defaultWallpaper: nil)
                        hasCustomFile = true
                    } else {
                        if case let .edit(info) = mode, let _ = info.theme.file {
                            theme = nil
                            hasCustomFile = true
                        } else {
                            theme = previewTheme.withUpdated(name: state.title, author: "", defaultWallpaper: nil)
                            hasCustomFile = false
                        }
                    }
                    
                    let themeResource: LocalFileMediaResource?
                    let themeData: Data?
                    let themeThumbnailData: Data?
                    if let theme = theme, let themeString = encodePresentationTheme(theme), let data = themeString.data(using: .utf8) {
                        let resource = LocalFileMediaResource(fileId: arc4random64())
                        context.account.postbox.mediaBox.storeResourceData(resource.id, data: data)
                        context.sharedContext.accountManager.mediaBox.storeResourceData(resource.id, data: data)
                        themeResource = resource
                        themeData = data
                        
                        var wallpaperImage: UIImage?
                        if case .file = theme.chat.defaultWallpaper {
                            wallpaperImage = chatControllerBackgroundImage(theme: theme, wallpaper: theme.chat.defaultWallpaper, mediaBox: context.sharedContext.accountManager.mediaBox, knockoutMode: false)
                        }
                        let themeThumbnail = generateImage(CGSize(width: 213, height: 320.0), contextGenerator: { size, context in
                            if let image = generateImage(CGSize(width: 194.0, height: 291.0), contextGenerator: { size, c in
                                drawThemeImage(context: c, theme: theme, wallpaperImage: wallpaperImage, size: size)
                            })?.cgImage {
                                context.draw(image, in: CGRect(origin: CGPoint(), size: size))
                            }
                        }, scale: 1.0)
                        themeThumbnailData = themeThumbnail?.jpegData(compressionQuality: 0.6)
                    } else {
                        themeResource = nil
                        themeData = nil
                        themeThumbnailData = nil
                    }
                    
                    let resolvedWallpaper: TelegramWallpaper?
                    if let theme = theme, case let .file(file) = theme.chat.defaultWallpaper, file.id != 0 {
                        resolvedWallpaper = theme.chat.defaultWallpaper
                        updateCachedWallpaper(account: context.account, wallpaper: theme.chat.defaultWallpaper)
                    } else {
                        resolvedWallpaper = nil
                    }
                    
                    switch mode {
                        case .create:
                            if let themeResource = themeResource {
                                let _ = (createTheme(account: context.account, title: state.title, resource: themeResource, thumbnailData: themeThumbnailData)
                                |> deliverOnMainQueue).start(next: { next in
                                    if case let .result(resultTheme) = next {
                                        let _ = applyTheme(accountManager: context.sharedContext.accountManager, account: context.account, theme: resultTheme).start()
                                        let _ = (context.sharedContext.accountManager.transaction { transaction -> Void in
                                            transaction.updateSharedData(ApplicationSpecificSharedDataKeys.presentationThemeSettings, { entry in
                                                let current: PresentationThemeSettings
                                                if let entry = entry as? PresentationThemeSettings {
                                                    current = entry
                                                } else {
                                                    current = PresentationThemeSettings.defaultSettings
                                                }
                                                if let resource = resultTheme.file?.resource, let data = themeData {
                                                    context.sharedContext.accountManager.mediaBox.storeResourceData(resource.id, data: data)
                                                }
                                                let themeReference: PresentationThemeReference = .cloud(PresentationCloudTheme(theme: resultTheme, resolvedWallpaper: resolvedWallpaper))
                                                var themeSpecificChatWallpapers = current.themeSpecificChatWallpapers
                                                if let theme = theme {
                                                    themeSpecificChatWallpapers[themeReference.index] = theme.chat.defaultWallpaper
                                                }
                                                return PresentationThemeSettings(chatWallpaper: theme?.chat.defaultWallpaper ?? current.chatWallpaper, theme: themeReference, themeSpecificAccentColors: current.themeSpecificAccentColors, themeSpecificChatWallpapers: themeSpecificChatWallpapers, fontSize: current.fontSize, automaticThemeSwitchSetting: current.automaticThemeSwitchSetting, largeEmoji: current.largeEmoji, disableAnimations: current.disableAnimations)
                                            })
                                        } |> deliverOnMainQueue).start(completed: {
                                            if !hasCustomFile {
                                                saveThemeTemplateFile(state.title, themeResource, {
                                                    dismissImpl?()
                                                })
                                            } else {
                                                dismissImpl?()
                                            }
                                        })
                                    }
                                }, error: { error in
                                    arguments.updateState { current in
                                        var state = current
                                        state.updating = false
                                        return state
                                    }
                                })
                            }
                        case let .edit(info):
                            let _ = (updateTheme(account: context.account, theme: info.theme, title: state.title, slug: state.slug, resource: themeResource)
                            |> deliverOnMainQueue).start(next: { next in
                                if case let .result(resultTheme) = next {
                                    let _ = applyTheme(accountManager: context.sharedContext.accountManager, account: context.account, theme: resultTheme).start()
                                    let _ = (context.sharedContext.accountManager.transaction { transaction -> Void in
                                        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.presentationThemeSettings, { entry in
                                            let current: PresentationThemeSettings
                                            if let entry = entry as? PresentationThemeSettings {
                                                current = entry
                                            } else {
                                                current = PresentationThemeSettings.defaultSettings
                                            }
                                            
                                            if let resource = resultTheme.file?.resource, let data = themeData {
                                                context.sharedContext.accountManager.mediaBox.storeResourceData(resource.id, data: data)
                                            }
                                            
                                            let themeReference: PresentationThemeReference = .cloud(PresentationCloudTheme(theme: resultTheme, resolvedWallpaper: resolvedWallpaper))
                                            var themeSpecificChatWallpapers = current.themeSpecificChatWallpapers
                                            if let theme = theme {
                                                themeSpecificChatWallpapers[themeReference.index] = theme.chat.defaultWallpaper
                                            }
                                            
                                            return PresentationThemeSettings(chatWallpaper: theme?.chat.defaultWallpaper ?? current.chatWallpaper, theme: themeReference, themeSpecificAccentColors: current.themeSpecificAccentColors, themeSpecificChatWallpapers: themeSpecificChatWallpapers, fontSize: current.fontSize, automaticThemeSwitchSetting: current.automaticThemeSwitchSetting, largeEmoji: current.largeEmoji, disableAnimations: current.disableAnimations)
                                        })
                                    } |> deliverOnMainQueue).start(completed: {
                                        if let themeResource = themeResource, !hasCustomFile {
                                            saveThemeTemplateFile(state.title, themeResource, {
                                                dismissImpl?()
                                            })
                                        } else {
                                            dismissImpl?()
                                        }
                                    })
                                }
                            }, error: { error in
                                arguments.updateState { current in
                                    var state = current
                                    state.updating = false
                                    return state
                                }
                            })
                    }
                })
            })
        }
        
        let title: String
        switch mode {
            case .create:
                title = presentationData.strings.EditTheme_CreateTitle
            case let .edit(theme):
                if theme.theme.file == nil {
                    title = presentationData.strings.EditTheme_CreateTitle
                } else {
                    title = presentationData.strings.EditTheme_EditTitle
                }
        }
        let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(title), leftNavigationButton: leftNavigationButton, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(entries: editThemeControllerEntries(presentationData: presentationData, state: state, previewTheme: previewTheme), style: .blocks, focusItemTag: focusItemTag, emptyStateItem: nil, animateChanges: false)
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    dismissImpl = { [weak controller] in
        controller?.view.endEditing(true)
        let _ = controller?.dismiss()
    }
    dismissInputImpl = { [weak controller] in
        controller?.view.endEditing(true)
    }
    return controller
}

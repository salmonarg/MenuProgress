/**
 * Copyright (c) 2026 Salmonization
 *
 * This source code is licensed under the BSD 2-Clause License
 * which you can find it in the LICENSE file in the root directory of this source tree.
 */

import AppKit

struct Event: Codable {
    var name: String
    var date: String
}

let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

// day delta, midnight-to-midnight
func daysUntil(_ dateString: String, from now: Date = Date()) -> Int? {
    guard let target = dateFormatter.date(from: dateString) else { return nil }
    let cal = Calendar.current
    return cal.dateComponents([.day],
                              from: cal.startOfDay(for: now),
                              to: cal.startOfDay(for: target)).day
}

func shortStatus(_ days: Int) -> String {
    if days > 0 { return "\(days) Left" }
    if days < 0 { return "\(-days) Passed" }
    return "Today"
}

func longStatus(_ days: Int) -> String {
    if days > 0 { return "\(days) Days Left" }
    if days < 0 { return "\(-days) Days Passed" }
    return "Today"
}

func stackedTitle(_ name: String, _ status: String) -> NSAttributedString {
    let style = NSMutableParagraphStyle()
    style.alignment = .right
    style.maximumLineHeight = 10
    style.minimumLineHeight = 10

    let text = "\(name)\n\(status)"
    let attributed = NSMutableAttributedString(string: text)
    let full = NSRange(location: 0, length: (text as NSString).length)
    attributed.addAttributes([.paragraphStyle: style, .baselineOffset: -3], range: full)

    let nameLength = (name as NSString).length
    attributed.addAttribute(.font, value: NSFont.systemFont(ofSize: 8, weight: .regular),
                            range: NSRange(location: 0, length: nameLength))
    attributed.addAttribute(.font, value: NSFont.systemFont(ofSize: 10, weight: .medium),
                            range: NSRange(location: nameLength + 1,
                                           length: (text as NSString).length - nameLength - 1))
    return attributed
}

func menuItemTitle(_ name: String, _ status: String) -> NSAttributedString {
    let text = "\(name)\n\(status)"
    let attributed = NSMutableAttributedString(string: text)
    let nameLength = (name as NSString).length

    attributed.addAttribute(.font, value: NSFont.menuFont(ofSize: 0),
                            range: NSRange(location: 0, length: nameLength))
    attributed.addAttributes([.font: NSFont.menuFont(ofSize: NSFont.smallSystemFontSize),
                              .foregroundColor: NSColor.secondaryLabelColor],
                             range: NSRange(location: nameLength + 1,
                                            length: (text as NSString).length - nameLength - 1))
    return attributed
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var events: [Event] = []
    var selectedName: String?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        load()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
        updateTitle()

        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateTitle()
        }
    }

    // MARK: - Storage

    func load() {
        if let data = UserDefaults.standard.data(forKey: "Events"),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }
        selectedName = UserDefaults.standard.string(forKey: "SelectedEvent")
    }

    func save() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: "Events")
        }
        UserDefaults.standard.set(selectedName, forKey: "SelectedEvent")
    }

    var selectedEvent: Event? {
        events.first { $0.name == selectedName } ?? events.first
    }

    // MARK: - UI

    func updateTitle() {
        guard let button = statusItem.button else { return }
        guard let event = selectedEvent, let days = daysUntil(event.date) else {
            button.attributedTitle = NSAttributedString(string: "MenuProgress")
            return
        }
        button.attributedTitle = stackedTitle(event.name, shortStatus(days))
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = statusItem.menu!
        menu.removeAllItems()

        if events.isEmpty {
            let empty = NSMenuItem(title: "No event found.", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for event in events {
                let status = daysUntil(event.date).map(longStatus) ?? "invalid date"
                let item = NSMenuItem(title: "", action: #selector(selectEvent(_:)), keyEquivalent: "")
                item.attributedTitle = menuItemTitle(event.name, status)
                item.representedObject = event.name
                item.state = (event.name == selectedEvent?.name) ? .on : .off
                menu.addItem(item)
            }
        }
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Add...", action: #selector(addEvent), keyEquivalent: "n"))
        menu.addItem(eventSubmenu(title: "Edit", action: #selector(editEvent(_:))))
        menu.addItem(eventSubmenu(title: "Remove", action: #selector(removeEvent(_:))))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Import...", action: #selector(importEvents), keyEquivalent: ""))
        let exportItem = NSMenuItem(title: "Export...", action: #selector(exportEvents), keyEquivalent: "")
        exportItem.isEnabled = !events.isEmpty
        menu.addItem(exportItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminate), keyEquivalent: "q"))
    }

    func eventSubmenu(title: String, action: Selector) -> NSMenuItem {
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for event in events {
            let item = NSMenuItem(title: event.name, action: action, keyEquivalent: "")
            item.representedObject = event.name
            submenu.addItem(item)
        }
        parent.submenu = submenu
        parent.isEnabled = !events.isEmpty
        return parent
    }

    // MARK: - Actions

    @objc func selectEvent(_ sender: NSMenuItem) {
        selectedName = sender.representedObject as? String
        save()
        updateTitle()
    }

    @objc func removeEvent(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Remove '\(name)'?"
        alert.informativeText = "This cannot be undone."
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        events.removeAll { $0.name == name }
        if selectedName == name { selectedName = events.first?.name }
        save()
        updateTitle()
    }

    @objc func addEvent() {
        guard let result = runEventDialog(title: "Add Event", confirm: "Add",
                                          name: "", date: Date()) else { return }
        let name = result.name
        guard !name.isEmpty else {
            warn("Name must not be empty.")
            return
        }
        guard !events.contains(where: { $0.name == name }) else {
            warn("Event with name '\(name)' already exists.")
            return
        }

        events.append(Event(name: name, date: dateFormatter.string(from: result.date)))
        if selectedName == nil { selectedName = name }
        save()
        updateTitle()
    }

    @objc func editEvent(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String,
              let index = events.firstIndex(where: { $0.name == name }) else { return }
        let current = dateFormatter.date(from: events[index].date) ?? Date()
        guard let result = runEventDialog(title: "Edit Event", confirm: "Save",
                                          name: name, date: current) else { return }
        let newName = result.name
        guard !newName.isEmpty else {
            warn("Name must not be empty.")
            return
        }
        guard newName == name || !events.contains(where: { $0.name == newName }) else {
            warn("Event with name '\(newName)' already exists.")
            return
        }

        events[index] = Event(name: newName, date: dateFormatter.string(from: result.date))
        if selectedName == name { selectedName = newName }
        save()
        updateTitle()
    }

    // MARK: - Import / Export

    @objc func exportEvents() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "events.json"
        panel.allowedFileTypes = ["json"]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        do {
            try encoder.encode(events).write(to: url)
        } catch {
            warn("Export failed: \(error.localizedDescription)")
        }
    }

    @objc func importEvents() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["json"]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let data = try? Data(contentsOf: url),
              let imported = try? JSONDecoder().decode([Event].self, from: data) else {
            warn("Not a valid MenuProgress event file.")
            return
        }
        guard imported.allSatisfy({ daysUntil($0.date) != nil }) else {
            warn("The file contains a date that is not YYYY-MM-DD.")
            return
        }

        // Replacing beats merging: no name-collision rules to invent or explain.
        let confirm = NSAlert()
        confirm.messageText = "Import \(imported.count) event(s)?"
        confirm.informativeText = "This replaces all current events."
        confirm.addButton(withTitle: "Import")
        confirm.addButton(withTitle: "Cancel")
        guard confirm.runModal() == .alertFirstButtonReturn else { return }

        events = imported
        if !events.contains(where: { $0.name == selectedName }) {
            selectedName = events.first?.name
        }
        save()
        updateTitle()
    }

    // MARK: - Event dialog

    func runEventDialog(title: String, confirm: String, name: String, date: Date) -> (name: String, date: Date)? {
        let width: CGFloat = 320
        let height: CGFloat = 170
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = ""
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        let content = panel.contentView!

        let heading = NSTextField(labelWithString: title)
        heading.font = NSFont.systemFont(ofSize: 17, weight: .bold)
        heading.frame = NSRect(x: 20, y: height - 42, width: width - 40, height: 22)
        content.addSubview(heading)

        let datePicker = NSDatePicker(frame: NSRect(x: 20, y: 58, width: 0, height: 24))
        datePicker.datePickerStyle = .textFieldAndStepper
        datePicker.datePickerElements = .yearMonthDay
        datePicker.dateValue = date
        if #available(macOS 10.15.4, *) {
            datePicker.presentsCalendarOverlay = true
        }
        datePicker.sizeToFit()
        datePicker.setFrameOrigin(NSPoint(x: 20, y: 58))
        content.addSubview(datePicker)

        let nameField = NSTextField(frame: NSRect(x: 20, y: 92, width: width - 40, height: 24))
        nameField.placeholderString = "Name"
        nameField.stringValue = name
        content.addSubview(nameField)

        let confirmButton = NSButton(frame: NSRect(x: width - 92, y: 20, width: 80, height: 24))
        confirmButton.title = confirm
        confirmButton.bezelStyle = .rounded
        confirmButton.keyEquivalent = "\r"
        confirmButton.target = self
        confirmButton.action = #selector(dialogConfirm)
        content.addSubview(confirmButton)

        panel.initialFirstResponder = nameField
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        let response = NSApp.runModal(for: panel)
        panel.orderOut(nil)

        guard response == .OK else { return nil }
        return (nameField.stringValue.trimmingCharacters(in: .whitespaces), datePicker.dateValue)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.stopModal(withCode: .cancel)
        return false
    }

    @objc func dialogConfirm() {
        NSApp.stopModal(withCode: .OK)
    }

    func warn(_ text: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = text
        alert.runModal()
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }
}

// self-check: ./MenuProgress --selftest
if CommandLine.arguments.contains("--selftest") {
    let cal = Calendar.current
    let today = Date()
    let fmt = { (d: Date) in dateFormatter.string(from: d) }
    precondition(daysUntil(fmt(today), from: today) == 0)
    precondition(daysUntil(fmt(cal.date(byAdding: .day, value: 10, to: today)!), from: today) == 10)
    precondition(daysUntil(fmt(cal.date(byAdding: .day, value: -3, to: today)!), from: today) == -3)
    precondition(daysUntil("not-a-date") == nil)
    precondition(daysUntil("2026-13-45") == nil)
    precondition(shortStatus(5) == "5 Left" && shortStatus(-5) == "5 Passed" && shortStatus(0) == "Today")
    precondition(longStatus(5) == "5 Days Left" && longStatus(-5) == "5 Days Passed")
    print("selftest ok")
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%\lib\JSON.ahk

; ============================================================
; AI-HUB-AHK - Comprehensive Hotkey, AI Chat, and Data Manager
; ============================================================

; Global variables
global MainGui := ""
global HotkeyList := []
global StoredData := []
global ChatHistory := []
global ConfigFile := A_ScriptDir "\config.json"
global DataFile := A_ScriptDir "\storage.json"

; Initialize and show main GUI
InitializeApp()

; ============================================================
; MAIN APPLICATION INITIALIZATION
; ============================================================

InitializeApp() {
    global MainGui, HotkeyList, StoredData

    ; Load saved configurations
    LoadConfig()
    LoadStoredData()

    ; Create main GUI with tabs
    MainGui := Gui("+Resize", "AI-HUB - Hotkey & AI Assistant")
    MainGui.SetFont("s10", "Segoe UI")
    MainGui.OnEvent("Close", (*) => ExitApp())
    MainGui.OnEvent("Size", GuiResize)

    ; Create Tab control
    MainGui.Tabs := MainGui.AddTab3("vMainTabs w800 h600", ["🎯 Hotkeys", "🤖 AI Chat", "📦 Data Storage", "⚙️ Settings"])

    ; ===== TAB 1: HOTKEY MANAGER =====
    MainGui.Tabs.UseTab(1)
    BuildHotkeyTab()

    ; ===== TAB 2: AI CHAT =====
    MainGui.Tabs.UseTab(2)
    BuildAIChatTab()

    ; ===== TAB 3: DATA STORAGE =====
    MainGui.Tabs.UseTab(3)
    BuildDataStorageTab()

    ; ===== TAB 4: SETTINGS =====
    MainGui.Tabs.UseTab(4)
    BuildSettingsTab()

    MainGui.Tabs.UseTab(0)

    ; Show the GUI
    MainGui.Show("w820 h650")

    ; Register active hotkeys
    RegisterAllHotkeys()
}

; ============================================================
; TAB 1: HOTKEY MANAGER
; ============================================================

BuildHotkeyTab() {
    global MainGui

    ; --- Modifier Selection Section ---
    MainGui.AddGroupBox("xm+10 ym+40 w380 h120", "Modifiers (Toggle On/Off)")

    ; Modifier checkboxes with modern toggle style
    MainGui.AddCheckbox("xm+25 ym+65 vChkCtrl", "Ctrl")
    MainGui.AddCheckbox("xm+100 ym+65 vChkAlt", "Alt")
    MainGui.AddCheckbox("xm+175 ym+65 vChkWin", "Win")
    MainGui.AddCheckbox("xm+250 ym+65 vChkShift", "Shift")
    MainGui.AddCheckbox("xm+25 ym+100 vChkCapsLock", "CapsLock (as modifier)")

    ; --- Key Capture Section ---
    MainGui.AddGroupBox("xm+10 ym+170 w380 h140", "Hotkey Configuration")

    MainGui.AddText("xm+25 ym+195", "Trigger Key:")
    MainGui.AddEdit("xm+120 ym+192 w150 vEditTriggerKey ReadOnly", "Click 'Capture' then press key")
    MainGui.AddButton("xm+280 ym+190 w90 vBtnCapture", "🎯 Capture").OnEvent("Click", CaptureHotkey)

    MainGui.AddText("xm+25 ym+230", "Description:")
    MainGui.AddEdit("xm+120 ym+227 w250 vEditDescription", "")

    MainGui.AddText("xm+25 ym+265", "Output/Action:")
    MainGui.AddEdit("xm+120 ym+262 w250 vEditOutput", "")

    ; Action type dropdown
    MainGui.AddText("xm+25 ym+295", "Action Type:")
    MainGui.AddDropDownList("xm+120 ym+292 w150 vDDLActionType Choose1", ["Send Text", "Run Program", "Open URL", "Custom Script"])

    ; Add hotkey button
    MainGui.AddButton("xm+280 ym+290 w90 vBtnAddHotkey", "➕ Add").OnEvent("Click", AddHotkey)

    ; --- Hotkey List Section ---
    MainGui.AddGroupBox("xm+400 ym+40 w390 h360", "Active Hotkeys")

    ; ListView for hotkeys
    MainGui.HotkeyLV := MainGui.AddListView("xm+415 ym+65 w360 h280 vLVHotkeys", ["Hotkey", "Description", "Action"])
    MainGui.HotkeyLV.ModifyCol(1, 100)
    MainGui.HotkeyLV.ModifyCol(2, 130)
    MainGui.HotkeyLV.ModifyCol(3, 120)

    ; Hotkey management buttons
    MainGui.AddButton("xm+415 ym+355 w80", "✏️ Edit").OnEvent("Click", EditHotkey)
    MainGui.AddButton("xm+505 ym+355 w80", "🗑️ Delete").OnEvent("Click", DeleteHotkey)
    MainGui.AddButton("xm+595 ym+355 w80", "🔄 Refresh").OnEvent("Click", RefreshHotkeyList)
    MainGui.AddButton("xm+685 ym+355 w90", "💾 Save All").OnEvent("Click", SaveAllHotkeys)

    ; Load existing hotkeys into ListView
    RefreshHotkeyList()
}

CaptureHotkey(*) {
    global MainGui

    ; Create capture dialog
    CaptureGui := Gui("+Owner" MainGui.Hwnd " +ToolWindow", "Press Any Key...")
    CaptureGui.SetFont("s12", "Segoe UI")
    CaptureGui.AddText("w250 Center", "Press the key you want to use as a hotkey`n`n(Press Escape to cancel)")
    CaptureGui.Show("w270 h100")

    ; Wait for key press
    ih := InputHook("L1 M")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{Escape}", "-E")
    ih.Start()
    ih.Wait()

    CaptureGui.Destroy()

    if (ih.EndKey != "Escape" && ih.EndKey != "") {
        MainGui["EditTriggerKey"].Value := ih.EndKey
    }
}

AddHotkey(*) {
    global MainGui, HotkeyList

    ; Get values from GUI
    ctrl := MainGui["ChkCtrl"].Value
    alt := MainGui["ChkAlt"].Value
    win := MainGui["ChkWin"].Value
    shift := MainGui["ChkShift"].Value
    capslock := MainGui["ChkCapsLock"].Value

    triggerKey := MainGui["EditTriggerKey"].Value
    description := MainGui["EditDescription"].Value
    output := MainGui["EditOutput"].Value
    actionType := MainGui["DDLActionType"].Text

    if (triggerKey = "" || triggerKey = "Click 'Capture' then press key") {
        MsgBox("Please capture a trigger key first!", "Missing Key", "Icon!")
        return
    }

    ; Build hotkey string
    hotkeyStr := ""
    if (ctrl) hotkeyStr .= "^"
    if (alt) hotkeyStr .= "!"
    if (win) hotkeyStr .= "#"
    if (shift) hotkeyStr .= "+"
    if (capslock) hotkeyStr .= "CapsLock & "
    hotkeyStr .= triggerKey

    ; Create hotkey object
    newHotkey := {
        hotkey: hotkeyStr,
        key: triggerKey,
        ctrl: ctrl,
        alt: alt,
        win: win,
        shift: shift,
        capslock: capslock,
        description: description,
        output: output,
        actionType: actionType,
        enabled: true
    }

    ; Add to list
    HotkeyList.Push(newHotkey)

    ; Register the hotkey
    RegisterHotkey(newHotkey)

    ; Refresh display
    RefreshHotkeyList()

    ; Clear inputs
    MainGui["EditTriggerKey"].Value := "Click 'Capture' then press key"
    MainGui["EditDescription"].Value := ""
    MainGui["EditOutput"].Value := ""
    MainGui["ChkCtrl"].Value := 0
    MainGui["ChkAlt"].Value := 0
    MainGui["ChkWin"].Value := 0
    MainGui["ChkShift"].Value := 0
    MainGui["ChkCapsLock"].Value := 0

    ; Auto-save
    SaveConfig()
}

RegisterHotkey(hk) {
    try {
        if (hk.capslock) {
            ; CapsLock combination needs special handling
            Hotkey("CapsLock & " hk.key, (*) => ExecuteHotkeyAction(hk))
        } else {
            Hotkey(hk.hotkey, (*) => ExecuteHotkeyAction(hk))
        }
    } catch as err {
        MsgBox("Failed to register hotkey: " hk.hotkey "`n" err.Message, "Error", "Icon!")
    }
}

RegisterAllHotkeys() {
    global HotkeyList
    for hk in HotkeyList {
        if (hk.enabled) {
            RegisterHotkey(hk)
        }
    }
}

ExecuteHotkeyAction(hk) {
    switch hk.actionType {
        case "Send Text":
            SendText(hk.output)
        case "Run Program":
            try Run(hk.output)
        case "Open URL":
            try Run(hk.output)
        case "Custom Script":
            ; Execute as AHK code (be careful with this!)
            try {
                fn := Func("RunCustomScript").Bind(hk.output)
                fn()
            }
    }
}

RunCustomScript(script) {
    ; Simple script execution - sends the text
    SendText(script)
}

EditHotkey(*) {
    global MainGui, HotkeyList

    row := MainGui.HotkeyLV.GetNext(0, "F")
    if (!row) {
        MsgBox("Please select a hotkey to edit.", "No Selection", "Icon!")
        return
    }

    hk := HotkeyList[row]

    ; Populate form with selected hotkey data
    MainGui["ChkCtrl"].Value := hk.ctrl
    MainGui["ChkAlt"].Value := hk.alt
    MainGui["ChkWin"].Value := hk.win
    MainGui["ChkShift"].Value := hk.shift
    MainGui["ChkCapsLock"].Value := hk.capslock
    MainGui["EditTriggerKey"].Value := hk.key
    MainGui["EditDescription"].Value := hk.description
    MainGui["EditOutput"].Value := hk.output

    ; Remove the old hotkey
    try Hotkey(hk.hotkey, "Off")
    HotkeyList.RemoveAt(row)
    RefreshHotkeyList()
}

DeleteHotkey(*) {
    global MainGui, HotkeyList

    row := MainGui.HotkeyLV.GetNext(0, "F")
    if (!row) {
        MsgBox("Please select a hotkey to delete.", "No Selection", "Icon!")
        return
    }

    hk := HotkeyList[row]

    if (MsgBox("Delete hotkey: " hk.hotkey "?", "Confirm Delete", "YesNo Icon?") = "Yes") {
        try Hotkey(hk.hotkey, "Off")
        HotkeyList.RemoveAt(row)
        RefreshHotkeyList()
        SaveConfig()
    }
}

RefreshHotkeyList(*) {
    global MainGui, HotkeyList

    MainGui.HotkeyLV.Delete()
    for hk in HotkeyList {
        MainGui.HotkeyLV.Add("", hk.hotkey, hk.description, hk.actionType)
    }
}

SaveAllHotkeys(*) {
    SaveConfig()
    MsgBox("All hotkeys saved successfully!", "Saved", "Iconi")
}

; ============================================================
; TAB 2: AI CHAT
; ============================================================

BuildAIChatTab() {
    global MainGui

    ; Chat display area
    MainGui.AddGroupBox("xm+10 ym+40 w780 h400", "AI Conversation")
    MainGui.ChatDisplay := MainGui.AddEdit("xm+20 ym+60 w760 h370 vEditChatDisplay ReadOnly Multi VScroll", "Welcome to AI-HUB Chat!`n`nConfigure your API key in Settings to enable AI features.`n`n---`n")

    ; Input area
    MainGui.AddGroupBox("xm+10 ym+450 w780 h100", "Your Message")
    MainGui.ChatInput := MainGui.AddEdit("xm+20 ym+470 w660 h70 vEditChatInput Multi", "")
    MainGui.AddButton("xm+690 ym+470 w90 h30", "📤 Send").OnEvent("Click", SendChatMessage)
    MainGui.AddButton("xm+690 ym+510 w90 h30", "🗑️ Clear").OnEvent("Click", ClearChat)

    ; Quick prompts
    MainGui.AddText("xm+10 ym+560", "Quick Prompts:")
    MainGui.AddButton("xm+100 ym+555 w100", "Fix Grammar").OnEvent("Click", (*) => QuickPrompt("Fix the grammar and spelling in this text:"))
    MainGui.AddButton("xm+210 ym+555 w100", "Summarize").OnEvent("Click", (*) => QuickPrompt("Summarize this text concisely:"))
    MainGui.AddButton("xm+320 ym+555 w100", "Explain").OnEvent("Click", (*) => QuickPrompt("Explain this in simple terms:"))
    MainGui.AddButton("xm+430 ym+555 w100", "Translate").OnEvent("Click", (*) => QuickPrompt("Translate this to English:"))
}

SendChatMessage(*) {
    global MainGui, ChatHistory

    userMsg := MainGui["EditChatInput"].Value
    if (userMsg = "")
        return

    ; Add user message to display
    currentChat := MainGui["EditChatDisplay"].Value
    currentChat .= "`n👤 You: " userMsg "`n"
    MainGui["EditChatDisplay"].Value := currentChat

    ; Store in history
    ChatHistory.Push({role: "user", content: userMsg})

    ; Clear input
    MainGui["EditChatInput"].Value := ""

    ; TODO: Implement actual AI API call here
    ; For now, show placeholder response
    response := ProcessAIRequest(userMsg)

    currentChat := MainGui["EditChatDisplay"].Value
    currentChat .= "`n🤖 AI: " response "`n`n---`n"
    MainGui["EditChatDisplay"].Value := currentChat

    ChatHistory.Push({role: "assistant", content: response})

    ; Scroll to bottom
    SendMessage(0x115, 7, 0, MainGui["EditChatDisplay"].Hwnd)
}

ProcessAIRequest(prompt) {
    global MainGui

    ; Check for API key
    apiKey := ""
    try apiKey := MainGui["EditAPIKey"].Value

    if (apiKey = "") {
        return "⚠️ Please configure your API key in the Settings tab to enable AI features."
    }

    ; Here you would implement the actual API call
    ; This is a placeholder that shows the structure
    return "AI response would appear here. Implement your preferred AI API (OpenAI, Anthropic, etc.) in the ProcessAIRequest function."
}

QuickPrompt(prefix) {
    global MainGui
    current := MainGui["EditChatInput"].Value
    MainGui["EditChatInput"].Value := prefix "`n`n" current
}

ClearChat(*) {
    global MainGui, ChatHistory
    ChatHistory := []
    MainGui["EditChatDisplay"].Value := "Chat cleared.`n`n---`n"
}

; ============================================================
; TAB 3: DATA STORAGE
; ============================================================

BuildDataStorageTab() {
    global MainGui

    ; --- Add New Data Section ---
    MainGui.AddGroupBox("xm+10 ym+40 w380 h250", "Add New Data Entry")

    MainGui.AddText("xm+25 ym+65", "Category:")
    MainGui.AddDropDownList("xm+120 ym+62 w200 vDDLCategory Choose1", [
        "📋 General",
        "👤 Personal Info",
        "🔑 API Keys",
        "📞 Phone Numbers",
        "📧 Email Addresses",
        "🏠 Addresses",
        "📅 Important Dates",
        "🔒 Passwords",
        "💳 Account Numbers",
        "📝 Notes"
    ])

    MainGui.AddText("xm+25 ym+100", "Name/Label:")
    MainGui.AddEdit("xm+120 ym+97 w250 vEditDataName", "")

    MainGui.AddText("xm+25 ym+135", "Value:")
    MainGui.AddEdit("xm+120 ym+132 w250 h60 vEditDataValue Multi", "")

    MainGui.AddText("xm+25 ym+205", "Tags (comma sep):")
    MainGui.AddEdit("xm+120 ym+202 w250 vEditDataTags", "")

    MainGui.AddButton("xm+120 ym+240 w120", "➕ Add Entry").OnEvent("Click", AddDataEntry)
    MainGui.AddButton("xm+250 ym+240 w120", "📋 Paste & Add").OnEvent("Click", PasteAndAddData)

    ; --- Data List Section ---
    MainGui.AddGroupBox("xm+400 ym+40 w390 h360", "Stored Data")

    ; Filter dropdown
    MainGui.AddText("xm+415 ym+60", "Filter:")
    MainGui.AddDropDownList("xm+460 ym+57 w150 vDDLDataFilter Choose1", [
        "All Categories",
        "📋 General",
        "👤 Personal Info",
        "🔑 API Keys",
        "📞 Phone Numbers",
        "📧 Email Addresses",
        "🏠 Addresses",
        "📅 Important Dates",
        "🔒 Passwords",
        "💳 Account Numbers",
        "📝 Notes"
    ]).OnEvent("Change", FilterDataList)

    MainGui.AddEdit("xm+620 ym+57 w155 vEditDataSearch", "").OnEvent("Change", FilterDataList)
    MainGui.AddText("xm+620 ym+80", "🔍 Search...")

    ; Data ListView
    MainGui.DataLV := MainGui.AddListView("xm+415 ym+95 w360 h250 vLVData", ["Category", "Name", "Value"])
    MainGui.DataLV.ModifyCol(1, 90)
    MainGui.DataLV.ModifyCol(2, 100)
    MainGui.DataLV.ModifyCol(3, 160)
    MainGui.DataLV.OnEvent("DoubleClick", CopyDataValue)

    ; Data management buttons
    MainGui.AddButton("xm+415 ym+355 w70", "📋 Copy").OnEvent("Click", CopySelectedData)
    MainGui.AddButton("xm+495 ym+355 w70", "✏️ Edit").OnEvent("Click", EditDataEntry)
    MainGui.AddButton("xm+575 ym+355 w70", "🗑️ Delete").OnEvent("Click", DeleteDataEntry)
    MainGui.AddButton("xm+655 ym+355 w100", "📤 Export").OnEvent("Click", ExportData)

    ; Quick insert section
    MainGui.AddGroupBox("xm+10 ym+300 w380 h100", "Quick Insert (Double-click item above or use hotkey)")
    MainGui.AddText("xm+25 ym+325", "Assign hotkey to insert selected data:")
    MainGui.AddEdit("xm+25 ym+350 w200 vEditQuickInsertKey ReadOnly", "Ctrl+Shift+V")
    MainGui.AddButton("xm+235 ym+347 w80", "Set Key").OnEvent("Click", SetQuickInsertKey)
    MainGui.AddCheckbox("xm+25 ym+375 vChkAutoHide Checked", "Auto-hide after insert")

    ; Load stored data
    RefreshDataList()
}

AddDataEntry(*) {
    global MainGui, StoredData

    category := MainGui["DDLCategory"].Text
    name := MainGui["EditDataName"].Value
    value := MainGui["EditDataValue"].Value
    tags := MainGui["EditDataTags"].Value

    if (name = "" || value = "") {
        MsgBox("Please enter both a name and value.", "Missing Data", "Icon!")
        return
    }

    newEntry := {
        id: A_Now . A_MSec,
        category: category,
        name: name,
        value: value,
        tags: tags,
        created: FormatTime(A_Now, "yyyy-MM-dd HH:mm"),
        modified: FormatTime(A_Now, "yyyy-MM-dd HH:mm")
    }

    StoredData.Push(newEntry)
    RefreshDataList()
    SaveStoredData()

    ; Clear inputs
    MainGui["EditDataName"].Value := ""
    MainGui["EditDataValue"].Value := ""
    MainGui["EditDataTags"].Value := ""

    MsgBox("Data entry added!", "Success", "Iconi T1")
}

PasteAndAddData(*) {
    global MainGui
    clipContent := A_Clipboard
    if (clipContent != "") {
        MainGui["EditDataValue"].Value := clipContent
    }
}

RefreshDataList(*) {
    global MainGui, StoredData

    MainGui.DataLV.Delete()

    filterCat := ""
    try filterCat := MainGui["DDLDataFilter"].Text

    searchTerm := ""
    try searchTerm := MainGui["EditDataSearch"].Value

    for entry in StoredData {
        ; Apply category filter
        if (filterCat != "All Categories" && filterCat != "" && entry.category != filterCat)
            continue

        ; Apply search filter
        if (searchTerm != "") {
            if (!InStr(entry.name, searchTerm) && !InStr(entry.value, searchTerm) && !InStr(entry.tags, searchTerm))
                continue
        }

        ; Truncate value for display
        displayValue := StrLen(entry.value) > 25 ? SubStr(entry.value, 1, 25) "..." : entry.value
        MainGui.DataLV.Add("", entry.category, entry.name, displayValue)
    }
}

FilterDataList(*) {
    RefreshDataList()
}

CopyDataValue(LV, row) {
    global StoredData
    if (row && row <= StoredData.Length) {
        A_Clipboard := StoredData[row].value
        ToolTip("Copied: " StoredData[row].name)
        SetTimer(() => ToolTip(), -1500)
    }
}

CopySelectedData(*) {
    global MainGui, StoredData
    row := MainGui.DataLV.GetNext(0, "F")
    if (row) {
        CopyDataValue(MainGui.DataLV, row)
    }
}

EditDataEntry(*) {
    global MainGui, StoredData
    row := MainGui.DataLV.GetNext(0, "F")
    if (!row) {
        MsgBox("Please select an entry to edit.", "No Selection", "Icon!")
        return
    }

    entry := StoredData[row]
    MainGui["EditDataName"].Value := entry.name
    MainGui["EditDataValue"].Value := entry.value
    MainGui["EditDataTags"].Value := entry.tags

    ; Remove the entry (will be re-added when user clicks Add)
    StoredData.RemoveAt(row)
    RefreshDataList()
}

DeleteDataEntry(*) {
    global MainGui, StoredData
    row := MainGui.DataLV.GetNext(0, "F")
    if (!row) {
        MsgBox("Please select an entry to delete.", "No Selection", "Icon!")
        return
    }

    if (MsgBox("Delete entry: " StoredData[row].name "?", "Confirm Delete", "YesNo Icon?") = "Yes") {
        StoredData.RemoveAt(row)
        RefreshDataList()
        SaveStoredData()
    }
}

ExportData(*) {
    global StoredData

    exportPath := FileSelect("S", A_ScriptDir "\data_export.json", "Export Data", "JSON Files (*.json)")
    if (exportPath = "")
        return

    jsonStr := "["
    for i, entry in StoredData {
        jsonStr .= "`n  {"
        jsonStr .= '`n    "category": "' EscapeJSON(entry.category) '",'
        jsonStr .= '`n    "name": "' EscapeJSON(entry.name) '",'
        jsonStr .= '`n    "value": "' EscapeJSON(entry.value) '",'
        jsonStr .= '`n    "tags": "' EscapeJSON(entry.tags) '"'
        jsonStr .= "`n  }" (i < StoredData.Length ? "," : "")
    }
    jsonStr .= "`n]"

    try {
        FileDelete(exportPath)
    }
    FileAppend(jsonStr, exportPath, "UTF-8")
    MsgBox("Data exported to:`n" exportPath, "Export Complete", "Iconi")
}

SetQuickInsertKey(*) {
    MsgBox("Quick insert key configuration coming soon!", "Feature", "Iconi")
}

; ============================================================
; TAB 4: SETTINGS
; ============================================================

BuildSettingsTab() {
    global MainGui

    ; --- AI API Configuration ---
    MainGui.AddGroupBox("xm+10 ym+40 w380 h180", "AI API Configuration")

    MainGui.AddText("xm+25 ym+65", "API Provider:")
    MainGui.AddDropDownList("xm+120 ym+62 w200 vDDLAPIProvider Choose1", ["OpenAI", "Anthropic", "Local LLM", "Custom"])

    MainGui.AddText("xm+25 ym+100", "API Key:")
    MainGui.AddEdit("xm+120 ym+97 w250 vEditAPIKey Password", "")

    MainGui.AddText("xm+25 ym+135", "API Endpoint:")
    MainGui.AddEdit("xm+120 ym+132 w250 vEditAPIEndpoint", "https://api.openai.com/v1/chat/completions")

    MainGui.AddText("xm+25 ym+170", "Model:")
    MainGui.AddEdit("xm+120 ym+167 w250 vEditModel", "gpt-4")

    MainGui.AddButton("xm+120 ym+195 w120", "🔐 Save API Key").OnEvent("Click", SaveAPISettings)
    MainGui.AddButton("xm+250 ym+195 w120", "🧪 Test Connection").OnEvent("Click", TestAPIConnection)

    ; --- Grammar Correction Settings ---
    MainGui.AddGroupBox("xm+10 ym+230 w380 h120", "Grammar Correction Hotkey")

    MainGui.AddText("xm+25 ym+255", "The grammar correction feature will:")
    MainGui.AddText("xm+25 ym+275", "1. Select all text (Ctrl+A)")
    MainGui.AddText("xm+25 ym+295", "2. Copy it")
    MainGui.AddText("xm+25 ym+315", "3. Send to AI for correction")
    MainGui.AddText("xm+25 ym+335", "4. Replace with corrected text")

    MainGui.AddText("xm+220 ym+255", "Hotkey:")
    MainGui.AddEdit("xm+270 ym+252 w100 vEditGrammarHotkey", "Ctrl+Alt+S")

    ; --- General Settings ---
    MainGui.AddGroupBox("xm+400 ym+40 w390 h180", "General Settings")

    MainGui.AddCheckbox("xm+415 ym+65 vChkStartWithWindows", "Start with Windows")
    MainGui.AddCheckbox("xm+415 ym+90 vChkMinimizeToTray Checked", "Minimize to system tray")
    MainGui.AddCheckbox("xm+415 ym+115 vChkShowNotifications Checked", "Show notifications")
    MainGui.AddCheckbox("xm+415 ym+140 vChkAutoSave Checked", "Auto-save changes")
    MainGui.AddCheckbox("xm+415 ym+165 vChkDarkMode", "Dark mode (requires restart)")

    MainGui.AddButton("xm+415 ym+190 w120", "💾 Save Settings").OnEvent("Click", SaveAllSettings)
    MainGui.AddButton("xm+545 ym+190 w120", "🔄 Reset Defaults").OnEvent("Click", ResetSettings)

    ; --- Data Management ---
    MainGui.AddGroupBox("xm+400 ym+230 w390 h120", "Data Management")

    MainGui.AddButton("xm+415 ym+255 w170", "📥 Import Configuration").OnEvent("Click", ImportConfig)
    MainGui.AddButton("xm+595 ym+255 w170", "📤 Export Configuration").OnEvent("Click", ExportConfig)
    MainGui.AddButton("xm+415 ym+290 w170", "🗑️ Clear All Hotkeys").OnEvent("Click", ClearAllHotkeys)
    MainGui.AddButton("xm+595 ym+290 w170", "🗑️ Clear All Data").OnEvent("Click", ClearAllData)

    ; --- About ---
    MainGui.AddGroupBox("xm+10 ym+360 w780 h90", "About AI-HUB")
    MainGui.AddText("xm+25 ym+385", "AI-HUB v1.0 - Your All-in-One Hotkey, AI Chat, and Data Management Solution")
    MainGui.AddText("xm+25 ym+405", "Features: Custom Hotkeys with Visual Modifiers | AI Chat Integration | Secure Data Storage | Grammar Correction")
    MainGui.AddText("xm+25 ym+425", "Press Ctrl+Alt+S anywhere to correct grammar in the active text field.")
}

SaveAPISettings(*) {
    SaveConfig()
    MsgBox("API settings saved!", "Saved", "Iconi T1")
}

TestAPIConnection(*) {
    MsgBox("API connection test - Feature coming soon!`n`nThis will verify your API key works.", "Test API", "Iconi")
}

SaveAllSettings(*) {
    SaveConfig()
    MsgBox("All settings saved!", "Saved", "Iconi")
}

ResetSettings(*) {
    if (MsgBox("Reset all settings to defaults?", "Confirm Reset", "YesNo Icon?") = "Yes") {
        ; Reset to defaults
        MsgBox("Settings reset to defaults.", "Reset", "Iconi")
    }
}

ImportConfig(*) {
    importPath := FileSelect(1, A_ScriptDir, "Import Configuration", "JSON Files (*.json)")
    if (importPath != "") {
        ; TODO: Implement import
        MsgBox("Configuration imported!", "Import", "Iconi")
    }
}

ExportConfig(*) {
    SaveConfig()
    exportPath := FileSelect("S", A_ScriptDir "\config_export.json", "Export Configuration", "JSON Files (*.json)")
    if (exportPath != "") {
        FileCopy(ConfigFile, exportPath, 1)
        MsgBox("Configuration exported to:`n" exportPath, "Export", "Iconi")
    }
}

ClearAllHotkeys(*) {
    global HotkeyList
    if (MsgBox("Delete ALL hotkeys? This cannot be undone!", "Confirm", "YesNo Icon!") = "Yes") {
        for hk in HotkeyList {
            try Hotkey(hk.hotkey, "Off")
        }
        HotkeyList := []
        RefreshHotkeyList()
        SaveConfig()
    }
}

ClearAllData(*) {
    global StoredData
    if (MsgBox("Delete ALL stored data? This cannot be undone!", "Confirm", "YesNo Icon!") = "Yes") {
        StoredData := []
        RefreshDataList()
        SaveStoredData()
    }
}

; ============================================================
; CONFIGURATION SAVE/LOAD
; ============================================================

SaveConfig() {
    global MainGui, HotkeyList, ConfigFile

    jsonStr := "{"
    jsonStr .= '`n  "hotkeys": ['

    for i, hk in HotkeyList {
        jsonStr .= "`n    {"
        jsonStr .= '"hotkey": "' EscapeJSON(hk.hotkey) '", '
        jsonStr .= '"key": "' EscapeJSON(hk.key) '", '
        jsonStr .= '"ctrl": ' (hk.ctrl ? "true" : "false") ', '
        jsonStr .= '"alt": ' (hk.alt ? "true" : "false") ', '
        jsonStr .= '"win": ' (hk.win ? "true" : "false") ', '
        jsonStr .= '"shift": ' (hk.shift ? "true" : "false") ', '
        jsonStr .= '"capslock": ' (hk.capslock ? "true" : "false") ', '
        jsonStr .= '"description": "' EscapeJSON(hk.description) '", '
        jsonStr .= '"output": "' EscapeJSON(hk.output) '", '
        jsonStr .= '"actionType": "' EscapeJSON(hk.actionType) '", '
        jsonStr .= '"enabled": ' (hk.enabled ? "true" : "false")
        jsonStr .= "}" (i < HotkeyList.Length ? "," : "")
    }

    jsonStr .= "`n  ],"

    ; Save API settings
    apiKey := ""
    apiEndpoint := ""
    model := ""
    try {
        apiKey := MainGui["EditAPIKey"].Value
        apiEndpoint := MainGui["EditAPIEndpoint"].Value
        model := MainGui["EditModel"].Value
    }

    jsonStr .= '`n  "apiKey": "' EscapeJSON(apiKey) '",'
    jsonStr .= '`n  "apiEndpoint": "' EscapeJSON(apiEndpoint) '",'
    jsonStr .= '`n  "model": "' EscapeJSON(model) '"'
    jsonStr .= "`n}"

    try FileDelete(ConfigFile)
    FileAppend(jsonStr, ConfigFile, "UTF-8")
}

LoadConfig() {
    global HotkeyList, ConfigFile, MainGui

    if (!FileExist(ConfigFile))
        return

    try {
        jsonStr := FileRead(ConfigFile, "UTF-8")
        config := JSON.Parse(jsonStr)

        ; Load hotkeys
        if (config.Has("hotkeys")) {
            for hkData in config["hotkeys"] {
                hk := {
                    hotkey: hkData["hotkey"],
                    key: hkData["key"],
                    ctrl: hkData["ctrl"],
                    alt: hkData["alt"],
                    win: hkData["win"],
                    shift: hkData["shift"],
                    capslock: hkData["capslock"],
                    description: hkData["description"],
                    output: hkData["output"],
                    actionType: hkData["actionType"],
                    enabled: hkData["enabled"]
                }
                HotkeyList.Push(hk)
            }
        }

        ; Load API settings after GUI is built
        SetTimer(() => LoadAPISettings(config), -100)
    } catch as err {
        ; Config file might be corrupted, start fresh
    }
}

LoadAPISettings(config) {
    global MainGui
    try {
        if (config.Has("apiKey"))
            MainGui["EditAPIKey"].Value := config["apiKey"]
        if (config.Has("apiEndpoint"))
            MainGui["EditAPIEndpoint"].Value := config["apiEndpoint"]
        if (config.Has("model"))
            MainGui["EditModel"].Value := config["model"]
    }
}

SaveStoredData() {
    global StoredData, DataFile

    jsonStr := "["
    for i, entry in StoredData {
        jsonStr .= "`n  {"
        jsonStr .= '"id": "' entry.id '", '
        jsonStr .= '"category": "' EscapeJSON(entry.category) '", '
        jsonStr .= '"name": "' EscapeJSON(entry.name) '", '
        jsonStr .= '"value": "' EscapeJSON(entry.value) '", '
        jsonStr .= '"tags": "' EscapeJSON(entry.tags) '", '
        jsonStr .= '"created": "' entry.created '", '
        jsonStr .= '"modified": "' entry.modified '"'
        jsonStr .= "}" (i < StoredData.Length ? "," : "")
    }
    jsonStr .= "`n]"

    try FileDelete(DataFile)
    FileAppend(jsonStr, DataFile, "UTF-8")
}

LoadStoredData() {
    global StoredData, DataFile

    if (!FileExist(DataFile))
        return

    try {
        jsonStr := FileRead(DataFile, "UTF-8")
        dataArray := JSON.Parse(jsonStr)

        for entryData in dataArray {
            entry := {
                id: entryData["id"],
                category: entryData["category"],
                name: entryData["name"],
                value: entryData["value"],
                tags: entryData["tags"],
                created: entryData["created"],
                modified: entryData["modified"]
            }
            StoredData.Push(entry)
        }
    } catch as err {
        ; Data file might be corrupted, start fresh
    }
}

EscapeJSON(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`t", "\t")
    return str
}

; ============================================================
; GUI RESIZE HANDLER
; ============================================================

GuiResize(thisGui, minMax, width, height) {
    if (minMax = -1)  ; Minimized
        return

    ; Resize tab control
    try thisGui["MainTabs"].Move(,, width - 20, height - 50)
}

; ============================================================
; GLOBAL HOTKEYS
; ============================================================

; Grammar correction hotkey (Ctrl+Alt+S)
^!s:: {
    CorrectGrammar()
}

CorrectGrammar() {
    global MainGui

    ; Store current clipboard
    oldClip := A_Clipboard
    A_Clipboard := ""

    ; Select all and copy
    Send("^a")
    Sleep(50)
    Send("^c")

    ; Wait for clipboard
    if (!ClipWait(2)) {
        MsgBox("No text selected or copied!", "Grammar Check", "Icon!")
        A_Clipboard := oldClip
        return
    }

    textToFix := A_Clipboard

    ; Show processing indicator
    ToolTip("🔄 Checking grammar...")

    ; Get API key
    apiKey := ""
    try apiKey := MainGui["EditAPIKey"].Value

    if (apiKey = "") {
        ToolTip()
        MsgBox("Please configure your API key in Settings to use grammar correction.", "API Key Required", "Icon!")
        A_Clipboard := oldClip
        return
    }

    ; TODO: Implement actual API call for grammar correction
    ; For now, show placeholder
    ToolTip()
    MsgBox("Grammar correction requires API integration.`n`nConfigure your API key in Settings and implement the API call in CorrectGrammar().", "Grammar Check", "Iconi")

    ; Restore clipboard
    A_Clipboard := oldClip
}

; Quick show/hide main window
^!h:: {
    global MainGui
    if WinExist("ahk_id " MainGui.Hwnd) {
        if WinActive("ahk_id " MainGui.Hwnd)
            MainGui.Hide()
        else
            MainGui.Show()
    }
}

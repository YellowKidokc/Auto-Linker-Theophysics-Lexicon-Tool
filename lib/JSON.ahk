#Requires AutoHotkey v2.0

; ============================================================
; Simple JSON Parser/Serializer for AutoHotkey v2
; ============================================================

class JSON {
    ; Parse JSON string to AHK object
    static Parse(jsonStr) {
        jsonStr := Trim(jsonStr)

        if (SubStr(jsonStr, 1, 1) = "{")
            return JSON._ParseObject(&jsonStr)
        else if (SubStr(jsonStr, 1, 1) = "[")
            return JSON._ParseArray(&jsonStr)
        else
            return JSON._ParseValue(&jsonStr)
    }

    static _ParseObject(&str) {
        obj := Map()
        str := LTrim(SubStr(str, 2))  ; Remove opening {

        while (str != "" && SubStr(str, 1, 1) != "}") {
            ; Skip whitespace and commas
            str := LTrim(str)
            if (SubStr(str, 1, 1) = ",") {
                str := LTrim(SubStr(str, 2))
            }
            if (SubStr(str, 1, 1) = "}")
                break

            ; Parse key
            key := JSON._ParseString(&str)
            str := LTrim(str)

            ; Skip colon
            if (SubStr(str, 1, 1) = ":")
                str := LTrim(SubStr(str, 2))

            ; Parse value
            value := JSON._ParseValue(&str)
            obj[key] := value
        }

        ; Remove closing }
        if (SubStr(str, 1, 1) = "}")
            str := SubStr(str, 2)

        return obj
    }

    static _ParseArray(&str) {
        arr := []
        str := LTrim(SubStr(str, 2))  ; Remove opening [

        while (str != "" && SubStr(str, 1, 1) != "]") {
            ; Skip whitespace and commas
            str := LTrim(str)
            if (SubStr(str, 1, 1) = ",") {
                str := LTrim(SubStr(str, 2))
            }
            if (SubStr(str, 1, 1) = "]")
                break

            ; Parse value
            value := JSON._ParseValue(&str)
            arr.Push(value)
        }

        ; Remove closing ]
        if (SubStr(str, 1, 1) = "]")
            str := SubStr(str, 2)

        return arr
    }

    static _ParseValue(&str) {
        str := LTrim(str)
        char := SubStr(str, 1, 1)

        if (char = '"')
            return JSON._ParseString(&str)
        else if (char = "{")
            return JSON._ParseObject(&str)
        else if (char = "[")
            return JSON._ParseArray(&str)
        else if (char = "t" && SubStr(str, 1, 4) = "true") {
            str := SubStr(str, 5)
            return true
        }
        else if (char = "f" && SubStr(str, 1, 5) = "false") {
            str := SubStr(str, 6)
            return false
        }
        else if (char = "n" && SubStr(str, 1, 4) = "null") {
            str := SubStr(str, 5)
            return ""
        }
        else
            return JSON._ParseNumber(&str)
    }

    static _ParseString(&str) {
        ; Skip opening quote
        str := SubStr(str, 2)
        result := ""
        i := 1

        while (i <= StrLen(str)) {
            char := SubStr(str, i, 1)

            if (char = '"') {
                str := SubStr(str, i + 1)
                return result
            }
            else if (char = "\") {
                i++
                nextChar := SubStr(str, i, 1)
                switch nextChar {
                    case "n": result .= "`n"
                    case "r": result .= "`r"
                    case "t": result .= "`t"
                    case '"': result .= '"'
                    case "\": result .= "\"
                    case "/": result .= "/"
                    default: result .= nextChar
                }
            }
            else {
                result .= char
            }
            i++
        }

        return result
    }

    static _ParseNumber(&str) {
        numStr := ""
        i := 1

        while (i <= StrLen(str)) {
            char := SubStr(str, i, 1)
            if (RegExMatch(char, "[\d\.\-\+eE]"))
                numStr .= char
            else
                break
            i++
        }

        str := SubStr(str, i)
        return Number(numStr)
    }

    ; Stringify AHK object to JSON
    static Stringify(obj, indent := "") {
        if (obj is Array)
            return JSON._StringifyArray(obj, indent)
        else if (obj is Map)
            return JSON._StringifyMap(obj, indent)
        else if (IsObject(obj))
            return JSON._StringifyObject(obj, indent)
        else if (obj is String)
            return '"' JSON._EscapeString(obj) '"'
        else if (obj = true)
            return "true"
        else if (obj = false)
            return "false"
        else if (obj = "")
            return "null"
        else
            return String(obj)
    }

    static _StringifyArray(arr, indent := "") {
        if (arr.Length = 0)
            return "[]"

        newIndent := indent . "  "
        items := []

        for value in arr {
            items.Push(newIndent . JSON.Stringify(value, newIndent))
        }

        return "[`n" . JSON._Join(items, ",`n") . "`n" . indent . "]"
    }

    static _StringifyMap(map, indent := "") {
        if (map.Count = 0)
            return "{}"

        newIndent := indent . "  "
        items := []

        for key, value in map {
            items.Push(newIndent . '"' . JSON._EscapeString(String(key)) . '": ' . JSON.Stringify(value, newIndent))
        }

        return "{`n" . JSON._Join(items, ",`n") . "`n" . indent . "}"
    }

    static _StringifyObject(obj, indent := "") {
        newIndent := indent . "  "
        items := []

        for key, value in obj.OwnProps() {
            items.Push(newIndent . '"' . JSON._EscapeString(String(key)) . '": ' . JSON.Stringify(value, newIndent))
        }

        if (items.Length = 0)
            return "{}"

        return "{`n" . JSON._Join(items, ",`n") . "`n" . indent . "}"
    }

    static _EscapeString(str) {
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, '"', '\"')
        str := StrReplace(str, "`n", "\n")
        str := StrReplace(str, "`r", "\r")
        str := StrReplace(str, "`t", "\t")
        return str
    }

    static _Join(arr, sep) {
        result := ""
        for i, item in arr {
            if (i > 1)
                result .= sep
            result .= item
        }
        return result
    }
}

-- utils/FilePicker.lua
-- Cross-platform async file picker using native system dialogs.
local mp = require 'mp'

local FilePicker = {}

local function get_platform()
    local platform = mp.get_property_native("platform")
    if platform == "windows" then return "windows" end
    if platform == "darwin"  then return "macos"   end
    return "linux"
end

-- Build the subprocess args for each platform
local function picker_args()
    local plat = get_platform()

    if plat == "windows" then
        return {
            "powershell", "-NoProfile", "-Command",
            [[
Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Title  = 'Select a video file'
$dlg.Filter = 'Video files|*.mp4;*.mkv;*.avi;*.webm;*.mov;*.flv;*.wmv;*.m4v;*.ts;*.mpg;*.mpeg|All files|*.*'
if ($dlg.ShowDialog() -eq 'OK') { $dlg.FileName }
]]
        }
    elseif plat == "macos" then
        return {
            "osascript", "-e",
            'POSIX path of (choose file of type {"public.movie"} with prompt "Select a video file")'
        }
    else
        -- Linux: try zenity first, kdialog as fallback is handled by the caller
        return {
            "zenity", "--file-selection",
            "--title=Select a video file",
            "--file-filter=Video files|*.mp4 *.mkv *.avi *.webm *.mov *.flv *.wmv *.m4v *.ts *.mpg *.mpeg",
            "--file-filter=All files|*"
        }
    end
end

--- Open a native file picker dialog asynchronously.
--- @param callback fun(path: string|nil)  Called with the selected path, or nil if cancelled.
function FilePicker.open(callback)
    local args = picker_args()

    mp.command_native_async({
        name = "subprocess",
        args = args,
        capture_stdout = true,
        playback_only = false,
    }, function(success, result)
        if success and result.status == 0 then
            local path = (result.stdout or ""):match("^%s*(.-)%s*$")  -- trim
            if path and path ~= "" then
                callback(path)
                return
            end
        end
        callback(nil)
    end)
end

return FilePicker

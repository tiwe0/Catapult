extends Node


const _SETTINGS_FILENAME = "catapult_settings.json"

const _HARDCODED_DEFAULTS = {
    "game": "dda",
    "channel": "stable",  # Currently used only for DDA.
    "active_install_dda": "Cataclysm-DDA experimental build 2022-07-26-0606",
    "active_install_bn": "",
    "update_current_when_installing": true,
    "launcher_locale": "zh",
    "launcher_theme": "Godot_3.res",
    "window_state": {},
    "print_tips_of_the_day": true,
    "update_to_same_build_allowed": false,
    "shorten_release_names": false,
    "always_show_installs": false,
    "num_releases_to_request": 10,
    "num_prs_to_request": 50,
    "ui_scale_override": 1.0,
    "ui_scale_override_enabled": true,
    "show_stock_mods": false,
    "show_installed_mods_in_available": false,
    "show_obsolete_mods": false,
    "install_archived_mods": false,
    "show_stock_sound": false,
    "font_preview_cyrillic": false,
    "show_game_desc": true,
    "keep_open_after_starting_game": true,
    "debug_mode": false,
}

var _settings_file = ""
var _current = {}


func _exit_tree() -> void:
    _write_to_file(_current, _settings_file)


func _load() -> void:
    
    _settings_file = Paths.own_dir + str(_SETTINGS_FILENAME)
    
    if FileAccess.file_exists(_settings_file):
        _current = _read_from_file(_settings_file)
        
    else:
        _current = _HARDCODED_DEFAULTS
        Status.post(tr("msg_creating_settings") % _SETTINGS_FILENAME)
        _write_to_file(_HARDCODED_DEFAULTS, _settings_file)


func _read_from_file(path: String) -> Dictionary:
    
    var json = JSON.new()
    var f = FileAccess.open(path, FileAccess.READ)
    
    if not FileAccess.file_exists(path):
        Status.post(tr("msg_nonexistent_attempt") % path, Enums.MSG_ERROR)
        return {}
        
    Status.post(tr("msg_loading_settings") % _SETTINGS_FILENAME)
        
    var s = f.get_as_text()
    var error = json.parse(s)
    
    if error == OK:
        return json.data
    else:
        Status.post(tr("msg_settings_parse_error") % [json.get_error_line, json.get_error_string], Enums.MSG_ERROR)
        return {}


func _write_to_file(data: Dictionary, path: String) -> void:
    
    var f = FileAccess.open(path, FileAccess.WRITE)
    var content = JSON.stringify(data, "    ")
    f.store_string(content)
    f.close()


func read(setting_name: String):
    
    if len(_current) == 0:
        _load()
    
    if not setting_name in _current:
        if setting_name in _HARDCODED_DEFAULTS:
            _current[setting_name] = _HARDCODED_DEFAULTS[setting_name]
        else:
            Status.post(tr("msg_nonexisting_setting") % setting_name, Enums.MSG_ERROR)
            return null
    
    return _current[setting_name]


func store(setting_name: String, setting_value) -> void:
    
    _current[setting_name] = setting_value

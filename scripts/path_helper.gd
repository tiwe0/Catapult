extends Node
# This is a cetralized place for all path resolution logic.


signal status_message

var own_dir: String : get =  _get_own_dir
var installs_summary: Dictionary : get =  _get_installs_summary
var game_dir: String : get =  _get_game_dir
var next_install_dir: String : get =  _get_next_install_dir
var userdata: String : get =  _get_userdata_dir
var config: String : get =  _get_config_dir
var savegames: String : get =  _get_savegame_dir
var mods_stock: String : get =  _get_mods_dir_default
var mods_user: String : get =  _get_mods_dir_user
var sound_stock: String : get =  _get_sound_dir_default
var sound_user: String : get =  _get_sound_dir_user
var gfx_default: String : get =  _get_gfx_dir_default
var gfx_user: String : get =  _get_gfx_dir_user
var font_user: String : get =  _get_font_dir_user
var templates: String : get =  _get_templates_dir
var memorial: String : get =  _get_memorial_dir
var graveyard: String : get =  _get_graveyard_dir
var mod_repo: String : get =  _get_modrepo_dir
var tmp_dir: String : get =  _get_tmp_dir
var utils_dir: String : get =  _get_utils_dir
var save_backups: String : get =  _get_save_backups_dir

var _last_active_install_name := ""
var _last_active_install_dir := ""


func _get_own_dir() -> String:
    
    return OS.get_executable_path().get_base_dir()


func _get_installs_summary() -> Dictionary:
    
    var result = {}
    
    for game in ["dda", "bn"]:
        var installs = {}
        var base_dir = Paths.own_dir + str(game)
        for subdir in FS.list_dir(base_dir):
            var info_file = base_dir + str(subdir) + str(Helpers.INFO_FILENAME)
            if DirAccess.dir_exists_absolute(info_file):
                var info = Helpers.load_json_file(info_file)
                installs[info["name"]] = base_dir + str(subdir)
        if not installs.is_empty():
            result[game] = installs
    
    # Ensure that some installation of the game is set as active
    var game = Settings.read("game")
    var active_name = Settings.read("active_install_" + game)
    if game in result:
        if (active_name == "") or (not active_name in result[game]):
            Settings.store("active_install_" + game, result[game].keys()[0])
    
    return result


func _get_game_dir() -> String:

    var active_name = Settings.read("active_install_" + Settings.read("game"))
    
    if active_name == "":
        return _get_next_install_dir()
    elif active_name == _last_active_install_name:
        return _last_active_install_dir
    else:
        return _find_active_game_dir()


func _find_active_game_dir() -> String:
    
    
    var base_dir = _get_own_dir() + str(Settings.read("game"))
    for subdir in FS.list_dir(base_dir):
        var curr_dir = base_dir + str(subdir)
        var info_file = curr_dir + str("catapult_install_info.json")
        if DirAccess.dir_exists_absolute(info_file):
            var info = Helpers.load_json_file(info_file)
            if ("name" in info) and (info["name"] == Settings.read("active_install_" + Settings.read("game"))):
                _last_active_install_dir = curr_dir
                return curr_dir
    
    return ""


func _get_next_install_dir() -> String:
    # Finds a suitable directory name for a new game installation in the
    # multi-install system. The names follow the pattern "game0, game1, ..."
    
    var base_dir := _get_own_dir() + str(Settings.read("game"))
    var dir_number := 0
    while DirAccess.dir_exists_absolute(base_dir + str("game" + str(dir_number))):
        dir_number += 1
    return base_dir + str("game" + str(dir_number))


func _get_userdata_dir() -> String:
    
    return _get_own_dir() + str(Settings.read("game")) + str("userdata")


func _get_config_dir() -> String:
    
    return _get_userdata_dir() + str("config")


func _get_savegame_dir() -> String:
    
    return _get_userdata_dir() + str("save")


func _get_mods_dir_default() -> String:
    
    return _get_game_dir() + str("data") + str("mods")


func _get_mods_dir_user() -> String:
    
    return _get_userdata_dir() + str("mods")


func _get_sound_dir_default() -> String:
    
    return _get_game_dir() + str("data") + str("sound")


func _get_sound_dir_user() -> String:
    
    return _get_userdata_dir() + str("sound")


func _get_gfx_dir_default() -> String:
    
    return _get_game_dir() + str("gfx")


func _get_gfx_dir_user() -> String:
    
    return _get_userdata_dir() + str("gfx")


func _get_font_dir_user() -> String:
    
    return _get_userdata_dir() + str("font")


func _get_templates_dir() -> String:
    
    return _get_userdata_dir() + str("templates")


func _get_memorial_dir() -> String:
    
    return _get_userdata_dir() + str("memorial")


func _get_graveyard_dir() -> String:
    
    return _get_userdata_dir() + str("graveyard")


func _get_modrepo_dir() -> String:
    
    return _get_own_dir() + str(Settings.read("game")) + str("mod_repo")


func _get_tmp_dir() -> String:
    
    return _get_own_dir() + str(Settings.read("game")) + str("tmp")


func _get_utils_dir() -> String:
    
    return _get_own_dir() + str("utils")


func _get_save_backups_dir() -> String:
    
    return _get_own_dir() + str(Settings.read("game")) + str("save_backups")

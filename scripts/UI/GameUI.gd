extends ScrollContainer

@onready var _btn_install = $GameVBox/BtnInstall
@onready var _btn_refresh = $GameVBox/Builds/BtnRefresh
@onready var _changelog = $GameVBox/ChangelogDialog
@onready var _lbl_changelog = $GameVBox/Channel/HBox/ChangelogLink
@onready var _btn_game_dir = $GameVBox/ActiveInstall/Build/GameDir
@onready var _btn_user_dir = $GameVBox/ActiveInstall/Build/UserDir
@onready var _btn_play = $GameVBox/ActiveInstall/Launch/BtnPlay
@onready var _btn_resume = $GameVBox/ActiveInstall/Launch/BtnResume
@onready var _lst_builds = $GameVBox/Builds/BuildsList
@onready var _rbtn_stable = $GameVBox/Channel/Group/RBtnStable
@onready var _rbtn_exper = $GameVBox/Channel/Group/RBtnExperimental
@onready var _lbl_build = $GameVBox/ActiveInstall/Build/Name
@onready var _cb_update = $GameVBox/UpdateCurrent
@onready var _lst_installs = $GameVBox/GameInstalls/HBox/InstallsList
@onready var _btn_make_active = $GameVBox/GameInstalls/HBox/VBox/btnMakeActive
@onready var _btn_delete = $GameVBox/GameInstalls/HBox/VBox/btnDelete
@onready var _panel_installs = $GameVBox/GameInstalls

@onready var _debug_ui = $/root/Catapult/Main/Tabs/DebugTab
@onready var _game_info = $/root/Catapult/Main/GameInfo
@onready var _tabs = $/root/Catapult/Main/Tabs
@onready var _mods = $/root/Catapult/Mods
@onready var _installer = $/root/Catapult/ReleaseInstaller

@onready var _game_desc = $/root/Catapult/Main/GameInfo/Description
@onready var _releases = $/root/Catapult/Releases
@onready var _lst_games = $/root/Catapult/Main/GameChoice/GamesList

var _base_icon_sizes := {}
var _installs := {}
var _disable_savestate := {}
var _easter_egg_counter := 0

# Called when the node enters the scene tree for the first time.
func _ready():
    _btn_resume.grab_focus()
    _lbl_changelog.bbcode_text = tr("lbl_changelog")
    _setup_ui()


func _get_release_key() -> String:
    # Compiles a string looking like "dda-stable" or "bn-experimental"
    # from settings.
    
    var game = Settings.read("game")
    var key = game + "-" + Settings.read("channel")
    
    return key

func _on_ChangelogLink_meta_clicked(_meta) -> void:
    
    _changelog.open()


func _on_BuildsList_item_selected(index: int) -> void:
    
    var info = Paths.installs_summary
    var game = Settings.read("game")
    
    if (not Settings.read("update_to_same_build_allowed")) \
            and (game in info) \
            and (_releases.releases[_get_release_key()][index]["name"] in info[game]):
        _btn_install.disabled = true
        _cb_update.disabled = true
    else:
        _btn_install.disabled = false
        _cb_update.disabled = false


func _on_BtnInstall_pressed() -> void:
    
    var index = _lst_builds.selected
    var release = _releases.releases[_get_release_key()][index]
    var update_path := ""
    if Settings.read("update_current_when_installing"):
        var game = Settings.read("game")
        var active_name = Settings.read("active_install_" + game)
        if (game in _installs) and (active_name in _installs[game]):
            update_path = _installs[game][active_name]
    _installer.install_release(release, Settings.read("game"), update_path)

func _setup_ui() -> void:

    _game_info.visible = Settings.read("show_game_desc")
    
    _cb_update.button_pressed = Settings.read("update_current_when_installing")
    
    apply_game_choice()
    
    _lst_games.connect("item_selected", _on_GamesList_item_selected)
    _rbtn_stable.connect("toggled", _on_RBtnStable_toggled)
    # Had to leave these signals unconnected in the editor and only connect
    # them now from code to avoid cyclic calls of apply_game_choice.
    
    _refresh_currently_installed()


func reload_builds_list() -> void:
    
    _lst_builds.clear()
    for rec in _releases.releases[_get_release_key()]:
        _lst_builds.add_item(rec["name"])
    _refresh_currently_installed()


func apply_game_choice() -> void:
    
    # TODO: Turn this mess into a more elegant mess.

    var game = Settings.read("game")
    var channel = Settings.read("channel")
    
    _rbtn_exper.disabled = false
    _rbtn_stable.disabled = false
    if channel == "stable":
        _rbtn_stable.button_pressed = true
        _btn_refresh.disabled = true
    else:
        _btn_refresh.disabled = false

    match game:
        "dda":
            _lst_games.select(0)
            _game_desc.bbcode_text = tr("desc_dda")
                
        "bn":
            _lst_games.select(1)
            _game_desc.bbcode_text = tr("desc_bn")
    
    if len(_releases.releases[_get_release_key()]) == 0:
        _releases.fetch(_get_release_key())
    else:
        reload_builds_list()


func _on_InstallsList_item_selected(index: int) -> void:
    
    var _name = _lst_installs.get_item_text(index)
    _btn_delete.disabled = false
    _btn_make_active.disabled = (_name == Settings.read("active_install_" + Settings.read("game")))


func _on_InstallsList_item_activated(index: int) -> void:
    
    var _name = _lst_installs.get_item_text(index)
    var path = _installs[Settings.read("game")][_name]
    if DirAccess.dir_exists_absolute(path):
        OS.shell_open(path)


func _on_btnMakeActive_pressed() -> void:
    
    var _name = _lst_installs.get_item_text(_lst_installs.get_selected_items()[0])
    Status.post(tr("msg_set_active") % _name)
    Settings.store("active_install_" + Settings.read("game"), _name)
    _refresh_currently_installed()


func _on_btnDelete_pressed() -> void:
    
    var _name = _lst_installs.get_item_text(_lst_installs.get_selected_items()[0])
    _installer.remove_release_by_name(_name)


func _refresh_currently_installed() -> void:
    
    var releases = _releases.releases[_get_release_key()]

    _lst_installs.clear()
    var game = Settings.read("game")
    _installs = Paths.installs_summary
    var active_name = Settings.read("active_install_" + game)
    if game in _installs:
        for _name in _installs[game]:
            _lst_installs.add_item(_name)
            var curr_idx = _lst_installs.get_item_count() - 1
            _lst_installs.set_item_tooltip(curr_idx, tr("tooltip_installs_item") % _installs[game][name])
#			if _name == active_name:
#				_lst_installs.set_item_custom_fg_color(curr_idx, Color(0, 0.8, 0))
    
    _lst_builds.select(0)
    _btn_make_active.disabled = true
    _btn_delete.disabled = true
    
    if game in _installs:
        _lbl_build.text = active_name
        _btn_play.disabled = false
        _btn_resume.disabled = not (DirAccess.dir_exists_absolute(Paths.config + str("lastworld.json")))
        _btn_game_dir.visible = true
        _btn_user_dir.visible = true
        if (_lst_builds.selected != -1) and (_lst_builds.selected < len(releases)):
                if not Settings.read("update_to_same_build_allowed"):
                    _btn_install.disabled = (releases[_lst_builds.selected]["name"] in _installs[game])
                    _cb_update.disabled = _btn_install.disabled
        else:
            _btn_install.disabled = true

    else:
        _lbl_build.text = tr("lbl_none")
        _btn_install.disabled = false
        _cb_update.disabled = true
        _btn_play.disabled = true
        _btn_resume.disabled = true
        _btn_game_dir.visible = false
        _btn_user_dir.visible = false
    
    if (game in _installs and _installs[game].size() > 1) or \
            (Settings.read("always_show_installs") == true):
        _panel_installs.visible = true
    else:
        _panel_installs.visible = false

    for i in [1, 2, 3, 4]:
        _tabs.set_tab_disabled(i, not game in _installs)

func _on_Tabs_tab_changed(tab: int) -> void:
    
    _refresh_currently_installed()


func _on_GamesList_item_selected(index: int) -> void:
    
    match index:
        0:
            Settings.store("game", "dda")
            _game_desc.bbcode_text = tr("desc_dda")
        1:
            Settings.store("game", "bn")
            _game_desc.bbcode_text = tr("desc_bn")
    
    _tabs.current_tab = 0
    apply_game_choice()
    _refresh_currently_installed()
    
    _mods.refresh_installed()
    _mods.refresh_available()


func _on_RBtnStable_toggled(button_pressed: bool) -> void:
    
    if button_pressed:
        Settings.store("channel", "stable")
    else:
        Settings.store("channel", "experimental")
        
    apply_game_choice()


func _on_Releases_started_fetching_releases() -> void:
    
    _smart_disable_controls("disable_while_fetching_releases")


func _on_Releases_done_fetching_releases() -> void:
    
    _smart_reenable_controls("disable_while_fetching_releases")
    reload_builds_list()
    _refresh_currently_installed()


func _on_ReleaseInstaller_operation_started() -> void:
    
    _smart_disable_controls("disable_during_release_operations")


func _on_ReleaseInstaller_operation_finished() -> void:
    
    _smart_reenable_controls("disable_during_release_operations")
    _refresh_currently_installed()


func _on_BtnRefresh_pressed() -> void:
    
    _releases.fetch(_get_release_key())


func _smart_disable_controls(group_name: String) -> void:
    
    var nodes = get_tree().get_nodes_in_group(group_name)
    var state = {}
    
    for n in nodes:
        if "disabled" in n:
            state[n] = n.disabled
            n.disabled = true
            
    _disable_savestate[group_name] = state
    

func _smart_reenable_controls(group_name: String) -> void:
    
    if not group_name in _disable_savestate:
        return
    
    var state = _disable_savestate[group_name]
    for node in state:
        node.disabled = state[node]
        
    _disable_savestate.erase(group_name)



func _on_mod_operation_started() -> void:
    
    _smart_disable_controls("disable_during_mod_operations")


func _on_mod_operation_finished() -> void:
    
    _smart_reenable_controls("disable_during_mod_operations")


func _on_soundpack_operation_started() -> void:
    
    _smart_disable_controls("disable_during_soundpack_operations")


func _on_soundpack_operation_finished() -> void:
    
    _smart_reenable_controls("disable_during_soundpack_operations")


func _on_backup_operation_started() -> void:
    
    _smart_disable_controls("disable_during_backup_operations")


func _on_backup_operation_finished() -> void:
    
    _smart_reenable_controls("disable_during_backup_operations")


func _on_Description_meta_clicked(meta) -> void:
    
    OS.shell_open(meta)


func _on_Log_meta_clicked(meta) -> void:
    
    OS.shell_open(meta)


func _on_cbUpdateCurrent_toggled(button_pressed: bool) -> void:
    
    Settings.store("update_current_when_installing", button_pressed)



func _on_GameDir_pressed() -> void:
    
    var gamedir = Paths.game_dir
    if DirAccess.dir_exists_absolute(gamedir):
        OS.shell_open(gamedir)


func _on_UserDir_pressed() -> void:
    
    var userdir = Paths.userdata
    if DirAccess.dir_exists_absolute(userdir):
        OS.shell_open(userdir)



func _on_BtnPlay_pressed() -> void:
    
    _start_game()


func _on_BtnResume_pressed() -> void:
    
    var lastworld: String = Paths.config + str("lastworld.json")
    var info = Helpers.load_json_file(lastworld)
    if info:
        _start_game(info["world_name"])


func _start_game(world := "") -> void:
    
    match OS.get_name():
        "X11":
            var params := ["--userdir", Paths.userdata + "/"]
            if world != "":
                params.append_array(["--world", world])
            OS.execute(Paths.game_dir + str("cataclysm-launcher"), params, [], false)
        "Windows":
            var world_str := ""
            if world != "":
                world_str = "--world \"%s\"" % world
            var command = "cd /d %s && start cataclysm-tiles.exe --userdir \"%s/\" %s" % [Paths.game_dir, Paths.userdata, world_str]
            OS.execute("cmd", ["/C", command], [], false)
        "macOS":
            return
        _:
            return
    
    if not Settings.read("keep_open_after_starting_game"):
        get_tree().quit()



func _on_InfoIcon_gui_input(event: InputEvent) -> void:
    
    if (event is InputEventMouseButton) and (event.button_index == MOUSE_BUTTON_LEFT) and (event.is_pressed()):
        _easter_egg_counter += 1
        if _easter_egg_counter == 3:
            Status.post("[color=red]%s[/color]" % tr("msg_easter_egg_warning"))
        if _easter_egg_counter == 10:
            _activate_easter_egg()


func _activate_easter_egg() -> void:
    
    for node in Helpers.get_all_nodes_within(self):
        if node is Control:
            node.rect_pivot_offset = node.rect_size / 2.0
            node.rect_rotation = randf() * 2.0 - 1.0
    
    Status.rainbow_text = true
    
    for i in range(20):
        Status.post(tr("msg_easter_egg_activated"))
        await get_tree().create_timer(0.1).timeout

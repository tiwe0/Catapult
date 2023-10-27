extends Control


@onready var _game_desc = $Main/GameInfo/Description
@onready var _releases = $Releases
@onready var _lst_games = $Main/GameChoice/GamesList

@onready var _game_choice = $"Main/GameChoice"
@onready var _game_info = $"Main/GameInfo"
@onready var _spacer = $"Main/Spacer"
@onready var _tabs = $"Main/Tabs"
@onready var _log = $"Main/Log"
@onready var _main_ui = [_game_choice, _game_info, _spacer, _tabs, _log]

@export var _ui_size: Vector2i : get = _get_ui_size

# For UI scaling on the fly
var _base_min_sizes := {}



func _ready() -> void:
    
    # Apply UI theme
    var theme_file = Settings.read("launcher_theme")
    load_ui_theme(theme_file)

    # UI scale
    _save_control_min_sizes()
    _scale_control_min_sizes(Geom.scale)
    Geom.connect("scale_changed", _on_ui_scale_changed)

    # Translation
    assign_localized_text()
    
    # Welcome
    var welcome_msg = tr("str_welcome")
    if Settings.read("print_tips_of_the_day"):
        welcome_msg += tr("str_tip_of_the_day") + TOTD.get_tip() + "\n"
    Status.post(welcome_msg)

    _lst_games.add_item("dda")
    _lst_games.add_item("bn")
    
    # Unpack utils
    _unpack_utils()

func _process(_delta):
    DisplayServer.window_set_size(_ui_size+Vector2i(0,28))

func _save_control_min_sizes() -> void:
    
    for node in Helpers.get_all_nodes_within(self):
        if ("rect_min_size" in node) and (node.rect_min_size != Vector2.ZERO):
            _base_min_sizes[node] = node.rect_min_size


func _scale_control_min_sizes(factor: float) -> void:
    
    for node in _base_min_sizes:
        node.rect_min_size = _base_min_sizes[node] * factor

func _on_ui_scale_changed(new_scale: float) -> void:
    
    _scale_control_min_sizes(new_scale)


func _save_icon_sizes() -> void:
    
    var resources = load("res://")


func assign_localized_text() -> void:
    
    DisplayServer.window_set_title(tr("window_title"))
    
    var game = Settings.read("game")
    if game == "dda":
        _game_desc.bbcode_text = tr("desc_dda")
    elif game == "bn":
        _game_desc.bbcode_text = tr("desc_bn")


func load_ui_theme(theme_file: String) -> void:
    
    # Since we've got multiple themes that have some shared elements (like fonts),
    # we have to make sure old theme's *scaled* sizes don't become new theme's
    # *base* sizes. To avoid that, we have to reset the scale of the old theme
    # before replacing it, and we have to do that before we even attempt to load
    # the new theme.
    
    # self.theme.applyf_scale(1.0)
    var new_theme := load("res://themes/" + str(theme_file)) as ScalableTheme
    
    if new_theme:
        new_theme.apply_scale(Geom.scale)
        set_theme(new_theme)
    else:
        new_theme = Theme.new() as ScalableTheme
        new_theme.apply_scale(Geom.scale)
        set_theme(new_theme)
        Status.post(tr("msg_theme_load_error") % theme_file, Enums.MSG_ERROR)


func _unpack_utils() -> void:
    
    var unzip_exe = Paths.utils_dir + str("unzip.exe")
    if (OS.get_name() == "Windows") and (not DirAccess.dir_exists_absolute(unzip_exe)):
        if not DirAccess.dir_exists_absolute(Paths.utils_dir):
            DirAccess.make_dir_absolute(Paths.utils_dir)
        Status.post(tr("msg_unpacking_unzip"))
        DirAccess.copy_absolute("res://utils/unzip.exe", unzip_exe)

func _get_ui_size() -> Vector2i:
    var x = $"Main".size.x
    var y = 0
    for weidget in _main_ui:
        y += weidget.size.y
    return Vector2i(x, y)

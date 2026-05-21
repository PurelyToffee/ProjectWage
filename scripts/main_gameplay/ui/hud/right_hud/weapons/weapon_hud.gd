class_name WeaponHUD
extends Control

# ── tunables ────────────────────────────────────────────────────────────────
@export var auto_close_delay    : float = 1.3
@export var slot_spacing        : float = 8.0
@export var slot_size           : Vector2 = Vector2(192, 96)
@export var dim_alpha           : float = 0.6
@export var tween_duration      : float = 0.22
@export var fade_duration       : float = 0.18
@export var list_right_margin   : float = 12.0
@export var active_bottom_margin: float = 12.0
# ────────────────────────────────────────────────────────────────────────────

var WEAPON_SCENES := [
	preload("uid://b8yd3ci75nvin"),
	preload("uid://ceaqd5iobucn4")
]

enum State { IDLE, OPEN, CLOSING }

@onready var active_slot : WeaponSlot       = $ActiveWeaponSlot
@onready var weapon_list : VBoxContainer = $WeaponList
@onready var sel_timer   : Timer         = $SelectionTimer

var state        : State = State.IDLE
var slots        : Array = []
var selected_idx : int   = 0
var weapon_count : int   = 0
var active_tween : Tween = null

var slot_h : float = 0.0
var slot_w : float = 0.0

func _process(delta: float) -> void:
	pass;

# ── called by the player every frame ────────────────────────────────────────

func refresh(wm: WeaponManager) -> void:
	var weapons := wm.get_weapons()

	if weapons.size() != weapon_count:
		rebuild_list(weapons)
		weapon_count = weapons.size()

	if wm.active_weapon_index != selected_idx:
		var prev_idx = selected_idx
		selected_idx = wm.active_weapon_index

		if state == State.IDLE:
			enter_open(prev_idx)
		elif state == State.CLOSING:
			enter_open(prev_idx)
		else:
			# Already open — update alphas smoothly, no slide
			apply_slot_alphas(false)
			reset_timer()

	sync_slot(active_slot, weapons[wm.active_weapon_index])
	for i in slots.size():
		sync_slot(slots[i], weapons[i])


func on_fire(wm: WeaponManager) -> void:
	if state != State.IDLE:
		enter_closing(wm)


# ── state transitions ────────────────────────────────────────────────────────

func show_active() -> void:
	LevelController.gameplay_HUD_right.remove_hud_drag_element(active_slot)
	active_slot.queue_free()

	active_slot = WEAPON_SCENES[selected_idx].instantiate()
	LevelController.gameplay_HUD_right.add_drag_element(active_slot)

	var target_pos := pos_of_slot(selected_idx)
	active_slot.global_position = target_pos
	active_slot.set_origin(target_pos)
	active_slot.set_alpha(1.0)
	active_slot.visible    = true

	self.add_child(active_slot)


func enter_open(prev_idx: int) -> void:
	state = State.OPEN
	position_list()
	weapon_list.visible = true
	active_slot.visible = true

	# Capture where the slot currently is before killing the tween
	var start_pos := active_slot.global_position  # ← ADD THIS
	var start_alpha := active_slot.shader_alpha    # ← ADD THIS

	slots[prev_idx].visible = false

	kill_tween()
	active_tween = create_tween().set_parallel(true)

	for i in slots.size():
		var target_a := 1.0 if i == selected_idx else dim_alpha
		if i != prev_idx:
			active_tween.tween_method(slots[i].set_alpha, slots[i].shader_alpha, target_a, fade_duration)  # ← was 0.0

	active_tween.tween_method(active_slot.set_alpha, start_alpha, dim_alpha, tween_duration)  # ← USE start_alpha
	active_tween.tween_property(active_slot, "global_position", pos_of_slot(prev_idx), tween_duration) \
		.from(start_pos) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	active_tween.chain().tween_callback(func():
		active_slot.set_origin(pos_of_slot(prev_idx))
		slots[prev_idx].set_alpha(active_slot.shader_alpha)
		slots[prev_idx].drag_offset = active_slot.drag_offset
		slots[prev_idx].visible = true
		active_slot.set_alpha(0.0)
		active_slot.visible = false
	)

	reset_timer()


func enter_closing(wm: WeaponManager) -> void:
	if state == State.IDLE:
		return
	state = State.CLOSING
	sel_timer.stop()

	show_active()

	kill_tween()
	active_tween = create_tween().set_parallel(true)

	for i in slots.size():
		var from_a := 0.0 if i == selected_idx else dim_alpha
		active_tween.tween_method(slots[i].set_alpha, from_a, 0.0, fade_duration)

	var target_pos := idle_pos()
	active_tween.tween_property(active_slot, "global_position", target_pos, tween_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	active_tween.chain().tween_callback(func():
		active_slot.set_origin(target_pos)
		weapon_list.visible = false
		state               = State.IDLE
		sync_slot(active_slot, wm.get_weapons()[wm.active_weapon_index])
	)


# ── alpha management ─────────────────────────────────────────────────────────

func apply_slot_alphas(hide_selected: bool = false) -> void:
	for i in slots.size():
		var target_a := (0.0 if hide_selected else 1.0) if i == selected_idx else dim_alpha
		var t := create_tween()
		t.tween_method(slots[i].set_alpha, slots[i].shader_alpha, target_a, fade_duration)


# ── layout ───────────────────────────────────────────────────────────────────

func idle_pos() -> Vector2:
	var vp := get_viewport_rect().size
	return Vector2(
		vp.x - slot_w - list_right_margin,
		vp.y - slot_h - active_bottom_margin
	)

func pos_of_slot(idx: int) -> Vector2:
	return slots[idx].global_position

func position_list() -> void:
	var vp      := get_viewport_rect().size
	var count   := slots.size()
	var total_h  = count * slot_h + max(count - 1, 0) * slot_spacing
	weapon_list.position = Vector2(
		vp.x - slot_w - list_right_margin,
		(vp.y - total_h - active_bottom_margin)
	)


# ── slot population ──────────────────────────────────────────────────────────

func rebuild_list(weapons: Array[BaseWeapon]) -> void:
	for child in weapon_list.get_children():
		child.queue_free()

	for s in slots:
		LevelController.gameplay_HUD_right.remove_hud_drag_element(s)
	slots.clear()
	weapon_list.add_theme_constant_override("separation", int(slot_spacing))

	slot_w = slot_size.x
	slot_h = slot_size.y

	for i in weapons.size():
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(slot_w, slot_h)

		var slot: GameplayHudElement = WEAPON_SCENES[weapons[i].index].instantiate()
		slot.use_global_positioning = false
		LevelController.gameplay_HUD_right.add_drag_element(slot)
		wrapper.add_child(slot)
		weapon_list.add_child(wrapper)
		slots.append(slot)
		sync_slot(slot, weapons[i])
		#slot.set_alpha(0.0)  # ← add this, ensure shader param is set after _ready runs

	var resting := idle_pos()
	active_slot.global_position = resting
	active_slot.set_origin(resting)
	active_slot.set_alpha(1.0)
	active_slot.visible    = true
	position_list()
	apply_slot_alphas(false)


func sync_slot(slot: Control, weapon: BaseWeapon) -> void:
	if slot.has_method("set_weapon_data"):
		slot.set_weapon_data({
			"weapon_name": weapon.weapon_name,
			"ammo":        weapon.ammo,
			"max_ammo":    weapon.max_ammo,
			"reloading":   weapon.reloading,
		})
		return

	var ammo_label: Label = slot.get_node_or_null("AmmoLabel")
	if ammo_label:
		if weapon.infinite_ammo:
			ammo_label.text = "∞"
		elif weapon.reloading:
			ammo_label.text = "..."
		else:
			ammo_label.text = "%d / %d" % [weapon.ammo, weapon.max_ammo]

	var sprite: AnimatedSprite2D = slot.get_node_or_null("AnimatedSprite2D")
	if sprite and sprite.sprite_frames:
		var anim := weapon.weapon_name.to_lower().replace(" ", "_")
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)


# ── timer ────────────────────────────────────────────────────────────────────

func reset_timer() -> void:
	sel_timer.wait_time = auto_close_delay
	sel_timer.start()


func on_selection_timer_timeout() -> void:
	if state == State.IDLE:
		return

	state = State.CLOSING

	show_active()

	kill_tween()
	active_tween = create_tween().set_parallel(true)

	for i in slots.size():
		if i == selected_idx:
			continue
		active_tween.tween_method(slots[i].set_alpha, dim_alpha, 0.0, fade_duration)

	slots[selected_idx].set_alpha(0.0)

	var target_pos := idle_pos()
	active_tween.tween_property(active_slot, "global_position", target_pos, tween_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	active_tween.chain().tween_callback(func():
		active_slot.set_origin(target_pos)
		weapon_list.visible = false
		state               = State.IDLE
	)


# ── lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	LevelController.weapon_hud = self

	clip_contents             = false
	weapon_list.clip_contents = false
	weapon_list.visible       = false
	active_slot.visible       = false
	active_slot.z_index       = 1
	sel_timer.timeout.connect(on_selection_timer_timeout)


func kill_tween() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()

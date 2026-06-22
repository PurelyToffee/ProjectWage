class_name VisibilityTrigger extends CollisionTrigger

## Nodes shown when the player passes through moving along entrance_vector,
## and hidden when passing through the opposite way.
@export var show_nodes : Array[Node3D] = [];
## Nodes hidden when the player passes through moving along entrance_vector,
## and shown when passing through the opposite way.
@export var hide_nodes : Array[Node3D] = [];
## World-space direction treated as the "forward" entrance direction.
## Player velocity aligned with this = forward; against it = reverse.
@export var entrance_vector : Vector3 = Vector3.FORWARD;


func _ready() -> void:
	super._ready();
	body_exited.connect(_on_body_exited);


func trigger(body) -> void:
	if !active : return;
	if !body.is_in_group("player") : return;
	_apply_visibility(body);


func _on_body_exited(body) -> void:
	if !active : return;
	if !body.is_in_group("player") : return;
	_apply_visibility(body);


# Forward (velocity aligned with entrance_vector): show Show, hide Hide.
# Reverse (moving against it): hide Show, show Hide.
func _apply_visibility(body) -> void:
	var forward : bool = body.velocity.dot(entrance_vector) >= 0.0;

	for node in show_nodes:
		if node : node.visible = forward;

	for node in hide_nodes:
		if node : node.visible = !forward;

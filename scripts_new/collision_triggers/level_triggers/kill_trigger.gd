extends CollisionTrigger

class_name KillTrigger

func trigger(body) -> void:
    if !active:
        return

    if not body is DynamicCharacterBody:
        return

    if body.has_method("kill"):
        body.kill()

    for child in body.get_children():
        if child.has_method("kill"):
            child.kill()

    set_active(false)

class_name OutlineMan extends Node

## Autoload singleton — registers itself so OutlineEffect (a Resource)
## can reach the SubViewport node without needing a @export node ref.
##
## Register this in:
##   Project Settings → Autoload → add outline_manager.gd → name it "OutlineManager"

var enemy_depth_rid: RID
var enemy_depth_sampler: RID

var mask_viewport: SubViewport = null

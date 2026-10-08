
A Godot 4 editor plugin that adds **Add** and **Add & Edit** buttons next to properties using the `PROPERTY_HINT_INPUT_NAME` hint, so you can create missing input actions directly from the inspector.

**Usage example:**
```gdscript
# Annotate an exported `String` property with the `quick_add` hint:
@export_custom(PROPERTY_HINT_INPUT_NAME, "quick_add") var action: String = "new_input"
@export_custom(PROPERTY_HINT_INPUT_NAME, "loose_mode,quick_add") var action_2: String = "new_input"
```

**!!! Relies on internal editor UI layout; may break on Godot updates.
Confirmed to work in Godot 4.7 - 4.8**

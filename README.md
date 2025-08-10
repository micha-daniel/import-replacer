# Import Replacer (Godot EditorScenePostImportPlugin)

A post-import helper for Godot that lets you via name tag an empty (or other) and additional custom properties, on import automatically:

- replace markers with scene instances,
- assign resources to properties,
- set multiple properties at once,
- attach scripts,
- add to groups,
- or replace a node’s type.

**No manual clean-up** after every re-import. Drop markers in your source file, export, and let the plugin do the rest.

---

## Installation

1. Copy the addon into your project at: `addons/import_replacer/`
2. In Godot: **Project > Project Settings > Plugins** > enable **Import Replacer**.
3. Re-import your scene (right-click your `.glb/.gltf` > **Reimport**).

The plugin logs to the editor output with the tag `[IMPORT REPLACER]` to identify errors or if something processed.

---

## Sample Project

A full sample project is included in **`sample/`**.  
It demonstrates **all features** of the plugin using a single example: a **Torch** setup.  
Open `sample/` as a Godot project and re-import the included `torch.glb` to see:

- `IR-REPLACE` swapping a marker with a torch scene instance,
- `IR-PROP_PATH` assigning a flame material,
- `IR-PROPS_VAL` toggling visibility/collision and setting custom values,
- `IR-SCRIPT` attaching a Torch script,
- `IR-GROUP` adding the torch to a `"lights"` group,
- `IR-REPLACE_TYPE` converting a placeholder into an `Area3D` or custom class.

Use it as a reference for naming, metadata keys, and transforms.

---

## Authoring Markers (Naming & Metadata)

### 1) Name your marker nodes

Any node whose **name starts with `IR-`** will be processed. Supported names:

- `IR-REPLACE`
- `IR-PROP_PATH`
- `IR-PROPS_VAL`
- `IR-SCRIPT`
- `IR-GROUP`
- `IR-REPLACE_TYPE`

Place the marker **as a child** of the node you want to affect, unless noted otherwise below.

> Also you are free to add a short text behind the empty in Godot to have better knowledge what you want to replace without seeing the properties (e.g. `IR-REPLACE-Particles`)

### 2) Add custom properties (metadata)

The plugin reads metadata from key **`"extras"`** on the marker node.

For glTF from Blender: add **Object > Custom Properties**, then enable **Custom Properties** in the glTF exporter.

Use these keys (strings) exactly:

| Key       | Meaning                   | Used by                              | Value format / example                         |
| --------- | ------------------------- | ------------------------------------ | ---------------------------------------------- |
| `ir_path` | Base path (no extension)  | `REPLACE`, `SCRIPT`                  | `res://scenes/MyThing` > appends `.tscn`/`.gd` |
| `ir_res`  | Base path (no extension)  | `PROP_PATH`                          | `res://materials/Mat` > appends `.tres`        |
| `ir_prop` | Property name             | `PROP_PATH`, `PROPS_VAL`             | `material_override`, `mesh`, `script`, etc.    |
| `ir_val`  | Value / group / type name | `GROUP`, `REPLACE_TYPE`, `PROPS_VAL` | `"lights"`, `"Area3D"`, `true`, `4`, etc.      |

For **`PROPS_VAL`**, supply **indexed pairs**:

- `ir_prop/0` + `ir_val/0`
- `ir_prop/1` + `ir_val/1`
- …

---

## Methods

### `IR-REPLACE`

**Goal:** Replace the marker with an instance of a scene.  
**Reads:** `ir_path` (appends `.tscn`)  
**Placement:** Put the marker where you want the new instance; its transform is copied.  
**Effect:** Instantiates under the same parent, copies marker `transform`, sets owner, deletes marker.

**Example:**

- Name: `IR-REPLACE`
- `ir_path = "res://scenes/props/torch"`

### `IR-PROP_PATH`

**Goal:** Set a property on the **parent node** to a loaded **Resource**.  
**Reads:** `ir_res` (appends `.tres`), `ir_prop`  
**Placement:** Marker as **child** of the node whose property you want to set.

**Example:**

- Name: `IR-PROP_PATH`
- `ir_prop = "material_override"`
- `ir_res  = "res://materials/torch_flame"`

### `IR-PROPS_VAL`

**Goal:** Set **multiple properties** (raw values) on the **parent node**.  
**Reads:** `ir_prop/N`, `ir_val/N` pairs  
**Placement:** Marker as **child** of the node you want to modify.

**Example:**

- Name: `IR-PROPS_VAL`
- `ir_prop/0 = "visible"` > `ir_val/0 = true`
- `ir_prop/1 = "collision_layer"` > `ir_val/1 = 4`
- `ir_prop/2 = "name"` > `ir_val/2 = "Torch_A"`

### `IR-SCRIPT`

**Goal:** Attach a script to the **parent node**.  
**Reads:** `ir_path` (appends `.gd`)  
**Placement:** Marker as **child** of the node that should receive the script.

**Example:**

- Name: `IR-SCRIPT`
- `ir_path = "res://scripts/Torch"`

### `IR-GROUP`

**Goal:** Add the **parent node** to a group.  
**Reads:** `ir_val` (group name)  
**Placement:** Marker as **child** of the node you want to add to the group.

**Example:**

- Name: `IR-GROUP`
- `ir_val = "lights"`

### `IR-REPLACE_TYPE`

**Goal:** Replace a node with a **different engine/custom type**.  
**Reads:** `ir_val` (class name)  
**Placement:** **Put this marker as a direct child of the node you want to replace.**  
**Effect:** Replaces the **parent** with `ir_val`, preserves name/transform, keeps children.

**Examples:**

- Name: `IR-REPLACE_TYPE`
- `ir_val = "AnimatableBody3D"`

---

## Path Conventions

- Don’t include file extensions in `ir_path` / `ir_res`. The plugin appends:
  - `.tscn` for scenes
  - `.tres` for resources
  - `.gd` for scripts
- Use full resource paths, e.g. `folder/name_without_extension`.

---

## Workflows

**Replace a Blender Empty with a Scene**

> Export glTF with **Custom Properties** > Import in Godot

1. Empty named `IR-REPLACE`
2. `ir_path = "assets/lights/torch"`

**Assign a Material on Import**

1. Mesh node (parent) > child marker `IR-PROP_PATH`
2. `ir_prop = "surface_material_override/0"`, `ir_res = "assets/material/wood"`

**Set Multiple Properties**

1. Child marker `IR-PROPS_VAL`
2. `ir_prop/0 = "visibility_range_end"`, `ir_val/0 = "5"`
3. `ir_prop/1 = "visibility_range_end_margin"`, `ir_val/1 = "1"`

**Attach a Script**

1. Child marker `IR-SCRIPT`
2. `ir_path = "script/test"`

**Replace a Node’s Type**

1. Parent: placeholder `StaticBody3D`
2. Child marker: `IR-REPLACE_TYPE` with `ir_val = "AnimatableBody3D"`

---

## Troubleshooting

- **“No Custom Properties in node … found”**  
  Enable **Custom Properties** in glTF exporter; put keys on the **marker** node.
- **“Requested type/class … does not exist!”**  
  `ir_val` for `REPLACE_TYPE` must be a valid Godot class or a `class_name` visible in the editor.
- **Nothing happens**  
  Check plugin enabled, names start with `IR-`, paths are correct (without extensions), then Reimport.
- **Resource didn’t assign**  
  Ensure the target property expects a Resource and the final path exists as `.tres`.
- **Transforms off for `REPLACE`**  
  The instance copies the **marker’s** transform.

---

## Notes

- Markers are deleted after processing.
- `PROP_PATH`, `PROPS_VAL`, `SCRIPT`, `GROUP` modify the **parent** of the marker.
- `REPLACE` adds the new instance as a sibling (under the same parent) and copies the marker’s transform.
- `REPLACE_TYPE` replaces the **marker’s parent** and preserves children.
- Ownership is set to the imported scene root for editability.

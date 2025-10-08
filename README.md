# Import Replacer

A post-import helper for Godot that uses **name-tagged empties** (from your DCC like Blender via glTF) plus **custom properties** to automatically:

- replace empties with scene instances
- assign resources to properties
- set multiple properties at once
- attach scripts
- add nodes to groups
- or swap a node's type

**Result:** No manual cleanup after every export from your DCC (like Blender), re-import in Godot, done.

![Sample inside Godot](godot.jpg)

---

## How it works (1-minute overview)

1. In your DCC (e.g., Blender), add **Empties** named with an `IR-…` tag and give them **Custom Properties**.
2. Export to glTF with **Custom Properties** enabled.
3. On import, the plugin reads the tagged empties and applies your instructions to the target nodes, then removes the helper empties.

---

## Installation

1. Copy the addon to: `addons/import_replacer/`
2. In Godot: **Project → Project Settings → Plugins** → enable **Import Replacer**
3. Re-import your scene (right-click your `.glb/.gltf` → **Reimport**)

> The plugin logs to the editor output with the tag `[IMPORT REPLACER]`.

---

## Sample Project

A complete sample lives in **`sample/`** and demonstrates all features with a **Torch**.  
Open `sample/` as a Godot project and **re-import `torch.glb`** to see the results.

> The original Blender file is included at `assets/props/torch`.

---

## Authoring empties

Any node whose **name starts with `IR-`** will be processed. Supported names:

- `IR-REPLACE`
- `IR-PROP_PATH`
- `IR-PROPS_VAL`
- `IR-SCRIPT`
- `IR-GROUP`
- `IR-REPLACE_TYPE`

## Methods

### `IR-REPLACE`

**Goal:** Replace the empty with an instance of a scene.  
**Reads:** `ir_path` (appends `.tscn`)  
**Placement:** Put the empty where you want the new instance; its transform is copied.  
**Effect:** Instantiates under the same parent, copies empty `transform`, sets owner, deletes empty.

**Example:**

- Name: `IR-REPLACE`
- `ir_path = "assets/lights/torch"`

### `IR-PROP_PATH`

**Goal:** Set a property on the **parent node** to a loaded **Resource**.  
**Reads:** `ir_res` (appends `.tres`), `ir_prop`  
**Placement:** empty as **child** of the node whose property you want to set.

**Example:**

- Name: `IR-PROP_PATH`
- `ir_prop = "surface_material_override/0"`
- `ir_res  = "assets/material/wood"`

### `IR-PROPS_VAL`

**Goal:** Set **multiple properties** (raw values) on the **parent node**.  
**Reads:** `ir_prop/N`, `ir_val/N` pairs  
**Placement:** empty as **child** of the node you want to modify.

**Example:**

- Name: `IR-PROPS_VAL`
- `ir_prop/0 = "visibility_range_end"` > `ir_val/0 = "5"`
- `ir_prop/1 = "visibility_range_end_margin"` > `ir_val/1 = "1"`
- `ir_prop/2 = "visibility_range_fade_mode"` > `ir_val/2 = "1"`

### `IR-SCRIPT`

**Goal:** Attach a script to the **parent node**.  
**Reads:** `ir_path` (appends `.gd`)  
**Placement:** empty as **child** of the node that should receive the script.

**Example:**

- Name: `IR-SCRIPT`
- `ir_path = "script/test"`

### `IR-GROUP`

**Goal:** Add the **parent node** to a group.  
**Reads:** `ir_val` (group name)  
**Placement:** empty as **child** of the node you want to add to the group.

**Example:**

- Name: `IR-GROUP`
- `ir_val = "torch"`

### `IR-REPLACE_TYPE`

**Goal:** Replace a node with a **different engine/custom type**.  
**Reads:** `ir_val` (class name)  
**Placement:** **Put this empty as a direct child of the node you want to replace.**  
**Effect:** Replaces the **parent** with `ir_val`, preserves name/transform, keeps children.

**Examples:**

- Name: `IR-REPLACE_TYPE`
- `ir_val = "AnimatableBody3D"`

---

## Path Conventions

- Don't include file extensions in `ir_path` / `ir_res`
  - `.tscn` for scenes
  - `.tres` for resources
  - `.gd` for scripts
- Use project-relative paths: `folder/name_without_extension`.

---

## Node Pruning

Some software like Blender using the AssetBrowser with collections, uses empties which are only required for handling inside. On import in Godot you can enable to prune those empty Node3D elements. This can help to reduce complexity in the sceen tree or when having issues with origin points offset to an object.

In _Project Settings_ you can enable or disable this feature `addons/import_replacer/always_prune_wrapper`

---

## Troubleshooting

- **"No Custom Properties in node … found"**  
  Enable **Custom Properties** in the exporter and put them on the **Empty's Object**. Make sure to only add the Custom Properties on _Object_, as others will be ignored
- **"Requested type/class... does not exist!"**  
  `ir_val` must be a valid Godot class or a `class_name`
- **Nothing happens**  
  Check plugin enabled, names start with `IR-`, paths are correct (without extensions), then re-import
- **Resource didn't assign**  
  Property must accept a Resource and the `.tres` must exist

---

## Notes

- Empties are deleted after processing.
- `PROP_PATH`, `PROPS_VAL`, `SCRIPT`, `GROUP` modify the **parent**
- `REPLACE` spawns a sibling instance, copies the empty's transform
- `REPLACE_TYPE` replaces the parent, preserves children
- Ownership is set to the imported scene root for editability

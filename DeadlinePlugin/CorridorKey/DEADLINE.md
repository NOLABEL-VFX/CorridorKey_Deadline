# CorridorKey DeadlinePlugin Files

This folder contains the Deadline plugin package for CorridorKey.

## Job-side fields (`CorridorKey.options`)
These map directly to CorridorKey run settings:
- InputPath / ConfigFile
- Device / Backend
- Linear / Despill / Despeckle / DespeckleSize / Refiner
- SkipExisting / MaxFrames / GenerateComp / GpuPost / AutoAlphaMode

## Plugin config defaults (`CorridorKey.param`)
These define worker-level defaults and required paths:
- PythonExecutable / UVExecutable
- RepositoryPath / CLIPath
- DefaultConfigFile
- DefaultDevice / DefaultBackend / DefaultLinear / DefaultDespill / DefaultDespeckle / DefaultDespeckleSize / DefaultRefiner / DefaultSkipExisting / DefaultMaxFrames / DefaultGenerateComp / DefaultGpuPost / DefaultAutoAlphaMode

`CorridorKey.py` resolves values with this precedence:
1. Job options
2. Optional JSON config file
3. Plugin default parameters


Headless execution is performed by `DeadlinePlugin/CorridorKey/CorridorKey_headless.py` to avoid any interactive wizard prompts.

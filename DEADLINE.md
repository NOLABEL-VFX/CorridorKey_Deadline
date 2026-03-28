# Deadline Integration (CorridorKey)

This repository includes a Deadline Render Farm integration designed around CorridorKey's inference settings.

## Automation Batch

`CorridorKey_Deadline_AutoRun.bat` supports two modes:

1. `CorridorKey_Deadline_AutoRun.bat <input_path> [config_file]`
2. `CorridorKey_Deadline_AutoRun.bat <config_file>` (requires `input_path` or `target_path` inside config)

Config files can be:
- `.json`
- plain text `key=value`

The batch parses:
- `input_path` / `target_path`
- `device`
- `backend`
- `linear`
- `despill`
- `despeckle`
- `despeckle_size`
- `refiner`
- `skip_existing`
- `max_frames`
- `generate_comp`
- `gpu_post`

## Deadline Plugin Package

`DeadlinePlugin/CorridorKey/` contains:
- `CorridorKey.options`: job-submission fields for all inference inputs.
- `CorridorKey.param`: executable/repository settings and plugin-wide fallback defaults.
- `CorridorKey.py`: merges values from job fields, optional JSON config, and plugin defaults; then runs wizard + inference.

## Example JSON Config

```json
{
  "input_path": "D:/Shots/Shot010",
  "device": "auto",
  "backend": "auto",
  "linear": false,
  "despill": 5,
  "despeckle": true,
  "despeckle_size": 400,
  "refiner": 1.0,
  "skip_existing": true,
  "max_frames": null,
  "generate_comp": true,
  "gpu_post": false
}
```

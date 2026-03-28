# Deadline Integration (CorridorKey)

This repository now includes a first-pass Deadline Render Farm integration:

- `CorridorKey_Deadline_AutoRun.bat`:
  - Automated launcher that accepts a target path and a config file.
  - Supports `.json` config or plain `key=value` text config.
  - Runs a wizard organization pass and then non-interactive inference with preconfigured flags.
- `DeadlinePlugin/CorridorKey/`:
  - `CorridorKey.options`: Job-level fields.
  - `CorridorKey.param`: Environment/worker configuration fields.
  - `CorridorKey.py`: Deadline plugin entry point and argument builder.

## Example JSON Config for AutoRun

```json
{
  "device": "cuda",
  "backend": "torch",
  "linear": false,
  "despill": 5,
  "despeckle": true,
  "despeckle_size": 400,
  "refiner": 1.0,
  "skip_existing": true,
  "generate_comp": true,
  "gpu_post": false
}
```

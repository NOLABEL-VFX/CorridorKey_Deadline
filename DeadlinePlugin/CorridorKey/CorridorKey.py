from Deadline.Events import *
from Deadline.Plugins import *
from Deadline.Scripting import *
import json
import os


def GetDeadlinePlugin():
    return CorridorKeyPlugin()


def CleanupDeadlinePlugin(deadlinePlugin):
    deadlinePlugin.Cleanup()


class CorridorKeyPlugin(DeadlinePlugin):
    def __init__(self):
        super(CorridorKeyPlugin, self).__init__()
        self.InitializeProcessCallback += self.InitializeProcess
        self.RenderExecutableCallback += self.RenderExecutable
        self.RenderArgumentCallback += self.RenderArgument

    def Cleanup(self):
        pass

    def InitializeProcess(self):
        self.SingleFramesOnly = False
        self.StdoutHandling = True

    def RenderExecutable(self):
        return "cmd.exe"

    def _read_json_dict(self, path):
        if not path:
            return {}
        if not os.path.isfile(path):
            self.LogWarning("Config file does not exist: " + path)
            return {}
        try:
            with open(path, "r") as fh:
                data = json.load(fh)
            if isinstance(data, dict):
                return data
            self.LogWarning("Config JSON is not an object, ignoring: " + path)
            return {}
        except Exception as exc:
            self.LogWarning("Failed to parse config JSON '{}': {}".format(path, exc))
            return {}

    def _first_non_empty(self, values, fallback=""):
        for value in values:
            if value is None:
                continue
            txt = str(value).strip()
            if txt != "":
                return txt
        return fallback

    def _bool_from_sources(self, key, job_default, json_data, config_default_key):
        value = self.GetBooleanPluginInfoEntryWithDefault(key, job_default)
        if self.GetPluginInfoEntryWithDefault(key, "") != "":
            return value

        if key.lower() in json_data:
            raw = json_data.get(key.lower())
            if isinstance(raw, bool):
                return raw
            return str(raw).strip().lower() in ["1", "true", "yes", "on"]

        return self.GetBooleanConfigEntryWithDefault(config_default_key, job_default)

    def RenderArgument(self):
        repository_path = self.GetConfigEntryWithDefault("RepositoryPath", r"D:\CorridorKey_Deadline")
        cli_path = self.GetConfigEntryWithDefault("CLIPath", "").strip()
        uv_exe = self.GetConfigEntryWithDefault("UVExecutable", "").strip()
        python_exe = self.GetConfigEntryWithDefault("PythonExecutable", r"C:\CorridorKey_Deadline\.venv\Scripts\python.exe")

        job_config_file = self.GetPluginInfoEntryWithDefault("ConfigFile", "").strip()
        default_config_file = self.GetConfigEntryWithDefault("DefaultConfigFile", "").strip()
        config_file = self._first_non_empty([job_config_file, default_config_file], "")
        json_data = self._read_json_dict(config_file) if config_file.lower().endswith(".json") else {}

        input_path = self._first_non_empty(
            [
                self.GetPluginInfoEntryWithDefault("InputPath", ""),
                json_data.get("input_path", ""),
                json_data.get("target_path", ""),
            ],
            "",
        )

        if not input_path:
            self.FailRender("InputPath is required (job InputPath or JSON input_path/target_path).")

        device = self._first_non_empty(
            [
                self.GetPluginInfoEntryWithDefault("Device", ""),
                json_data.get("device", ""),
                self.GetConfigEntryWithDefault("DefaultDevice", "auto"),
            ],
            "auto",
        )
        backend = self._first_non_empty(
            [
                self.GetPluginInfoEntryWithDefault("Backend", ""),
                json_data.get("backend", ""),
                self.GetConfigEntryWithDefault("DefaultBackend", "auto"),
            ],
            "auto",
        )

        linear = self._bool_from_sources("Linear", False, json_data, "DefaultLinear")
        despill = self._first_non_empty(
            [
                self.GetPluginInfoEntryWithDefault("Despill", ""),
                json_data.get("despill", ""),
                self.GetConfigEntryWithDefault("DefaultDespill", "5"),
            ],
            "5",
        )
        despeckle = self._bool_from_sources("Despeckle", True, json_data, "DefaultDespeckle")
        despeckle_size = self._first_non_empty(
            [
                self.GetPluginInfoEntryWithDefault("DespeckleSize", ""),
                json_data.get("despeckle_size", ""),
                self.GetConfigEntryWithDefault("DefaultDespeckleSize", "400"),
            ],
            "400",
        )
        refiner = self._first_non_empty(
            [
                self.GetPluginInfoEntryWithDefault("Refiner", ""),
                json_data.get("refiner", ""),
                self.GetConfigEntryWithDefault("DefaultRefiner", "1.0"),
            ],
            "1.0",
        )
        skip_existing = self._bool_from_sources("SkipExisting", True, json_data, "DefaultSkipExisting")
        max_frames = self._first_non_empty(
            [
                self.GetPluginInfoEntryWithDefault("MaxFrames", ""),
                json_data.get("max_frames", ""),
                self.GetConfigEntryWithDefault("DefaultMaxFrames", ""),
            ],
            "",
        )
        generate_comp = self._bool_from_sources("GenerateComp", True, json_data, "DefaultGenerateComp")
        gpu_post = self._bool_from_sources("GpuPost", False, json_data, "DefaultGpuPost")

        cli_script = cli_path if cli_path else os.path.join(repository_path, "corridorkey_cli.py")
        if not os.path.isfile(cli_script):
            self.FailRender("corridorkey_cli.py not found at: " + cli_script)

        linear_flag = "--linear" if linear else "--srgb"
        despeckle_flag = "--despeckle" if despeckle else "--no-despeckle"
        skip_flag = "--skip-existing" if skip_existing else ""
        comp_flag = "--comp" if generate_comp else "--no-comp"
        gpu_post_flag = "--gpu-post" if gpu_post else "--cpu-post"
        max_frames_flag = (" --max-frames " + str(max_frames)) if str(max_frames).strip() else ""

        wizard_args = '"{cli}" --device {device} wizard "{input_path}"'.format(
            cli=cli_script,
            device=device,
            input_path=input_path,
        )
        inference_args = (
            '"{cli}" --device {device} run-inference --backend {backend}{max_frames} '
            '{skip} {linear} --despill {despill} {despeckle} --despeckle-size {despeckle_size} '
            '--refiner {refiner} {comp} {gpu_post}'
        ).format(
            cli=cli_script,
            device=device,
            backend=backend,
            max_frames=max_frames_flag,
            skip=skip_flag,
            linear=linear_flag,
            despill=despill,
            despeckle=despeckle_flag,
            despeckle_size=despeckle_size,
            refiner=refiner,
            comp=comp_flag,
            gpu_post=gpu_post_flag,
        )

        if uv_exe:
            args = '/c pushd "{repo}" && "{uv}" run --extra cuda python {wiz} && "{uv}" run --extra cuda python {inf}'.format(
                repo=repository_path,
                uv=uv_exe,
                wiz=wizard_args,
                inf=inference_args,
            )
        else:
            args = '/c pushd "{repo}" && "{python}" {wiz} && "{python}" {inf}'.format(
                repo=repository_path,
                python=python_exe,
                wiz=wizard_args,
                inf=inference_args,
            )

        self.LogInfo("CorridorKey args: " + args)
        return args

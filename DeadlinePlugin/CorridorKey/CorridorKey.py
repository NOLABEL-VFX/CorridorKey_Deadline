from Deadline.Events import *
from Deadline.Plugins import *
from Deadline.Scripting import *
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

        self.python_exe = r"C:\Python39\python.exe"
        self.repository_path = r"D:\CorridorKey_Deadline"
        self.cli_path = ""
        self.uv_exe = ""

    def Cleanup(self):
        pass

    def InitializeProcess(self):
        self.SingleFramesOnly = False
        self.StdoutHandling = True

        ocio = self.GetConfigEntryWithDefault("OCIOConfig", "")
        if ocio:
            self.SetProcessEnvironmentVariable("OCIO", ocio)

    def RenderExecutable(self):
        uv_cfg = self.GetConfigEntryWithDefault("UVExecutable", "").strip()
        if uv_cfg:
            return uv_cfg
        return self.GetConfigEntryWithDefault("PythonExecutable", self.python_exe)

    def RenderArgument(self):
        self.repository_path = self.GetConfigEntryWithDefault("RepositoryPath", self.repository_path)
        self.cli_path = self.GetConfigEntryWithDefault("CLIPath", "").strip()
        self.uv_exe = self.GetConfigEntryWithDefault("UVExecutable", "").strip()

        input_path = self.GetPluginInfoEntryWithDefault("InputPath", "")
        device = self.GetPluginInfoEntryWithDefault("Device", "auto")
        backend = self.GetPluginInfoEntryWithDefault("Backend", "auto")
        linear = self.GetBooleanPluginInfoEntryWithDefault("Linear", False)
        despill = self.GetIntegerPluginInfoEntryWithDefault("Despill", 5)
        despeckle = self.GetBooleanPluginInfoEntryWithDefault("Despeckle", True)
        despeckle_size = self.GetIntegerPluginInfoEntryWithDefault("DespeckleSize", 400)
        refiner = self.GetPluginInfoEntryWithDefault("Refiner", "1.0")
        skip_existing = self.GetBooleanPluginInfoEntryWithDefault("SkipExisting", True)
        generate_comp = self.GetBooleanPluginInfoEntryWithDefault("GenerateComp", True)
        gpu_post = self.GetBooleanPluginInfoEntryWithDefault("GpuPost", False)
        max_frames = self.GetPluginInfoEntryWithDefault("MaxFrames", "")

        if not input_path:
            self.FailRender("InputPath is required.")

        cli_script = self.cli_path if self.cli_path else os.path.join(self.repository_path, "corridorkey_cli.py")
        if not os.path.isfile(cli_script):
            self.FailRender("corridorkey_cli.py not found at: " + cli_script)

        linear_flag = "--linear" if linear else "--srgb"
        despeckle_flag = "--despeckle" if despeckle else "--no-despeckle"
        skip_flag = "--skip-existing" if skip_existing else ""
        comp_flag = "--comp" if generate_comp else "--no-comp"
        gpu_post_flag = "--gpu-post" if gpu_post else "--cpu-post"
        max_frames_flag = (" --max-frames " + max_frames) if max_frames else ""

        if self.uv_exe:
            args = (
                "run --extra cuda corridorkey --device {device} run-inference --backend {backend}{max_frames} "
                "{skip} {linear} --despill {despill} {despeckle} --despeckle-size {despeckle_size} "
                "--refiner {refiner} {comp} {gpu_post}"
            ).format(
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
        else:
            args = (
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

        self.LogInfo("CorridorKey args: " + args)
        return args

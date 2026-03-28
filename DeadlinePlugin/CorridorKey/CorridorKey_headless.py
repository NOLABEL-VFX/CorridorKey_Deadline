import argparse
import os
import sys

import clip_manager
from clip_manager import InferenceSettings
from device_utils import resolve_device


def main() -> int:
    parser = argparse.ArgumentParser(description="Headless CorridorKey runner for Deadline")
    parser.add_argument("--input-path", required=True, help="Path containing shot folders or loose clips")
    parser.add_argument("--device", default="auto", choices=["auto", "cuda", "mps", "cpu"])
    parser.add_argument("--backend", default="auto", choices=["auto", "torch", "mlx"])
    parser.add_argument("--linear", action="store_true", help="Treat input as linear")
    parser.add_argument("--srgb", action="store_false", dest="linear", help="Treat input as sRGB")
    parser.add_argument("--despill", type=int, default=5, help="Despill 0-10")
    parser.add_argument("--despeckle", action="store_true", default=True)
    parser.add_argument("--no-despeckle", action="store_false", dest="despeckle")
    parser.add_argument("--despeckle-size", type=int, default=400)
    parser.add_argument("--refiner", type=float, default=1.0)
    parser.add_argument("--skip-existing", action="store_true", default=True)
    parser.add_argument("--no-skip-existing", action="store_false", dest="skip_existing")
    parser.add_argument("--max-frames", type=int, default=None)
    parser.add_argument("--comp", action="store_true", default=True)
    parser.add_argument("--no-comp", action="store_false", dest="generate_comp")
    parser.add_argument("--gpu-post", action="store_true", default=False)
    parser.add_argument("--cpu-post", action="store_false", dest="gpu_post")

    args = parser.parse_args()

    input_path = os.path.abspath(args.input_path)
    if not os.path.exists(input_path):
        print("[ERROR] input path does not exist: {}".format(input_path))
        return 1

    clip_manager.CLIPS_DIR = input_path

    clips = clip_manager.scan_clips()
    if not clips:
        print("[ERROR] no valid clips found in {}".format(input_path))
        return 1

    despill = max(0, min(10, int(args.despill))) / 10.0
    settings = InferenceSettings(
        input_is_linear=bool(args.linear),
        despill_strength=despill,
        auto_despeckle=bool(args.despeckle),
        despeckle_size=max(0, int(args.despeckle_size)),
        refiner_scale=float(args.refiner),
        generate_comp=bool(args.generate_comp),
        gpu_post_processing=bool(args.gpu_post),
    )

    device = resolve_device(args.device)
    clip_manager.run_inference(
        clips,
        device=device,
        backend=args.backend,
        max_frames=args.max_frames,
        skip_existing=bool(args.skip_existing),
        settings=settings,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

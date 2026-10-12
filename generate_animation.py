#!/usr/bin/env python3
"""Generate Permission Scanner animated walkthrough preview GIF for README.

Loads the modern screenshots from asset/github-img/#3, crops device status/nav bars,
resizes with high-quality resampling, frames them in a rounded device canvas,
appends clear feature title badges with the app theme color, and creates an optimized animated GIF.
"""

import os
from PIL import Image, ImageDraw, ImageFont

def generate_demo_gif(output_path="asset/github-img/permission_scanner_demo.gif"):
    screens_info = [
        ("asset/github-img/#3/Screenshot_20261012_224847.jpg", "Security Dashboard & Risk Score"),
        ("asset/github-img/#3/Screenshot_20261012_224858.jpg", "Installed Apps Risk Classification"),
        ("asset/github-img/#3/Screenshot_20261012_225031.jpg", "App Permissions & Risk Analysis"),
        ("asset/github-img/#3/Screenshot_20261012_225022.jpg", "Side-by-Side App Risk Comparison"),
        ("asset/github-img/#3/Screenshot_20261012_224904.jpg", "Privacy Tools & Audit Utilities"),
        ("asset/github-img/#3/Screenshot_20261012_225043.jpg", "Android Permission Reference Library"),
        ("asset/github-img/#3/Screenshot_20261012_225048.jpg", "Privacy Timeline & Exposure Map"),
        ("asset/github-img/#3/Screenshot_20261012_225140.jpg", "SDK Profile & Behavior Posture Audit"),
    ]

    base_dir = os.path.dirname(os.path.abspath(__file__))
    target_w = 360
    # Crop status bar (0-68) and navigation bar (1528-1608)
    crop_box = (0, 68, 720, 1528)
    crop_w = crop_box[2] - crop_box[0]
    crop_h = crop_box[3] - crop_box[1]
    target_h = int(target_w * (crop_h / crop_w))

    border_pad = 12
    banner_h = 44
    canvas_w = target_w + (border_pad * 2)
    canvas_h = target_h + (border_pad * 2) + banner_h

    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
    except Exception:
        font = ImageFont.load_default()

    loaded_images = []
    for rel_path, label in screens_info:
        full_path = os.path.join(base_dir, rel_path)
        raw = Image.open(full_path)
        cropped = raw.crop(crop_box).convert("RGB")
        resized = cropped.resize((target_w, target_h), Image.Resampling.LANCZOS)

        screen_mask = Image.new("L", (target_w, target_h), 0)
        mask_draw = ImageDraw.Draw(screen_mask)
        mask_draw.rounded_rectangle([0, 0, target_w - 1, target_h - 1], radius=16, fill=255)

        # Canvas background (Dark slate)
        canvas = Image.new("RGB", (canvas_w, canvas_h), (15, 23, 42))
        draw = ImageDraw.Draw(canvas)

        canvas.paste(resized, (border_pad, border_pad), screen_mask)

        # Phone bezel
        draw.rounded_rectangle(
            [border_pad - 1, border_pad - 1, border_pad + target_w, border_pad + target_h],
            radius=16,
            outline=(51, 65, 85),  # Slate 700
            width=2,
        )

        # Feature label badge styled with App theme color (#0E7B72)
        banner_y1 = border_pad + target_h + 10
        banner_y2 = banner_y1 + 32
        # Outer badge container with app theme primary color
        draw.rounded_rectangle(
            [border_pad, banner_y1, canvas_w - border_pad, banner_y2],
            radius=8,
            fill=(14, 123, 114),  # AppColors.primary (0xFF0E7B72)
            outline=(149, 203, 197),  # AppColors.secondary (0xFF95CBC5)
            width=1,
        )

        bbox = draw.textbbox((0, 0), label, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        tx = (canvas_w - tw) // 2
        ty = banner_y1 + (32 - th) // 2 - 1
        draw.text((tx, ty), label, fill=(255, 255, 255), font=font)

        loaded_images.append(canvas)

    frames = []
    durations = []

    for i, canvas in enumerate(loaded_images):
        frames.append(canvas.quantize(colors=128, method=Image.Resampling.LANCZOS))
        durations.append(2200)

        next_canvas = loaded_images[(i + 1) % len(loaded_images)]
        for alpha in [0.4, 0.75]:
            blended = Image.blend(canvas, next_canvas, alpha)
            frames.append(blended.quantize(colors=128, method=Image.Resampling.LANCZOS))
            durations.append(100)

    full_out = os.path.join(base_dir, output_path)
    os.makedirs(os.path.dirname(full_out), exist_ok=True)
    frames[0].save(
        full_out,
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=0,
        optimize=True,
    )
    size_kb = os.path.getsize(full_out) / 1024
    print(f"Generated {full_out} ({size_kb:.1f} KB, {len(frames)} frames)")

if __name__ == "__main__":
    generate_demo_gif()

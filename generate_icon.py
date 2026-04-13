#!/usr/bin/env python3
"""Generate Permission Scanner app icon: shield with scanning effect on teal gradient."""

from PIL import Image, ImageDraw, ImageChops
import math

SIZE = 1024
CENTER = SIZE // 2

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

# --- Background: rounded square with teal-to-dark-teal gradient ---
def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

top_color = (13, 148, 132)      # #0D9488 (primary teal)
bottom_color = (6, 95, 90)      # Darker teal

# Draw gradient row by row (fast enough for 1024px)
for y in range(SIZE):
    t = y / SIZE
    c = lerp_color(top_color, bottom_color, t)
    for x in range(SIZE):
        # Slight diagonal shift
        t2 = min(1.0, max(0.0, t + (x / SIZE - 0.5) * 0.15))
        c2 = lerp_color(top_color, bottom_color, t2)
        img.putpixel((x, y), (*c2, 255))

# Apply rounded corners mask
mask = Image.new("L", (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
corner_radius = int(SIZE * 0.22)
mask_draw.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], corner_radius, fill=255)
img.putalpha(mask)


def min_alpha(img_layer, mask_layer):
    """Apply a grayscale mask as minimum-alpha to an RGBA image (no numpy)."""
    r, g, b, a = img_layer.split()
    # ImageChops.darker takes per-pixel min
    new_a = ImageChops.darker(a, mask_layer)
    img_layer.putalpha(new_a)
    return img_layer


# --- Draw shield shape ---
def shield_points(cx, cy, w, h):
    """Return list of (x,y) forming a shield polygon."""
    points = []
    top_y = cy - h * 0.48
    mid_y = cy + h * 0.05
    bottom_y = cy + h * 0.48
    left_x = cx - w * 0.42
    right_x = cx + w * 0.42
    steps = 30
    corner_r = w * 0.12

    # Top-left rounded corner
    for i in range(steps + 1):
        angle = math.pi + (math.pi / 2) * (i / steps)
        px = left_x + corner_r + corner_r * math.cos(angle)
        py = top_y + corner_r + corner_r * math.sin(angle)
        points.append((px, py))

    # Top-right rounded corner
    for i in range(steps + 1):
        angle = -math.pi / 2 + (math.pi / 2) * (i / steps)
        px = right_x - corner_r + corner_r * math.cos(angle)
        py = top_y + corner_r + corner_r * math.sin(angle)
        points.append((px, py))

    # Right side curve down to point
    for i in range(steps + 1):
        t = i / steps
        px = right_x - (right_x - cx) * (t ** 1.5)
        py = mid_y + (bottom_y - mid_y) * t
        points.append((px, py))

    # Left side curve from point up
    for i in range(steps + 1):
        t = 1 - i / steps
        px = left_x + (cx - left_x) * (t ** 1.5)
        py = mid_y + (bottom_y - mid_y) * t
        points.append((px, py))

    return points


def draw_shield(draw, cx, cy, w, h, fill):
    draw.polygon(shield_points(cx, cy, w, h), fill=fill)


# Outer shield glow (subtle)
for i in range(3, 0, -1):
    alpha = int(30 * (4 - i))
    glow_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)
    draw_shield(glow_draw, CENTER, CENTER + 10, 540 + i * 12, 600 + i * 12,
                fill=(255, 255, 255, alpha))
    img = Image.alpha_composite(img, glow_img)

# Main shield (white)
shield_w, shield_h = 480, 540
overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
overlay_draw = ImageDraw.Draw(overlay)
draw_shield(overlay_draw, CENTER, CENTER + 10, shield_w, shield_h,
            fill=(255, 255, 255, 240))
img = Image.alpha_composite(img, overlay)

# --- Scanning lines clipped to inner shield ---
scan_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
scan_draw = ImageDraw.Draw(scan_overlay)

# Shield mask for clipping
shield_mask = Image.new("L", (SIZE, SIZE), 0)
shield_mask_draw = ImageDraw.Draw(shield_mask)
draw_shield(shield_mask_draw, CENTER, CENTER + 10, shield_w - 40, shield_h - 40, fill=255)

# Horizontal scan lines (teal)
line_color = (13, 148, 132, 80)
line_spacing = 36
y_start = CENTER - 230
for i in range(14):
    y = y_start + i * line_spacing
    scan_draw.rectangle([0, y, SIZE, y + 3], fill=line_color)

# Brighter "active" scan line
bright_line_y = CENTER - 30
scan_draw.rectangle([0, bright_line_y, SIZE, bright_line_y + 6], fill=(13, 148, 132, 160))
scan_draw.rectangle([0, bright_line_y - 8, SIZE, bright_line_y + 14], fill=(13, 148, 132, 40))

# Clip scan lines to shield
scan_overlay = min_alpha(scan_overlay, shield_mask)
img = Image.alpha_composite(img, scan_overlay)

# --- Checkmark inside shield ---
check_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
check_draw = ImageDraw.Draw(check_overlay)

check_cx, check_cy = CENTER, CENTER + 10
check_size = 140
p1 = (check_cx - check_size * 0.55, check_cy - check_size * 0.02)
p2 = (check_cx - check_size * 0.1, check_cy + check_size * 0.45)
p3 = (check_cx + check_size * 0.6, check_cy - check_size * 0.42)
line_width = 42

check_draw.line([p1, p2], fill=(13, 148, 132, 230), width=line_width, joint="curve")
check_draw.line([p2, p3], fill=(13, 148, 132, 230), width=line_width, joint="curve")

for p in [p1, p2, p3]:
    check_draw.ellipse(
        [p[0] - line_width // 2, p[1] - line_width // 2,
         p[0] + line_width // 2, p[1] + line_width // 2],
        fill=(13, 148, 132, 230)
    )

img = Image.alpha_composite(img, check_overlay)

# --- Subtle dot grid in background ---
dot_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
dot_draw = ImageDraw.Draw(dot_overlay)
dot_spacing = 48
for dy in range(0, SIZE, dot_spacing):
    for dx in range(0, SIZE, dot_spacing):
        dot_draw.ellipse([dx - 1, dy - 1, dx + 1, dy + 1], fill=(255, 255, 255, 18))

# Invert shield mask for background-only dots
inv_shield_mask = ImageChops.invert(shield_mask)
dot_overlay = min_alpha(dot_overlay, inv_shield_mask)

final = Image.alpha_composite(img, dot_overlay)

# Re-apply rounded corner mask
final = min_alpha(final, mask)

# Save
output_path = "asset/icon/Permission Scanner.png"
final.save(output_path, "PNG")
print(f"Icon saved to {output_path} ({final.size[0]}x{final.size[1]})")

# Full version (no transparent corners) for flutter_launcher_icons
bg = Image.new("RGBA", (SIZE, SIZE), (*top_color, 255))
result = Image.alpha_composite(bg, final)
result.save("asset/icon/icon_full.png", "PNG")
print(f"Full icon saved to asset/icon/icon_full.png")

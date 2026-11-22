"""Generates the art for Math Runner: the weapons, the app icon and the ground.
The knight (assets/images/knight.png) is from Jumpy Boi and is not made here,
and the sounds are recordings.

Run it from the project folder with `python3 tools/make_assets.py`.
It only needs Python 3, no extra packages.
"""
import random
import struct
import zlib


def save_png(path, pixels):
    """pixels is a list of rows, each row a list of (r, g, b, a)."""
    height, width = len(pixels), len(pixels[0])
    raw = bytearray()
    for row in pixels:
        raw += b"\x00" + b"".join(bytes(p) for p in row)

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)) \
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    open(path, "wb").write(png)


def load_png(path):
    """Reads an 8-bit RGBA PNG (the kind knight.png is) into rows of (r, g, b, a)."""
    data = open(path, "rb").read()
    pos, idat = 8, b""
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind, body = data[pos + 4:pos + 8], data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            width, height, depth, color_type = struct.unpack(">IIBB", body[:10])
            assert depth == 8 and color_type == 6, "only 8-bit RGBA PNGs"
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length

    # Each row starts with a byte that says which PNG filter to undo
    raw, stride = zlib.decompress(idat), width * 4
    rows, previous = [], bytearray(stride)
    for y in range(height):
        start = y * (stride + 1)
        kind, line = raw[start], bytearray(raw[start + 1:start + 1 + stride])
        for x in range(stride):
            left = line[x - 4] if x >= 4 else 0
            up = previous[x]
            up_left = previous[x - 4] if x >= 4 else 0
            if kind == 1:
                line[x] = (line[x] + left) & 255
            elif kind == 2:
                line[x] = (line[x] + up) & 255
            elif kind == 3:
                line[x] = (line[x] + (left + up) // 2) & 255
            elif kind == 4:
                guess = left + up - up_left
                distances = [abs(guess - left), abs(guess - up), abs(guess - up_left)]
                line[x] = (line[x] + (left, up, up_left)[distances.index(min(distances))]) & 255
        rows.append([tuple(line[x:x + 4]) for x in range(0, stride, 4)])
        previous = line
    return rows


def scale(pixels, factor):
    out = []
    for row in pixels:
        wide = [p for p in row for _ in range(factor)]
        out.extend([wide] * factor)
    return out


def side_by_side(frames):
    return [sum((frame[y] for frame in frames), []) for y in range(len(frames[0]))]


# ------------------------------------------------------------- the weapons ---
# One weapon per problem type, drawn in the knight's style: the same dark
# outline and the same steel and gold colors. Each is drawn as text, one
# character per pixel, standing straight up. The outline is added afterwards.
# The game recolors the knight with a shader, but not the weapon.

CLEAR = (0, 0, 0, 0)
OUTLINE = "o"
PALETTE = {
    ".": CLEAR,
    "o": (14, 13, 14, 255),     # outline (the knight's)
    "h": (234, 223, 209, 255),  # steel in the light (the knight's)
    "s": (179, 170, 161, 255),  # steel (the knight's)
    "d": (124, 119, 111, 255),  # steel in shade (the knight's)
    "y": (235, 167, 36, 255),   # gold (the knight's)
    "b": (150, 92, 54, 255),    # wood
    "n": (98, 60, 42, 255),     # leather grip
}

# The order is the frame order in weapons.png and must match Weapon.Kind in
# scripts/weapon.gd. grip is the pixel the knight holds; the weapon turns around it.
WEAPONS = [
    {"name": "sword", "grip": (2, 10), "rows": [
        "..s..",
        ".hsd.",
        ".hsd.",
        ".hsd.",
        ".hsd.",
        ".hsd.",
        ".hsd.",
        ".hsd.",
        "yyyyy",
        "..n..",
        "..n..",
        "..y..",
    ]},
    {"name": "spear", "grip": (2, 17), "rows": [
        "..h..",
        ".hsd.",
        ".hsd.",
        ".hsd.",
        "..s..",
        ".yyy.",
        "..b..",
        "..b..",
        "..b..",
        "..b..",
        "..b..",
        "..b..",
        "..b..",
        "..b..",
        "..b..",
        "..b..",
        "..n..",
        "..n..",
        "..b..",
        "..b..",
        "..b..",
    ]},
    {"name": "mace", "grip": (3, 15), "rows": [
        ".s...s.",
        "..hsd..",
        ".hhssd.",
        "shhssds",
        ".hssdd.",
        "..ddd..",
        ".s.y.s.",
        "...b...",
        "...b...",
        "...b...",
        "...b...",
        "...b...",
        "...b...",
        "...n...",
        "...n...",
        "...n...",
        "...y...",
    ]},
    {"name": "axe", "grip": (0, 15), "rows": [
        "b...h..",
        "b..ssh.",
        "bddsssh",
        "bddsssh",
        "bddsssh",
        "b..ssh.",
        "b...h..",
        "b......",
        "b......",
        "b......",
        "b......",
        "b......",
        "b......",
        "n......",
        "n......",
        "n......",
        "b......",
    ]},
]

# Every weapon gets a frame this size, with its grip moved to WEAPON_GRIP.
# Keep these in step with FRAME_SIZE and the offset in scenes/weapon.tscn.
WEAPON_FRAME = (16, 24)
WEAPON_GRIP = (6, 19)


def outlined(rows):
    """Puts the drawing on a grid that is 1 pixel bigger on every side, and
    fills each empty pixel next to the drawing with the outline color."""
    width, height = len(rows[0]) + 2, len(rows) + 2
    grid = [["."] * width for _ in range(height)]
    for y, row in enumerate(rows):
        for x, char in enumerate(row):
            grid[y + 1][x + 1] = char
    for y in range(height):
        for x in range(width):
            if grid[y][x] != ".":
                continue
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < width and 0 <= ny < height and grid[ny][nx] not in (".", OUTLINE):
                    grid[y][x] = OUTLINE
                    break
    return grid


def weapon_frame(weapon):
    grid = outlined(weapon["rows"])
    # +1 because outlined() added a pixel on the left and on the top
    dx = WEAPON_GRIP[0] - (weapon["grip"][0] + 1)
    dy = WEAPON_GRIP[1] - (weapon["grip"][1] + 1)
    frame = [[CLEAR] * WEAPON_FRAME[0] for _ in range(WEAPON_FRAME[1])]
    for y, row in enumerate(grid):
        for x, char in enumerate(row):
            if char != ".":
                assert 0 <= x + dx < WEAPON_FRAME[0] and 0 <= y + dy < WEAPON_FRAME[1], weapon["name"] + " does not fit"
                frame[y + dy][x + dx] = PALETTE[char]
    return frame


def make_weapons():
    save_png("assets/images/weapons.png", side_by_side([weapon_frame(w) for w in WEAPONS]))


# ---------------------------------------------------------------- the icon ---
# The knight with its sword, on the grey of the game's background.

KNIGHT_HAND = (22, 23)  # where the knight holds the weapon in its 32x32 frame


def make_icon():
    knight = [row[0:32] for row in load_png("assets/images/knight.png")[0:32]]  # first idle frame
    sword = weapon_frame(WEAPONS[0])
    picture = [[CLEAR] * 32 for _ in range(32)]
    for layer, dx, dy in ((knight, 0, 0), (sword, KNIGHT_HAND[0] - WEAPON_GRIP[0], KNIGHT_HAND[1] - WEAPON_GRIP[1])):
        for y, row in enumerate(layer):
            for x, pixel in enumerate(row):
                if pixel[3] == 255 and 0 <= x + dx < 32 and 0 <= y + dy < 32:
                    picture[y + dy][x + dx] = pixel

    # Cut away the empty border, then center the picture at 8x on a 192x192 icon
    used = [(x, y) for y, row in enumerate(picture) for x, pixel in enumerate(row) if pixel[3]]
    left, right = min(x for x, _ in used), max(x for x, _ in used)
    top, bottom = min(y for _, y in used), max(y for _, y in used)
    big = scale([row[left:right + 1] for row in picture[top:bottom + 1]], 8)
    grey = (77, 77, 77, 255)
    icon = [[grey] * 192 for _ in range(192)]
    ox, oy = (192 - len(big[0])) // 2, (192 - len(big)) // 2
    for y, row in enumerate(big):
        for x, pixel in enumerate(row):
            if pixel[3]:
                icon[y + oy][x + ox] = pixel
    save_png("icon.png", icon)


# -------------------------------------------------------------- the ground ---
# 576x24 pixels, each drawn as a 4x4 block = 2304x96. It is random speckles in
# bands from grass to soil, so it tiles when two strips sit next to each other.

def make_ground():
    width, height, block = 576, 24, 4
    blade = (176, 214, 84, 255)
    light = (128, 190, 66, 255)
    mid = (86, 152, 64, 255)
    dark = (54, 112, 68, 255)
    soil_top = (40, 80, 76, 255)
    soil = (31, 60, 72, 255)
    soil_dark = (25, 45, 63, 255)

    rng = random.Random(7)  # fixed seed: the same ground every time

    def pick(a, b, chance_b):
        return b if rng.random() < chance_b else a

    rows = []
    for y in range(height):
        row = []
        for _ in range(width):
            if y == 0:
                color = pick(CLEAR, blade, 0.45)  # loose blades sticking up
            elif y == 1:
                color = pick(blade, light, 0.35)
            elif y <= 4:
                color = pick(light, mid, 0.12 + 0.1 * (y - 2))
            elif y <= 8:
                color = pick(mid, dark, 0.15 + 0.15 * (y - 5))
                if y == 5:
                    color = pick(color, light, 0.25)
            elif y <= 12:
                color = pick(dark, soil_top, 0.2 + 0.2 * (y - 9))
            elif y <= 17:
                color = pick(soil_top, soil, 0.15 + 0.17 * (y - 13))
            else:
                color = pick(soil, soil_dark, 0.12 + 0.14 * (y - 18))
            row.append(color)
        rows.append(row)
    save_png("assets/images/ground.png", scale(rows, block))


if __name__ == "__main__":
    make_weapons()
    make_icon()
    make_ground()
    print("Assets written to assets/ and icon.png")

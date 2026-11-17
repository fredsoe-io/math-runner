"""Generates the art for Math Runner: the dino, the life icons, the app icon
and the ground. The sounds are recordings and are not made here.

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


def scale(pixels, factor):
    out = []
    for row in pixels:
        wide = [p for p in row for _ in range(factor)]
        out.extend([wide] * factor)
    return out


# ---------------------------------------------------------------- the dino ---
# Drawn as text, one character per pixel. The game recolors it with a shader,
# so this red dino is the Addasaurus and the others are the same picture.
# It is built from loose parts (head, body, arms, legs), so a frame of the
# animation is just the same parts moved a pixel or two.

SIZE = 24
CLEAR = (0, 0, 0, 0)
PALETTE = {
    ".": CLEAR,
    "o": (30, 22, 34, 255),     # outline, pupil, mouth
    "b": (226, 88, 62, 255),    # body
    "d": (170, 54, 58, 255),    # darker spots, and the arm and leg on the far side
    "c": (255, 222, 150, 255),  # belly
    "y": (228, 168, 78, 255),   # belly in shade
    "w": (255, 255, 255, 255),  # eye
}
USED_PALETTE = {char: (CLEAR if char == "." else (46, 42, 50, 255)) for char in PALETTE}

HEAD = [
    "........................",
    ".............bbbbbb.....",
    "...........bbbbbbbbbb...",
    "..........bbbwobbbbbbb..",
    "..........bbbwobbbbdbb..",
    "..........bbbbbbbbbbbb..",
    "..........bbbbboooooo...",
    "...........bbbbbbbbb....",
    "............bbbbbb......",
]
BODY = [
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "............bbbbc.......",
    "..........bbbbbccc......",
    ".........bdbbbbccc......",
    ".b......bbbbbbbcccc.....",
    ".bb....bbbbdbbbcccc.....",
    ".bbb..bbbbbbbbbcccy.....",
    "..bbbbbdbbbbbbbccyy.....",
    "...bbbbbbbbbbbbbyy......",
    ".....dbbbbbbbbbb........",
]
# Arms and legs are lists of (x, y) pixels, counted from the shoulder or hip
LEG = [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (0, 3), (1, 3), (2, 3), (3, 3)]
LEG_LIFTED = [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (1, 2), (2, 2), (3, 2)]
NEAR_ARM = [(0, 0), (1, 0), (2, 0), (2, 1)]
FAR_ARM = [(0, 0), (1, 0), (1, 1)]
NEAR_HIP = (11, 16)
FAR_HIP = (8, 16)
NEAR_SHOULDER = (17, 10)
FAR_SHOULDER = (19, 12)


def cells_from_rows(rows, dx=0, dy=0):
    cells = {}
    for y, row in enumerate(rows):
        for x, char in enumerate(row):
            if char != ".":
                cells[(x + dx, y + dy)] = char
    return cells


def cells_from_points(points, origin, char, dx=0, dy=0):
    return {(origin[0] + x + dx, origin[1] + y + dy): char for x, y in points}


def stamp(grid, cells):
    """Draws a part with its own dark outline, on top of what is already there."""
    for (x, y) in cells:
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if (nx, ny) not in cells and 0 <= nx < SIZE and 0 <= ny < SIZE:
                grid[ny][nx] = "o"
    for (x, y), char in cells.items():
        if 0 <= x < SIZE and 0 <= y < SIZE:
            grid[y][x] = char


def blank():
    return [["."] * SIZE for _ in range(SIZE)]


def dino_frame(bob=0, head=0, near_arm=0, far_arm=0, near_leg=(0, False), far_leg=(0, False)):
    """bob moves everything but the legs down, head moves the head down on top
    of that, the arms move up (negative) or down. A leg is (dx, lifted)."""
    grid = blank()
    stamp(grid, cells_from_points(LEG_LIFTED if far_leg[1] else LEG, FAR_HIP, "d", far_leg[0]))
    stamp(grid, cells_from_points(FAR_ARM, FAR_SHOULDER, "d", 0, bob + far_arm))
    upper = cells_from_rows(BODY, 0, bob)
    upper.update(cells_from_rows(HEAD, 0, bob + head))
    stamp(grid, upper)
    stamp(grid, cells_from_points(LEG_LIFTED if near_leg[1] else LEG, NEAR_HIP, "b", near_leg[0]))
    stamp(grid, cells_from_points(NEAR_ARM, NEAR_SHOULDER, "b", 0, bob + near_arm))
    return grid


def head_frame():
    grid = blank()
    stamp(grid, cells_from_rows(HEAD, -4, 7))  # roughly centered
    return grid


def to_pixels(grid, palette=PALETTE):
    return [[palette[char] for char in row] for row in grid]


def side_by_side(frames):
    return [sum((frame[y] for frame in frames), []) for y in range(len(frames[0]))]


def make_dino():
    # Idle: the hands move and the head bobs
    idle = [
        dino_frame(head=0, near_arm=0, far_arm=0),
        dino_frame(head=0, near_arm=1, far_arm=0),
        dino_frame(head=1, near_arm=1, far_arm=1),
        dino_frame(head=1, near_arm=0, far_arm=1),
    ]
    run = [
        dino_frame(0, 0, 0, 1, (2, False), (-2, False)),
        dino_frame(1, 0, 0, 1, (1, False), (-1, False)),
        dino_frame(0, 1, 1, 0, (0, False), (0, True)),
        dino_frame(0, 0, 1, 0, (-2, False), (2, False)),
        dino_frame(1, 0, 1, 0, (-1, False), (1, False)),
        dino_frame(0, 1, 0, 1, (0, True), (0, False)),
    ]
    # Jump: arms up, legs pulled up and apart
    jump = dino_frame(0, 0, -2, -1, (2, True), (-2, True))
    # Frame 0-3 idle, 4-9 running, 11 jumping (10 is a spare copy of the jump)
    save_png("assets/images/dino.png", side_by_side([to_pixels(f) for f in idle + run + [jump, jump]]))

    # Frame 0 = a full life, frame 1 = a used life
    head = head_frame()
    save_png("assets/images/life.png", side_by_side([to_pixels(head), to_pixels(head, USED_PALETTE)]))

    # The app icon: the dino on the grey of the game's background
    grey = (77, 77, 77, 255)
    big = scale(to_pixels(dino_frame()), 7)
    icon = [[grey] * 192 for _ in range(192)]
    for y, row in enumerate(big):
        for x, pixel in enumerate(row):
            if pixel[3]:
                icon[y + 16][x + 12] = pixel
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
    make_dino()
    make_ground()
    print("Assets written to assets/ and icon.png")

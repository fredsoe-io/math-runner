"""Generates the art and sounds for Math Runner: the dino, the life icons, the
app icon, the ground and the correct/wrong sounds.

Run it from the project folder with `python3 tools/make_assets.py`.
It only needs Python 3, no extra packages.
"""
import math
import random
import struct
import wave
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

SIZE = 24
CLEAR = (0, 0, 0, 0)
PALETTE = {
    ".": CLEAR,
    "o": (52, 32, 46, 255),     # outline, pupil, mouth
    "b": (226, 88, 62, 255),    # body
    "d": (170, 54, 58, 255),    # body in shade
    "c": (255, 220, 164, 255),  # belly
    "s": (255, 170, 60, 255),   # plates on the back
    "w": (255, 255, 255, 255),  # eye
}
USED_PALETTE = {char: (CLEAR if char == "." else (46, 42, 50, 255)) for char in PALETTE}

# Head, body and tail. The legs are drawn separately so they can move.
UPPER = [
    "........................",
    "........................",
    "........................",
    "........................",
    ".............bbbbbbb....",
    "............bbbbwobbd...",
    "............bbbbbbbbb...",
    "............bbbbboooo...",
    "...........sbbbbbbb.....",
    "............bbbbc.......",
    "..........sbbbbbcc......",
    "...........bbbbbccbb....",
    ".b......sbbbbbbbcc......",
    ".bbb..bbbbbbbbbbc.......",
    "...bbbbbbbbbbbbb........",
    ".....ddddbbbbbb.........",
]
HEAD_ROWS = range(4, 9)   # the rows of UPPER that make up the head
HEAD_FIRST_COLUMN = 11
LEG_ROW = 16              # first row of the legs when standing
LEG_LENGTH = 4
NEAR_LEG_X = 11           # hip position; dx moves a leg forwards or backwards
FAR_LEG_X = 9


def blank():
    return [["."] * SIZE for _ in range(SIZE)]


def put(grid, x, y, char):
    if 0 <= x < SIZE and 0 <= y < SIZE:
        grid[y][x] = char


def draw_leg(grid, x, char, lifted):
    top = LEG_ROW - (1 if lifted else 0)
    for row in range(top, top + LEG_LENGTH):
        put(grid, x, row, char)
        put(grid, x + 1, row, char)
    put(grid, x + 2, top + LEG_LENGTH - 1, char)  # the foot points forwards


def add_outline(grid):
    result = [row[:] for row in grid]
    for y in range(SIZE):
        for x in range(SIZE):
            if grid[y][x] != ".":
                continue
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < SIZE and 0 <= ny < SIZE and grid[ny][nx] != ".":
                    result[y][x] = "o"
                    break
    return result


def dino_frame(bob=0, near=(2, False), far=(-2, False)):
    """bob moves the body down. near and far are (dx, lifted) for each leg."""
    grid = blank()
    draw_leg(grid, FAR_LEG_X + far[0], "d", far[1])
    draw_leg(grid, NEAR_LEG_X + near[0], "b", near[1])
    for y, row in enumerate(UPPER):
        for x, char in enumerate(row):
            if char != ".":
                put(grid, x, y + bob, char)
    return add_outline(grid)


def head_frame():
    grid = blank()
    for y in HEAD_ROWS:
        for x in range(HEAD_FIRST_COLUMN, SIZE):
            if UPPER[y][x] != ".":
                put(grid, x - 4, y + 5, UPPER[y][x])  # roughly centered
    return add_outline(grid)


def to_pixels(grid, palette=PALETTE):
    return [[palette[char] for char in row] for row in grid]


def side_by_side(frames):
    return [sum((frame[y] for frame in frames), []) for y in range(len(frames[0]))]


def make_dino():
    idle = [dino_frame(), dino_frame(), dino_frame(bob=1), dino_frame(bob=1)]
    run = [
        dino_frame(0, (2, False), (-2, False)),
        dino_frame(1, (1, False), (-1, False)),
        dino_frame(0, (0, False), (0, True)),
        dino_frame(0, (-2, False), (2, False)),
        dino_frame(1, (-1, False), (1, False)),
        dino_frame(0, (0, True), (0, False)),
    ]
    jump = dino_frame(-1, (-1, True), (-3, True))
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


# -------------------------------------------------------------- the sounds ---
# 44.1 kHz, mono, 16 bit.

RATE = 44100
SOFT_SQUARE = [(1, 1.0), (3, 0.33), (5, 0.2)]
BUZZ = [(1, 1.0), (2, 0.5), (3, 0.33), (4, 0.25), (5, 0.2), (6, 0.17)]


def tone(frequency, seconds, volume, decay, harmonics):
    samples = []
    for i in range(int(RATE * seconds)):
        t = i / RATE
        value = 0.0
        for number, weight in harmonics:
            value += weight * math.sin(2 * math.pi * frequency * number * t)
        envelope = math.exp(-decay * t) * min(1.0, i / 60.0)  # short fade-in avoids a click
        samples.append(value * envelope * volume)
    return samples


def save_wav(path, samples):
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))


def make_sounds():
    # correct: a quick rising two-note chime (B5 -> E6), like picking up a coin
    save_wav("assets/sounds/correct.wav", tone(987.77, 0.08, 0.3, 3, SOFT_SQUARE) + tone(1318.51, 0.4, 0.3, 9, SOFT_SQUARE))
    # wrong: a low falling two-note buzz (G3 -> D3)
    save_wav("assets/sounds/wrong.wav", tone(196.0, 0.16, 0.3, 2, BUZZ) + tone(146.83, 0.38, 0.3, 6, BUZZ))


if __name__ == "__main__":
    make_dino()
    make_ground()
    make_sounds()
    print("Assets written to assets/ and icon.png")

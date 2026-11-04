#!/usr/bin/env python3
"""Persona-style greeting: spinning red starburst, white domino mask with glinting eyes,
and a white slash behind it, next to fastfetch output.
Glitches in, keeps animating in place until the shell kills it (see fish config).
Same protocol as cyber.py. Half-block pixels: the canvas is W x 2H pixels.
`python3 persona.py --still` prints one frame (for previewing)."""
import functools, math, os, random, re, subprocess, sys, time

W, H = 44, 22
PW, PH = W, H * 2
FPS = 15
CX, CY = 22, 21.5                        # centre of burst + mask (pixels)

RED = (230, 0, 18)
RED_D = (150, 0, 12)
RED_HI = (255, 60, 60)
BLK = (10, 10, 12)
WHT = (245, 243, 236)
GREY = (190, 188, 182)
GLITCH = (RED, WHT, BLK, RED_HI)

def mix(a, b, t):
    t = 0.0 if t < 0 else 1.0 if t > 1 else t
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)

def info():
    cfg = os.path.expanduser("~/.config/fastfetch/persona.jsonc")
    out = subprocess.run(["fastfetch", "--logo", "none", "--pipe", "false", "-c", cfg],
                         capture_output=True, text=True).stdout
    return out.rstrip("\n").split("\n")

# ── shapes ──────────────────────────────────────────────────────────────────────
SPIKES, R_IN, R_OUT = 13, 11.5, 17.5

def burst_r(theta, t):
    """Radius of the jagged starburst at angle theta (spikes of uneven length)."""
    a = (theta + t * 0.35) * SPIKES / (2 * math.pi)
    k, f = int(math.floor(a)), a - math.floor(a)
    tri = 1 - abs(2 * f - 1)                                   # 0 at valleys, 1 at tips
    jag = 0.75 + 0.25 * ((k * 7919) % 5) / 4                   # uneven spike lengths
    return R_IN + (R_OUT - R_IN) * tri * jag

MASK_S = 17.5                                # pixels per mask unit

@functools.cache
def mask_at(x, y):
    """0 outside, 1 mask body, 2 eye hole."""
    u, v = (x + 0.5 - CX) / MASK_S, (y + 0.5 - CY) / MASK_S
    if abs(u) >= 1:
        return 0
    au = abs(u)
    centre = -0.30 * au ** 3 + 0.02                            # tips sweep upward
    top = centre - 0.36 * (1 - au ** 2.4) ** 0.7
    bot = centre + 0.30 * (1 - au ** 2.6) ** 0.8 - 0.16 * math.exp(-u * u / 0.012)  # nose notch
    if not (top < v < bot):
        return 0
    # angled eye slits, outer corners raised
    eu, ev = au - 0.42, v + 0.03 + 0.35 * (au - 0.42)
    if (eu / 0.23) ** 2 + (ev / 0.12) ** 2 < 1:
        return 2
    return 1

def slash_at(x, y):
    """Diagonal white slash from bottom-left to top-right: 0 none, 1 edge, 2 fill."""
    d = (x - CX) * 0.55 + (y - CY) * 1.0 - 1.5   # signed distance-ish to the line
    d /= 1.14
    if abs(d) < 2.0:
        return 2
    if abs(d) < 3.0:
        return 1
    return 0

# ── frame ───────────────────────────────────────────────────────────────────────
@functools.cache
def _static():
    """Everything that is the same every frame, worked out once."""
    dots, slash, polar, mask = [], [], [], []
    for y in range(PH):
        for x in range(PW):
            if not ((x + y) % 2 or y % 2):                     # halftone dot grid
                corner = max(0.0, (math.hypot(x - CX, y - CY) - 16) / 10)
                if corner > 0.5:                               # can ever pass the threshold below
                    dots.append((x, y, corner))
            s = slash_at(x, y)
            if s:
                slash.append((x, y, WHT if s == 2 else BLK))
            dx, dy = x + 0.5 - CX, y + 0.5 - CY
            d = math.hypot(dx, dy)
            if d < R_OUT + 0.5:                                # could be inside the burst
                polar.append((x, y, d, math.atan2(dy, dx),
                              (x + y) % 2 == 0 and y % 2 == 0, d < 9 and (x * 3 + y) % 11 == 0))
            m = mask_at(x, y)
            if m == 1:
                shade = WHT if (y + 0.5 - CY) < 1 else mix(WHT, GREY, 0.6)
                edge = any(mask_at(x + a, y + b) == 0 for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                mask.append((x, y, BLK if edge else shade))
            elif m == 2 or mask_at(x - 1, y - 1) == 1:         # eye holes, offset shadow
                mask.append((x, y, BLK))
    return dots, slash, polar, mask

def canvas(t=0.0):
    dots, slash, polar, mask = _static()
    px = [[None] * PW for _ in range(PH)]
    # halftone dots drifting in the corners
    for x, y, corner in dots:
        wave = 0.5 + 0.5 * math.sin(x * 0.4 - y * 0.3 + t * 2)
        if corner * (0.6 + 0.4 * wave) > 0.5:
            px[y][x] = mix(RED_D, RED, wave * 0.6)
    # slash behind everything else
    for x, y, c in slash:
        px[y][x] = c
    # starburst
    flash = (t % 3.2) < 0.18                                   # eye flash every few seconds
    for x, y, d, theta, dotted, sparkle in polar:
        r = burst_r(theta, t)
        if d < r:
            px[y][x] = BLK if d > r - 1.3 else RED_D if d > r * 0.62 and dotted else RED_HI if sparkle else RED
    # mask with outline + drop shadow
    for x, y, c in mask:
        px[y][x] = c
    # glinting eyes: a red pupil slides along each slit
    for side in (-1, 1):
        ex = CX + side * 0.43 * MASK_S
        ey = CY - 0.03 * MASK_S
        off = math.sin(t * 1.3) * 1.5
        for gx, gy in ((0, 0), (1, 0), (0, -1) if flash else (0, 0)):
            x, y = int(ex + off + gx), int(ey + gy)
            if mask_at(x, y) == 2:
                px[y][x] = RED_HI if not flash else WHT
        if flash:
            for y in range(int(ey) - 2, int(ey) + 3):
                for x in range(int(ex) - 4, int(ex) + 5):
                    if mask_at(x, y) == 2 and px[y][x] == BLK:
                        px[y][x] = RED
    return px

def _c(c): return _ci(int(c[0]), int(c[1]), int(c[2]))

@functools.lru_cache(maxsize=8192)
def _ci(r, g, b): return f"{r};{g};{b}"

def render(px, glitch=0.0, rnd=None):
    rows = []
    for r in range(H):
        top, bot = px[2 * r], px[2 * r + 1]
        shift = rnd.randint(-4, 4) if glitch and rnd.random() < glitch else 0
        out, fg, bg = [], None, None
        for c in range(W):
            sc = c - shift
            a = top[sc] if 0 <= sc < W else None
            b = bot[sc] if 0 <= sc < W else None
            if glitch and (a or b) and rnd.random() < glitch * .25:
                a, b, ch = rnd.choice(GLITCH), None, rnd.choice("░▒▓/\\▌▐█")
            elif a and b:
                ch = "▀"
            elif a or b:
                a, b, ch = (a or b), None, "▀" if a else "▄"
            else:
                ch = " "
            nf, nb = (_c(a) if a else fg), (_c(b) if b else None)
            if ch != " " and nf != fg:
                out.append(f"\x1b[38;2;{nf}m"); fg = nf
            if nb != bg:
                out.append(f"\x1b[48;2;{nb}m" if nb else "\x1b[49m"); bg = nb
            out.append(ch)
        rows.append("".join(out) + "\x1b[0m")
    return rows

def cursor_row():
    """Ask the terminal where the cursor is (1-based row), or None."""
    import select, termios, tty
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        sys.stdout.write("\x1b[6n"); sys.stdout.flush()
        buf = ""
        while not buf.endswith("R"):
            if not select.select([fd], [], [], 0.3)[0]:
                return None
            buf += os.read(fd, 32).decode(errors="ignore")
        m = re.search(r"\x1b\[(\d+);(\d+)R", buf)
        return int(m.group(1)) if m else None
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)

def main():
    if "--still" in sys.argv:
        print("\n".join(render(canvas(float(os.environ.get("T", "0.5")))))); return
    pidfile = sys.argv[1] if len(sys.argv) > 1 else None   # where the shell looks for us
    text = info()
    rows = max(H, len(text))
    ok = sys.stdin.isatty() and sys.stdout.isatty()
    size = os.get_terminal_size() if ok else None
    top = max(0, (rows - H) // 2)
    itop = max(0, (rows - len(text)) // 2)

    def layout(d):
        out = []
        for r in range(rows):
            left = d[r - top] if 0 <= r - top < H else " " * W
            ti = r - itop
            right = text[ti] if 0 <= ti < len(text) else ""
            out.append(f"{left}  {right}\x1b[K")
        return out

    still = render(canvas(0))
    if not ok or size.columns < W + 4 + 40:
        print("\n".join(layout(still) if ok else text)); return
    sys.stdout.write("\n".join(layout(still)) + "\n"); sys.stdout.flush()
    row = cursor_row()
    if not pidfile or row is None or row - rows < 1:
        return
    first = row - rows                       # 1-based row of the first printed line
    if os.fork():                            # parent returns => prompt shows right away
        return
    import signal
    for sig in (signal.SIGTERM, signal.SIGHUP, signal.SIGINT):
        signal.signal(sig, lambda *_: sys.exit(0))
    with open(pidfile, "w") as f:
        f.write(str(os.getpid()))
    fd = os.open("/dev/tty", os.O_WRONLY)
    rnd = random.Random()
    t0 = time.monotonic()
    try:
        k = 0
        while True:
            if os.get_terminal_size(fd) != size:
                return
            t = time.monotonic() - t0
            glitch = max(0.0, 0.55 - k / 16)                   # glitchy intro
            if (t % 5.3) > 5.1:                                # plus a short twitch now and then
                glitch = 0.3
            d = render(canvas(t), glitch, rnd)
            buf = "\x1b7"
            for i, line in enumerate(d):
                buf += f"\x1b[{first + top + i};1H{line}"
            buf += "\x1b8"
            os.write(fd, buf.encode())
            k += 1
            time.sleep(max(0.0, k / FPS - (time.monotonic() - t0)))
    finally:
        try: os.remove(pidfile)
        except OSError: pass

if __name__ == "__main__":
    main()

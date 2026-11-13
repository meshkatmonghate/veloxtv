import os
import math
import struct
import zlib

def write_ico(filename, png_bytes_list):
    """Writes a multi-resolution Windows ICO file containing PNG streams."""
    os.makedirs(os.path.dirname(os.path.abspath(filename)), exist_ok=True)
    count = len(png_bytes_list)
    header = struct.pack("<HHH", 0, 1, count)
    entries = bytearray()
    offset = 6 + count * 16
    data_bytes = bytearray()
    
    for size, png_data in png_bytes_list:
        w_byte = 0 if size >= 256 else size
        h_byte = 0 if size >= 256 else size
        entry = struct.pack("<BBBBHHII", w_byte, h_byte, 0, 0, 1, 32, len(png_data), offset)
        entries.extend(entry)
        data_bytes.extend(png_data)
        offset += len(png_data)
        
    with open(filename, "wb") as f:
        f.write(header + entries + data_bytes)

def write_png(filename, width, height, pixels):
    """Writes an RGBA PNG file using only standard python library."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack(">I", zlib.crc32(c) & 0xffffffff)
        return struct.pack(">I", len(data)) + c + crc

    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0) # filter type 0: None
        for x in range(width):
            r, g, b, a = pixels[y][x]
            raw_data.extend([r, g, b, a])

    compressed = zlib.compress(bytes(raw_data), level=9)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", compressed) + chunk(b"IEND", b"")
    
    if filename:
        os.makedirs(os.path.dirname(os.path.abspath(filename)), exist_ok=True)
        with open(filename, "wb") as f:
            f.write(png)
    return png

def point_in_poly(x, y, poly):
    n = len(poly)
    inside = False
    p1x, p1y = poly[0]
    for i in range(n + 1):
        p2x, p2y = poly[i % n]
        if y > min(p1y, p2y):
            if y <= max(p1y, p2y):
                if x <= max(p1x, p2x):
                    if p1y != p2y:
                        xinters = (y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                    if p1x == p2x or x <= xinters:
                        inside = not inside
        p1x, p1y = p2x, p2y
    return inside

def dist_to_segment(px, py, x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    if dx == 0 and dy == 0:
        return math.hypot(px - x1, py - y1)
    t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    nearest_x = x1 + t * dx
    nearest_y = y1 + t * dy
    return math.hypot(px - nearest_x, py - nearest_y)

def dist_to_poly_boundary(px, py, poly):
    min_d = 1e9
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        d = dist_to_segment(px, py, x1, y1, x2, y2)
        if d < min_d:
            min_d = d
    return min_d

def render_icon(size):
    w, h = size, size
    pixels = [[(0, 0, 0, 0) for _ in range(w)] for _ in range(h)]
    
    # Normalized bolt polygon coordinates (0.0 to 1.0)
    base_bolt = [
        (0.53, 0.20),
        (0.66, 0.44),
        (0.54, 0.44),
        (0.61, 0.80),
        (0.36, 0.52),
        (0.48, 0.52),
    ]
    bolt_poly = [(p[0] * w, p[1] * h) for p in base_bolt]
    
    cx, cy = w / 2.0, h / 2.0
    corner_radius = w * 0.26
    
    for y in range(h):
        for x in range(w):
            # Squircle / rounded box test
            dx = abs(x - cx)
            dy = abs(y - cy)
            
            # Distance from center for rounded square
            straight = w * 0.44
            if dx > straight - corner_radius and dy > straight - corner_radius:
                rx = dx - (straight - corner_radius)
                ry = dy - (straight - corner_radius)
                d_corner = math.hypot(rx, ry)
                if d_corner > corner_radius:
                    # Outside icon boundary (transparent)
                    pixels[y][x] = (0, 0, 0, 0)
                    continue
            elif dx > straight or dy > straight:
                pixels[y][x] = (0, 0, 0, 0)
                continue

            # Inside icon background: Dark radial gradient
            norm_d = math.hypot(dx, dy) / (w * 0.6)
            bg_r = int(22 * (1.0 - norm_d * 0.4))
            bg_g = int(27 * (1.0 - norm_d * 0.4))
            bg_b = int(42 * (1.0 - norm_d * 0.4))
            
            # Check bolt
            inside = point_in_poly(x, y, bolt_poly)
            d_edge = dist_to_poly_boundary(x, y, bolt_poly)
            
            if inside:
                # Vertical gradient for lightning bolt (Cyan to Electric Violet)
                t = (y - 0.2 * h) / (0.6 * h)
                t = max(0.0, min(1.0, t))
                bolt_r = int(0 * (1 - t) + 168 * t)
                bolt_g = int(229 * (1 - t) + 85 * t)
                bolt_b = int(255)
                
                # Antialiased inner edge
                if d_edge < 1.5:
                    alpha = d_edge / 1.5
                    r = int(bolt_r * alpha + bg_r * (1 - alpha))
                    g = int(bolt_g * alpha + bg_g * (1 - alpha))
                    b = int(bolt_b * alpha + bg_b * (1 - alpha))
                    pixels[y][x] = (r, g, b, 255)
                else:
                    pixels[y][x] = (bolt_r, bolt_g, bolt_b, 255)
            else:
                # Cyan Glow aura around bolt
                glow_max = w * 0.08
                if d_edge < glow_max:
                    glow_intensity = math.exp(-d_edge / (glow_max * 0.35)) * 0.65
                    r = min(255, int(bg_r + 0 * glow_intensity))
                    g = min(255, int(bg_g + 229 * glow_intensity))
                    b = min(255, int(bg_b + 255 * glow_intensity))
                    pixels[y][x] = (r, g, b, 255)
                else:
                    pixels[y][x] = (bg_r, bg_g, bg_b, 255)

    return pixels

def render_banner(w, h):
    pixels = [[(0, 0, 0, 255) for _ in range(w)] for _ in range(h)]
    base_bolt = [
        (0.24, 0.22),
        (0.29, 0.48),
        (0.25, 0.48),
        (0.28, 0.78),
        (0.18, 0.54),
        (0.22, 0.54),
    ]
    bolt_poly = [(p[0] * w, p[1] * h) for p in base_bolt]
    
    for y in range(h):
        for x in range(w):
            # Dark futuristic gradient
            bg_r = int(15 + 10 * (x / w))
            bg_g = int(18 + 8 * (x / w))
            bg_b = int(28 + 18 * (y / h))
            
            inside = point_in_poly(x, y, bolt_poly)
            d_edge = dist_to_poly_boundary(x, y, bolt_poly)
            
            if inside:
                t = (y - 0.22 * h) / (0.56 * h)
                bolt_r = int(0 * (1 - t) + 168 * t)
                bolt_g = int(229 * (1 - t) + 85 * t)
                bolt_b = 255
                pixels[y][x] = (bolt_r, bolt_g, bolt_b, 255)
            elif d_edge < 18:
                glow = math.exp(-d_edge / 6.0) * 0.6
                r = min(255, int(bg_r + 0 * glow))
                g = min(255, int(bg_g + 229 * glow))
                b = min(255, int(bg_b + 255 * glow))
                pixels[y][x] = (r, g, b, 255)
            else:
                pixels[y][x] = (bg_r, bg_g, bg_b, 255)
    return pixels

def main():
    root = r"C:\Users\meshk\.gemini\antigravity\scratch\veloxtv"
    
    # 1. Master Icon
    print("Generating Master 512x512 app_icon.png...")
    px512 = render_icon(512)
    write_png(os.path.join(root, "assets", "icon", "app_icon.png"), 512, 512, px512)
    
    # 2. Android Mipmaps
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    
    for folder, size in sizes.items():
        print(f"Generating Android {folder} ({size}x{size})...")
        px = render_icon(size)
        out_path = os.path.join(root, "android", "app", "src", "main", "res", folder, "ic_launcher.png")
        write_png(out_path, size, size, px)
        
    # 3. Android TV Leanback Banner (320x180)
    print("Generating Android TV Banner (320x180)...")
    banner_px = render_banner(320, 180)
    write_png(os.path.join(root, "android", "app", "src", "main", "res", "drawable", "tv_banner.png"), 320, 180, banner_px)
    
    # 4. Windows app_icon.ico
    print("Generating Windows app_icon.ico...")
    px48 = render_icon(48)
    png48 = write_png(None, 48, 48, px48)
    px256 = render_icon(256)
    png256 = write_png(None, 256, 256, px256)
    write_ico(os.path.join(root, "windows", "runner", "resources", "app_icon.ico"), [(48, png48), (256, png256)])
    
    print("Done! All VeloxTV icons generated successfully.")

if __name__ == "__main__":
    main()

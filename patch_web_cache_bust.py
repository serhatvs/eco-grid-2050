import os, shutil, re

web_dir = r"C:\Users\serhat\eco-grid-2050\build\web"
pck_path = os.path.join(web_dir, "index.pck")
v3_pck_path = os.path.join(web_dir, "ecogrid_v3.pck")

# 1. Create ecogrid_v3.pck from fresh index.pck
if not os.path.exists(pck_path):
    print("ERROR: index.pck does not exist in build/web! Run Godot export first.")
    exit(1)

shutil.copy2(pck_path, v3_pck_path)
pck_size = os.path.getsize(v3_pck_path)
print(f"Created ecogrid_v3.pck ({pck_size} bytes)")

# 2. Update index.html
html_path = os.path.join(web_dir, "index.html")
with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

# Add meta cache headers if not present
meta_headers = '''		<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
		<meta http-equiv="Pragma" content="no-cache">
		<meta http-equiv="Expires" content="0">
'''
if '<meta http-equiv="Cache-Control"' not in html:
    html = html.replace('<meta charset="utf-8">', '<meta charset="utf-8">\n' + meta_headers)

# Update GODOT_CONFIG to load ecogrid_v3.pck
# The GODOT_CONFIG line looks like: const GODOT_CONFIG = {"args":[],"canvasResizePolicy":2,"ensureCrossOriginIsolationHeaders":false,"executable":"index","experimentalVK":false,"fileSizes":{"index.pck":...},"focusCanvas":true,"gdextensionLibs":[]};
html = re.sub(r'"fileSizes":\{"[^"]+":\d+,', f'"mainPack":"ecogrid_v3.pck","fileSizes":{{"ecogrid_v3.pck":{pck_size},', html)

# Make sure mainPack is set if it was previously set or not
if '"mainPack"' not in html:
    html = html.replace('"fileSizes"', f'"mainPack":"ecogrid_v3.pck","fileSizes"')

# Update index.js script tag with v=3 query string for cache busting
html = re.sub(r'<script src="index\.js(\?v=\d+)?"></script>', '<script src="index.js?v=3"></script>', html)

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html)

print("Updated index.html with cache-busting headers and ecogrid_v3.pck successfully!")

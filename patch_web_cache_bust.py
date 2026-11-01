import os, shutil

web_dir = r"C:\Users\serhat\eco-grid-2050\build\web"
pck_path = os.path.join(web_dir, "index.pck")
v2_pck_path = os.path.join(web_dir, "ecogrid_v2.pck")

# 1. Create ecogrid_v2.pck
shutil.copy2(pck_path, v2_pck_path)
pck_size = os.path.getsize(v2_pck_path)
print(f"Created ecogrid_v2.pck ({pck_size} bytes)")

# 2. Update index.html
html_path = os.path.join(web_dir, "index.html")
with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

# Add meta cache headers
meta_headers = '''		<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
		<meta http-equiv="Pragma" content="no-cache">
		<meta http-equiv="Expires" content="0">
'''
if '<meta http-equiv="Cache-Control"' not in html:
    html = html.replace('<meta charset="utf-8">', '<meta charset="utf-8">\n' + meta_headers)

# Update GODOT_CONFIG to load ecogrid_v2.pck
import re
html = re.sub(r'"fileSizes":\{"[^"]+":\d+,', f'"mainPack":"ecogrid_v2.pck","fileSizes":{{"ecogrid_v2.pck":{pck_size},', html)

# Update index.js script tag
html = html.replace('<script src="index.js"></script>', '<script src="index.js?v=2"></script>')

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html)

print("Updated index.html with cache-busting headers and ecogrid_v2.pck!")

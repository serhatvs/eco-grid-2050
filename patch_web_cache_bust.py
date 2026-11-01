import os, shutil, re

web_dir = r"C:\Users\serhat\eco-grid-2050\build\web"
pck_path = os.path.join(web_dir, "index.pck")
v4_pck_path = os.path.join(web_dir, "ecogrid_v4.pck")

if not os.path.exists(pck_path):
    print("ERROR: index.pck does not exist in build/web! Run Godot export first.")
    exit(1)

shutil.copy2(pck_path, v4_pck_path)
pck_size = os.path.getsize(v4_pck_path)
print(f"Created ecogrid_v4.pck ({pck_size} bytes)")

html_path = os.path.join(web_dir, "index.html")
with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

# Update or insert mainPack
if '"mainPack"' in html:
    html = re.sub(r'"mainPack":"[^"]+"', '"mainPack":"ecogrid_v4.pck"', html)
else:
    html = html.replace('"fileSizes"', '"mainPack":"ecogrid_v4.pck","fileSizes"')

# Update fileSizes
html = re.sub(r'"fileSizes":\{"[^"]+":\d+,', f'"fileSizes":{{"ecogrid_v4.pck":{pck_size},', html)

# Update index.js query param to v=4
html = re.sub(r'<script src="index\.js(\?v=\d+)?"></script>', '<script src="index.js?v=4"></script>', html)

# Ensure aggressive unregister / cache-killer script is right after <head>
sw_killer = '''<script>
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function(regs) {
        for (let r of regs) r.unregister();
    });
}
if ('caches' in window) {
    caches.keys().then(function(names) {
        for (let n of names) caches.delete(n);
    });
}
</script>
'''
if 'if (\'serviceWorker\' in navigator)' not in html:
    html = html.replace('<head>', '<head>\n' + sw_killer)

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html)

print("Updated index.html with ecogrid_v4.pck successfully!")

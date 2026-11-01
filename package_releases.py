import os, zipfile

desktop = r"C:\Users\serhat\Desktop"
web_build = r"C:\Users\serhat\eco-grid-2050\build\web"
win_build = r"C:\Users\serhat\eco-grid-2050\build\windows"

# 1. Package Web Build
web_zip_path = os.path.join(desktop, "Eco-Grid-2050-Web.zip")
if os.path.exists(web_zip_path):
    os.remove(web_zip_path)

with zipfile.ZipFile(web_zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(web_build):
        for f in files:
            full_p = os.path.join(root, f)
            rel_p = os.path.relpath(full_p, web_build)
            zf.write(full_p, rel_p)

print(f"Created {web_zip_path} ({os.path.getsize(web_zip_path)} bytes)")

# 2. Package Windows Build
win_zip_path = os.path.join(desktop, "Eco-Grid-2050-Windows.zip")
if os.path.exists(win_zip_path):
    os.remove(win_zip_path)

with zipfile.ZipFile(win_zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(win_build):
        for f in files:
            full_p = os.path.join(root, f)
            rel_p = os.path.relpath(full_p, win_build)
            zf.write(full_p, rel_p)

print(f"Created {win_zip_path} ({os.path.getsize(win_zip_path)} bytes)")

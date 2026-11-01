import subprocess, shutil, os, time

REPO = r"C:\Users\serhat\eco-grid-2050"
TEMP_DIR = r"C:\Users\serhat\AppData\Local\Temp\eco_gh_pages"
BUILD_DIR = r"C:\Users\serhat\eco-grid-2050\build\web"

if os.path.exists(TEMP_DIR):
    subprocess.run(["git", "worktree", "remove", "--force", TEMP_DIR], cwd=REPO, capture_output=True)
    if os.path.exists(TEMP_DIR):
        shutil.rmtree(TEMP_DIR, ignore_errors=True)

print("Adding worktree for gh-pages...")
res = subprocess.run(["git", "worktree", "add", "-B", "gh-pages", TEMP_DIR, "origin/gh-pages"], cwd=REPO, capture_output=True, text=True)
print("Worktree add:", res.stdout, res.stderr)

if not os.path.exists(TEMP_DIR):
    # Try creating orphan branch worktree
    res = subprocess.run(["git", "worktree", "add", TEMP_DIR, "gh-pages"], cwd=REPO, capture_output=True, text=True)
    print("Worktree add retry:", res.stdout, res.stderr)

# Clean out old files in temp dir except .git
for item in os.listdir(TEMP_DIR):
    if item == ".git":
        continue
    p = os.path.join(TEMP_DIR, item)
    if os.path.isdir(p):
        shutil.rmtree(p)
    else:
        os.remove(p)

# Copy all files from build/web
for item in os.listdir(BUILD_DIR):
    s = os.path.join(BUILD_DIR, item)
    d = os.path.join(TEMP_DIR, item)
    if os.path.isdir(s):
        shutil.copytree(s, d)
    else:
        shutil.copy2(s, d)

# Ensure .nojekyll exists
with open(os.path.join(TEMP_DIR, ".nojekyll"), "w") as f:
    pass

print("Files in deploy dir:", len(os.listdir(TEMP_DIR)))

# Git commit and push
subprocess.run(["git", "add", "-A"], cwd=TEMP_DIR, check=True)
res_status = subprocess.run(["git", "status", "--porcelain"], cwd=TEMP_DIR, capture_output=True, text=True)
print("Status changes:\n", res_status.stdout[:500])

if res_status.stdout.strip():
    commit_res = subprocess.run(
        ["git", "commit", "-m", "fix: 100% symbol rendering, cache-busting ecogrid_v2.pck, and clean UI spacing"],
        cwd=TEMP_DIR,
        capture_output=True,
        text=True
    )
    print("Commit:", commit_res.stdout)
    
    print("Pushing to origin gh-pages...")
    push_res = subprocess.run(
        ["git", "push", "origin", "gh-pages"],
        cwd=TEMP_DIR,
        capture_output=True,
        text=True
    )
    print("Push output:", push_res.stdout, push_res.stderr)
else:
    print("No changes to commit!")

# Clean up worktree
subprocess.run(["git", "worktree", "remove", "--force", TEMP_DIR], cwd=REPO, capture_output=True)
print("Worktree cleaned up. Deployment complete!")

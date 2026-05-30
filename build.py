import os
import random
import subprocess
import shutil

SRC_DIR = "src"
ROOT_DIR = "."

def obfuscate_lua(src_path, dest_path):
    with open(src_path, 'r', encoding='utf-8') as f:
        code = f.read()
    
    key = random.randint(10, 240)
    encrypted_bytes = [(ord(c) ^ key) for c in code]
    byte_str = ",".join(str(b) for b in encrypted_bytes)
    
    obfuscated_code = f"""-- ============================================================
-- Axiore.wtf | Protected by cook45
-- ============================================================
local K = {key}
local B = {{{byte_str}}}
local S = ""
for i=1, #B do
    S = S .. string.char(bit32.bxor(B[i], K))
end
local F, E = loadstring(S)
if F then F() else warn("Decode error") end
"""

    with open(dest_path, 'w', encoding='utf-8') as f:
        f.write(obfuscated_code)
    print(f"[+] Built & Obfuscated: {dest_path}")

def build():
    print("=== Axiore.wtf Build Pipeline ===\n")
    
    if not os.path.exists(SRC_DIR):
        print("Error: src/ directory not found!")
        return

    # 1. Obfuscate all files from src/ to root
    for filename in os.listdir(SRC_DIR):
        if filename.endswith(".lua") or filename.endswith(".luau"):
            src_file = os.path.join(SRC_DIR, filename)
            # Save as .luau in root
            dest_file = os.path.join(ROOT_DIR, filename.replace(".lua", ".luau"))
            obfuscate_lua(src_file, dest_file)
    
    # Also obfuscate loader if it exists in src/ (Optional, skipping for now as loader is static)

    print("\n=== Git Push ===")
    try:
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(["git", "commit", "-m", "Auto-build: Added Rayfield GUI"], check=True)
        subprocess.run(["git", "push", "origin", "main"], check=True)
        print("[SUCCESS] Files pushed to GitHub!")
    except Exception as e:
        print(f"[ERROR] Git push failed: {e}")

if __name__ == "__main__":
    build()

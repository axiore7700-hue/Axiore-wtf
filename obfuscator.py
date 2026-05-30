import os
import random

def obfuscate_lua(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        code = f.read()
    
    # 1. Aşama: Kodu byte'lara çevir ve rastgele bir key ile XOR'la
    key = random.randint(10, 240)
    encrypted_bytes = [(ord(c) ^ key) for c in code]
    
    # 2. Aşama: Lua unpack ve string.char kullanan bir loader oluştur
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

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(obfuscated_code)
    
    print(f"[+] Obfuscated: {filepath}")

# Tüm .luau dosyalarını bul ve şifrele
directory = r"C:\Users\Axiore\Videos\roblox script"
for filename in os.listdir(directory):
    if filename.endswith(".luau"):
        obfuscate_lua(os.path.join(directory, filename))

print("\nTüm scriptler şifrelendi!")

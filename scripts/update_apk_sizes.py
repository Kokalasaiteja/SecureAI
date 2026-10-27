import os
import re

def get_apk_sizes():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    media_dir = os.path.join(base_dir, 'SecureAI_Web', 'media')
    
    apks = {
        'universal': 'app-release.apk',
        'arm64': 'app-arm64-v8a-release.apk',
        'arm32': 'app-armeabi-v7a-release.apk',
        'x86_64': 'app-x86_64-release.apk'
    }
    
    sizes = {}
    for key, filename in apks.items():
        path = os.path.join(media_dir, filename)
        if os.path.exists(path):
            size_mb = os.path.getsize(path) / 1000000.0  # Decimal MB standard
            sizes[key] = f"{size_mb:.1f} MB"
        else:
            sizes[key] = None
    return sizes

def update_files():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sizes = get_apk_sizes()
    print(f"Calculated APK sizes: {sizes}")
    
    if not sizes['universal']:
        print("APKs not found in media, skipping.")
        return

    # 1. Update root README.md
    readme_path = os.path.join(base_dir, 'README.md')
    if os.path.exists(readme_path):
        with open(readme_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Replace sizes in table and lists
        content = re.sub(r'app-release\.apk`\)\s*\|\s*Local:[^)]+\)\s*\*\([^)]+\*', f"app-release.apk`](https://secureai-7wgj.onrender.com/media/app-release.apk) | Local: [`SecureAI_Web/media/app-release.apk`](./SecureAI_Web/media/app-release.apk) *({sizes['universal']} - All ABIs*", content)
        content = re.sub(r'app-arm64-v8a-release\.apk`\)\s*\|\s*Local:[^)]+\)\s*\*\([^)]+\*', f"app-arm64-v8a-release.apk`](https://secureai-7wgj.onrender.com/media/app-arm64-v8a-release.apk) | Local: [`SecureAI_Web/media/app-arm64-v8a-release.apk`](./SecureAI_Web/media/app-arm64-v8a-release.apk) *({sizes['arm64']} - 64-bit ARM smartphones*", content)
        content = re.sub(r'app-armeabi-v7a-release\.apk`\)\s*\|\s*Local:[^)]+\)\s*\*\([^)]+\*', f"app-armeabi-v7a-release.apk`](https://secureai-7wgj.onrender.com/media/app-armeabi-v7a-release.apk) | Local: [`SecureAI_Web/media/app-armeabi-v7a-release.apk`](./SecureAI_Web/media/app-armeabi-v7a-release.apk) *({sizes['arm32']} - 32-bit ARM smartphones*", content)
        content = re.sub(r'app-x86_64-release\.apk`\)\s*\|\s*Local:[^)]+\)\s*\*\([^)]+\*', f"app-x86_64-release.apk`](https://secureai-7wgj.onrender.com/media/app-x86_64-release.apk) | Local: [`SecureAI_Web/media/app-x86_64-release.apk`](./SecureAI_Web/media/app-x86_64-release.apk) *({sizes['x86_64']} - Android Studio emulators*", content)

        # Table rows
        content = re.sub(r'\|\s*\*\*`app-release\.apk`\*\*\s*\*\(Universal Build\)\*\s*\|\s*\*\*~?[0-9.]+\s*MB\*\*', f"| **`app-release.apk`** *(Universal Build)* | **~{sizes['universal']}**", content)
        content = re.sub(r'\|\s*\*\*`app-arm64-v8a-release\.apk`\*\*\s*\*\(Targeted Build\)\*\s*\|\s*\*\*~?[0-9.]+\s*MB\*\*', f"| **`app-arm64-v8a-release.apk`** *(Targeted Build)* | **~{sizes['arm64']}**", content)
        content = re.sub(r'\|\s*\*\*`app-armeabi-v7a-release\.apk`\*\*\s*\*\(Targeted Build\)\*\s*\|\s*\*\*~?[0-9.]+\s*MB\*\*', f"| **`app-armeabi-v7a-release.apk`** *(Targeted Build)* | **~{sizes['arm32']}**", content)
        content = re.sub(r'\|\s*\*\*`app-x86_64-release\.apk`\*\*\s*\*\(Emulator Build\)\*\s*\|\s*\*\*~?[0-9.]+\s*MB\*\*', f"| **`app-x86_64-release.apk`** *(Emulator Build)* | **~{sizes['x86_64']}**", content)
        
        # Directory tree comments
        content = re.sub(r'app-arm64-v8a-release\.apk\s*#\s*64-bit optimized APK build \([0-9.]+\s*MB\)', f"app-arm64-v8a-release.apk # 64-bit optimized APK build ({sizes['arm64']})", content)
        content = re.sub(r'app-armeabi-v7a-release\.apk\s*#\s*32-bit legacy APK build \([0-9.]+\s*MB\)', f"app-armeabi-v7a-release.apk # 32-bit legacy APK build ({sizes['arm32']})", content)
        content = re.sub(r'app-x86_64-release\.apk\s*#\s*Emulator APK build \([0-9.]+\s*MB\)', f"app-x86_64-release.apk    # Emulator APK build ({sizes['x86_64']})", content)
        content = re.sub(r'app-release\.apk\s*#\s*Universal all-device APK build \([0-9.]+\s*MB\)', f"app-release.apk           # Universal all-device APK build ({sizes['universal']})", content)

        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated root README.md successfully.")

    # 2. Update modal template
    modal_path = os.path.join(base_dir, 'SecureAI_Web', 'templates', 'apk_download_modal.html')
    if os.path.exists(modal_path):
        with open(modal_path, 'r', encoding='utf-8') as f:
            modal_content = f.read()

        # Update size badges
        modal_content = re.sub(r'border-indigo-400/40">[^<]+</span>', f'border-indigo-400/40">{sizes["arm64"]}</span>', modal_content)
        modal_content = re.sub(r'border-teal-500/30">[^<]+</span>', f'border-teal-500/30">{sizes["universal"]}</span>', modal_content)
        modal_content = re.sub(r'border-pink-500/30">[^<]+</span>', f'border-pink-500/30">{sizes["arm32"]}</span>', modal_content)
        modal_content = re.sub(r'border-cyan-500/30">[^<]+</span>', f'border-cyan-500/30">{sizes["x86_64"]}</span>', modal_content)

        with open(modal_path, 'w', encoding='utf-8') as f:
            f.write(modal_content)
        print("Updated apk_download_modal.html successfully.")

if __name__ == '__main__':
    update_files()

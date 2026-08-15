import requests
import os
import py7zr

def fetch_and_extract_mpv():
    project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    lib_dir = os.path.join(project_dir, "lib")
    os.makedirs(lib_dir, exist_ok=True)
    archive_path = os.path.join(lib_dir, "mpv-dev.7z")

    headers = {'User-Agent': 'Mozilla/5.0'}
    print("Querying latest release from shinchiro/mpv-winbuild-cmake...")
    api_url = "https://api.github.com/repos/shinchiro/mpv-winbuild-cmake/releases/latest"
    r = requests.get(api_url, headers=headers)
    data = r.json()

    download_url = None
    for asset in data.get("assets", []):
        name = asset.get("name", "")
        if name.startswith("mpv-dev-x86_64-") and not name.startswith("mpv-dev-x86_64-v3-") and name.endswith(".7z"):
            download_url = asset.get("browser_download_url")
            print(f"Found target asset: {name}")
            break

    if not download_url:
        print("Could not find matching asset url!")
        return

    print(f"Downloading from {download_url}...")
    with requests.get(download_url, headers=headers, stream=True) as resp:
        resp.raise_for_status()
        with open(archive_path, 'wb') as f:
            for chunk in resp.iter_content(chunk_size=8192):
                f.write(chunk)

    print("Download finished. Extracting...")
    with py7zr.SevenZipFile(archive_path, mode='r') as z:
        z.extractall(path=lib_dir)

    print("Extraction complete! Cleaning up archive...")
    if os.path.exists(archive_path):
        os.remove(archive_path)
    print("libmpv is fully ready!")

if __name__ == "__main__":
    fetch_and_extract_mpv()

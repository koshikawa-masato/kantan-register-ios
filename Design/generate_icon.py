"""Install the approved icon master into the app's asset catalogs."""
from pathlib import Path
from shutil import copyfile

root = Path(__file__).resolve().parents[1]
master = root / "Design/AppIcon.png"
assets = root / "KantanRegister/Assets.xcassets"
for folder, name in [
    ("AppIcon.appiconset", "AppIcon.png"),
    ("AppBrand.imageset", "AppBrand.png"),
]:
    copyfile(master, assets / folder / name)

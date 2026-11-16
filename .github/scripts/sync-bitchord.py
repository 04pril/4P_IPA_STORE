#!/usr/bin/env python3
"""Keep 4P IPA Store's BitChord entry aligned with the published IPA release."""

import json
import os
from pathlib import Path
from urllib.request import Request, urlopen


BUNDLE_ID = "com.music.bitchord"
STORE_FILE = Path("source.json")
UPSTREAM_SOURCE = (
    "https://raw.githubusercontent.com/04pril/BitChord-iOS/main/source.json"
)
LATEST_RELEASE = (
    "https://api.github.com/repos/04pril/BitChord-iOS/releases/latest"
)


def fetch_json(url: str) -> dict:
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "4P-IPA-Store"}
    token = os.environ.get("GH_TOKEN")
    if token and url.startswith("https://api.github.com/"):
        headers["Authorization"] = f"Bearer {token}"
        headers["X-GitHub-Api-Version"] = "2022-11-28"
    with urlopen(Request(url, headers=headers), timeout=30) as response:
        return json.load(response)


def find_bitchord(source: dict) -> dict:
    matches = [
        item for item in source.get("apps", [])
        if item.get("bundleIdentifier") == BUNDLE_ID
    ]
    if len(matches) != 1:
        raise ValueError("Expected exactly one BitChord app entry")
    return matches[0]


def main() -> None:
    release = fetch_json(LATEST_RELEASE)
    if release.get("draft") or release.get("prerelease"):
        raise ValueError("Latest release should be a published stable release")

    ipa_assets = [
        asset for asset in release.get("assets", [])
        if asset.get("name", "").startswith("BitChord-")
        and asset.get("name", "").endswith(".ipa")
    ]
    if len(ipa_assets) != 1:
        raise ValueError("Expected exactly one BitChord IPA in latest release")
    asset = ipa_assets[0]

    upstream = find_bitchord(fetch_json(UPSTREAM_SOURCE))
    versions = upstream.get("versions", [])
    if not versions or not upstream.get("version"):
        raise ValueError("Upstream BitChord source is missing version metadata")

    # The app's own source.json can update after the GitHub release is published.
    # Do not publish a stale or missing IPA while those two are out of sync.
    expected_url = asset["browser_download_url"]
    if (
        versions[0].get("downloadURL") != expected_url
        or upstream.get("downloadURL") != expected_url
        or versions[0].get("size") != asset["size"]
    ):
        print("Latest release and upstream source metadata differ; retry next run.")
        return

    current_text = STORE_FILE.read_text(encoding="utf-8")
    store = json.loads(current_text)
    target = find_bitchord(store)
    for key in ("versions", "version", "versionDate", "size", "downloadURL"):
        if key not in upstream:
            raise ValueError(f"Upstream source is missing {key}")
        target[key] = upstream[key]

    target["localizedDescription"] = (
        "04pril/BitChord-iOS 최신 릴리스입니다. "
        + versions[0].get("localizedDescription", "")
    )
    updated = json.dumps(store, ensure_ascii=False, indent=2) + "\n"
    if updated == current_text:
        print(f"Already current: {release['tag_name']}")
        return

    STORE_FILE.write_text(updated, encoding="utf-8")
    print(f"Updated BitChord to {release['tag_name']}")


if __name__ == "__main__":
    main()

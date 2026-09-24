#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: render-print-assets.sh URL ASSET_NAME PREVIEW_PORT SITE_DIR" >&2
  exit 2
fi

url="$1"
asset_name="$2"
preview_port="$3"
site_dir="$4"
public_dir="$site_dir/public"
dist_dir="$site_dir/dist"
pdf_file="$public_dir/$asset_name.pdf"
png_prefix="$public_dir/$asset_name"

browser="${BROWSER_BIN:-}"
if [[ -z "$browser" ]]; then
  browser="$(command -v chromium-browser || command -v chromium || command -v google-chrome || true)"
fi
if [[ -z "$browser" || ! -x "$browser" ]]; then
  if [[ -f "$pdf_file" && -f "$png_prefix.png" ]]; then
    cp "$pdf_file" "$dist_dir/$asset_name.pdf"
    cp "$png_prefix.png" "$dist_dir/$asset_name.png"
    echo "Chromium unavailable; reused committed print assets"
    exit 0
  fi
  echo "A Chromium-based browser is required to generate print assets." >&2
  exit 1
fi

npx astro preview stop >/dev/null 2>&1 || true
npm run preview -- --host 127.0.0.1 --port "$preview_port" >/dev/null 2>&1 &
preview_pid=$!
trap 'kill "$preview_pid" 2>/dev/null || true' EXIT

for attempt in {1..30}; do
  if curl --fail --silent "http://127.0.0.1:$preview_port/" >/dev/null; then
    break
  fi
  sleep 1
done

if ! curl --fail --silent "http://127.0.0.1:$preview_port/" >/dev/null; then
  echo "Astro preview did not start." >&2
  exit 1
fi

echo "Rendering PDF with $browser"
"$browser" --headless --no-sandbox --disable-gpu \
  --print-to-pdf="$pdf_file" "$url"

command -v pdftoppm >/dev/null || {
  echo "pdftoppm is required to generate PNG output from the PDF." >&2
  exit 1
}
echo "Rasterizing PNG from the PDF with pdftoppm"
pdftoppm -singlefile -png -r 150 "$pdf_file" "$png_prefix"

cp "$pdf_file" "$dist_dir/$asset_name.pdf"
cp "$png_prefix.png" "$dist_dir/$asset_name.png"

echo "Generated $public_dir/$asset_name.pdf and $public_dir/$asset_name.png"

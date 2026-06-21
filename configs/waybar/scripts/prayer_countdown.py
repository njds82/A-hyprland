#!/usr/bin/env python3
import os
import sys
import json
import urllib.request
from datetime import datetime, timedelta

# Default coordinates (Amman)
DEFAULT_LAT = "31.9552"
DEFAULT_LON = "35.9450"

CACHE_DIR = os.path.expanduser("~/.cache")
CACHE_FILE = os.path.join(CACHE_DIR, "waybar_prayer.json")

PRAYER_NAMES_AR = {
    "Fajr": "الفجر",
    "Sunrise": "الشروق",
    "Dhuhr": "الظهر",
    "Asr": "العصر",
    "Maghrib": "المغرب",
    "Isha": "العشاء"
}

def get_prayer_times():
    today_str = datetime.now().strftime("%Y-%m-%d")
    
    # Check if cache is valid
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                cache = json.load(f)
            if cache.get("date") == today_str:
                return cache.get("timings")
        except Exception:
            pass

    # Cache is invalid or missing, fetch new data
    os.makedirs(CACHE_DIR, exist_ok=True)
    lat, lon = DEFAULT_LAT, DEFAULT_LON
    
    # 1. Try to get location
    try:
        req = urllib.request.Request("https://ipinfo.io/json", headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=3) as response:
            data = json.loads(response.read().decode())
            loc = data.get("loc", "").split(",")
            if len(loc) == 2:
                lat, lon = loc[0], loc[1]
    except Exception:
        pass

    # 2. Fetch prayer times
    try:
        url = f"https://api.aladhan.com/v1/timings?latitude={lat}&longitude={lon}&method=4"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            res = json.loads(response.read().decode())
            if res.get("code") == 200:
                timings = res["data"]["timings"]
                # Save to cache
                with open(CACHE_FILE, "w") as f:
                    json.dump({"date": today_str, "timings": timings}, f)
                return timings
    except Exception:
        # If fetch fails, try to return cached data anyway even if it's old
        if os.path.exists(CACHE_FILE):
            try:
                with open(CACHE_FILE, "r") as f:
                    cache = json.load(f)
                return cache.get("timings")
            except Exception:
                pass
        return None

def main():
    timings = get_prayer_times()
    if not timings:
        print(json.dumps({"text": "🕌 صلاة --:--", "tooltip": "تعذر الاتصال بالشبكة لجلب أوقات الصلاة"}))
        return

    now = datetime.now()
    today_str = now.strftime("%Y-%m-%d")

    # Parse prayer times
    prayer_list = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
    parsed_prayers = []

    for name in prayer_list:
        time_str = timings.get(name)
        if time_str:
            # format is HH:MM
            p_time = datetime.strptime(f"{today_str} {time_str}", "%Y-%m-%d %H:%M")
            parsed_prayers.append((name, p_time))

    # Find the next prayer
    next_name = None
    next_time = None
    
    for name, p_time in parsed_prayers:
        if p_time > now:
            next_name = name
            next_time = p_time
            break

    # If all prayers of today have passed, the next is Fajr of tomorrow
    if not next_name:
        next_name = "Fajr"
        fajr_today_str = timings.get("Fajr")
        fajr_today = datetime.strptime(f"{today_str} {fajr_today_str}", "%Y-%m-%d %H:%M")
        next_time = fajr_today + timedelta(days=1)

    # Calculate countdown
    diff = next_time - now
    diff_seconds = diff.total_seconds()
    hours = int(diff_seconds // 3600)
    minutes = int((diff_seconds % 3600) // 60)

    # Format output
    name_ar = PRAYER_NAMES_AR.get(next_name, next_name)
    countdown_str = f"{hours:02d}:{minutes:02d}"
    display_text = f"🕌 {name_ar} {countdown_str}"

    # Build tooltip
    tooltip_lines = [
        "🕋 أوقات الصلاة اليوم:",
        f"• الفجر:   {timings.get('Fajr')}",
        f"• الشروق:  {timings.get('Sunrise')}",
        f"• الظهر:   {timings.get('Dhuhr')}",
        f"• العصر:   {timings.get('Asr')}",
        f"• المغرب:  {timings.get('Maghrib')}",
        f"• العشاء:  {timings.get('Isha')}",
        "",
        f"الصلاة القادمة: {name_ar} عند {next_time.strftime('%I:%M %p')}",
        f"الوقت المتبقي: {hours} ساعة و {minutes} دقيقة"
    ]
    tooltip_text = "\n".join(tooltip_lines)

    # Output JSON for waybar
    out = {
        "text": display_text,
        "tooltip": tooltip_text,
        "class": next_name.lower(),
        "alt": next_name
    }
    print(json.dumps(out, ensure_ascii=False))

if __name__ == "__main__":
    main()

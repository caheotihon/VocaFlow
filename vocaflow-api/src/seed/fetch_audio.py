import json
import requests
import time
import re
import ast

# ==================================================
# CONFIG
# ==================================================
INPUT_FILE = "words.seed.js"
OUTPUT_FILE = "words_final.json"
DELAY_SECONDS = 0.3

def parse_js_array(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # 1. Tìm mảng bắt đầu từ [ và kết thúc tại ] trước module.exports
    match = re.search(r'\[[\s\S]*?\](?=\s*;?\s*module\.exports)', content)
    if not match:
        raise ValueError("Không tìm thấy mảng dữ liệu trong file JS.")
    
    array_str = match.group(0)
    
    # 2. Loại bỏ các dòng comment //
    array_str = re.sub(r'//.*', '', array_str)
    
    # 3. Thêm ngoặc kép cho các key (ví dụ word: -> "word":)
    # Tìm các từ đứng trước dấu hai chấm mà chưa có ngoặc
    array_str = re.sub(r'(\s)(\w+):', r'\1"\2":', array_str)
    
    # 4. Xử lý dấu phẩy cuối cùng (trailing commas) nếu có
    array_str = re.sub(r',(\s*[\]}])', r'\1', array_str)

    # Chuyển đổi chuỗi thành list trong Python
    # Sử dụng json.loads vì giờ nó đã là định dạng JSON chuẩn
    return json.loads(array_str)

# ==================================================
# MAIN PROCESS
# ==================================================
print(f"--- Bắt đầu xử lý file {INPUT_FILE} ---")
try:
    words_data = parse_js_array(INPUT_FILE)
except Exception as e:
    print(f"❌ Lỗi xử lý file JS: {e}")
    exit()

final_results = []
total = len(words_data)

for i, item in enumerate(words_data, start=1):
    word_text = item.get("word", "").strip()
    print(f"[{i}/{total}] Đang lấy audio: {word_text}")

    # Gọi API để lấy audio và phonetic
    url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{word_text}"
    try:
        res = requests.get(url, timeout=10)
        if res.status_code == 200:
            api_data = res.json()[0]
            
            # Cập nhật phonetic nếu seed cũ chưa có
            if not item.get("phonetic"):
                item["phonetic"] = api_data.get("phonetic", "")

            # Cập nhật audio_url
            for p in api_data.get("phonetics", []):
                if p.get("audio"):
                    item["audio_url"] = p["audio"]
                    break
        else:
            item["audio_url"] = ""
    except Exception:
        item["audio_url"] = ""

    final_results.append(item)
    time.sleep(DELAY_SECONDS)

# Lưu kết quả ra file JSON
with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    json.dump(final_results, f, ensure_ascii=False, indent=2)

print(f"\n✅ Hoàn tất! Đã tạo file: {OUTPUT_FILE}")
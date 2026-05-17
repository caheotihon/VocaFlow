# Hướng dẫn chạy Seed dữ liệu từ vựng cho VocaFlow (LingoPro)

Tài liệu này hướng dẫn chi tiết cách chuẩn bị dữ liệu, cào phát âm (Audio) và nạp (Seed) hàng trăm từ vựng chất lượng cao vào cơ sở dữ liệu MongoDB của dự án.

---

## 📁 Cấu trúc thư mục Seed
```tree
vocaflow-api/src/seed/
├── words.seed.js      # Danh sách từ vựng gốc (336 từ chuẩn Oxford/IELTS/TOEIC)
├── fetch_audio.py     # Script Python để lấy phiên âm & link phát âm từ Dictionary API
├── words_final.json   # File kết quả chứa đầy đủ nghĩa, ví dụ, phiên âm và âm thanh
└── seedData.js        # Script NodeJS nạp dữ liệu vào MongoDB
```

---

## ⚡ Các bước thực hiện nhanh (Quick Start)

Nếu bạn muốn nạp dữ liệu ngay lập tức bằng file dữ liệu đã có sẵn (`words_final.json`), hãy thực hiện các bước sau:

1. Mở Terminal tại thư mục `vocaflow-api`:
   ```bash
   cd vocaflow-api
   ```
2. Chạy lệnh nạp dữ liệu:
   ```bash
   npm run seed
   ```
   *Hoặc chạy trực tiếp:*
   ```bash
   node src/seed/seedData.js
   ```

Hệ thống sẽ kết nối tới MongoDB của bạn và nạp/cập nhật toàn bộ **336 từ vựng** kèm theo đầy đủ thông tin!

---

## 🔍 Hướng dẫn chi tiết từng phần

### 1. Script Cào Phát Âm (`fetch_audio.py`)

Nếu bạn muốn thay đổi danh sách từ vựng trong file `words.seed.js` và muốn cập nhật lại toàn bộ phát âm cũng như phiên âm quốc tế, hãy làm theo các bước:

#### Yêu cầu hệ thống:
* Đã cài đặt **Python 3**.
* Cài đặt thư viện `requests` bằng cách mở terminal và chạy:
  ```bash
  pip install requests
  ```

#### Cách chạy:
1. Di chuyển vào thư mục chứa file python:
   ```bash
   cd vocaflow-api/src/seed
   ```
2. Chạy script:
   ```bash
   python fetch_audio.py
   ```
   * Script sẽ tự động đọc danh sách từ `words.seed.js`.
   * Gửi yêu cầu đến **Free Dictionary API** để tải về liên kết âm thanh và phiên âm quốc tế.
   * Tự động xuất ra file kết quả sạch sẽ mang tên `words_final.json`.

---

### 2. Script Nạp Dữ Liệu MongoDB (`seedData.js`)

Script này có nhiệm vụ đọc file `words_final.json` và đưa dữ liệu vào MongoDB một cách an toàn (Sử dụng cơ chế `upsert: true` tránh trùng lặp từ vựng cũ).

#### Cách chạy:
1. Mở Terminal tại thư mục `vocaflow-api`:
   ```bash
   cd vocaflow-api
   ```
2. Chạy lệnh:
   ```bash
   npm run seed
   ```
3. Kết quả mong đợi trên màn hình:
   ```text
   ✅ Connected to MongoDB
   🌱 Done! Processed 336 words.
   ```

---

> [!TIP]
> **Mẹo phát triển:**
> * Bạn có thể tự do chỉnh sửa, thêm bớt từ vựng mới vào `words.seed.js` theo cấu trúc sẵn có.
> * Cơ chế `updateOne` với `{ upsert: true }` trong `seedData.js` đảm bảo rằng nếu bạn chạy lại nhiều lần, nó sẽ chỉ cập nhật những thay đổi mới chứ không bao giờ tạo trùng lặp hoặc làm hỏng dữ liệu cũ của bạn!

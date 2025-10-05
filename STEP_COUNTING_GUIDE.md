# Hướng dẫn đếm bước chân

## 🔍 **Cách thức hoạt động của cảm biến bước chân**

### 1. **Cảm biến được sử dụng:**

- **Gia tốc kế (Accelerometer)**: Phát hiện chuyển động lên xuống
- **Con quay hồi chuyển (Gyroscope)**: Phát hiện hướng chuyển động
- **Cảm biến bước chân (Step Counter)**: Cảm biến chuyên dụng

### 2. **Thuật toán phát hiện:**

- Phân tích mẫu chuyển động đặc trưng của việc đi bộ
- Loại bỏ các chuyển động không phải đi bộ
- Cần chuỗi chuyển động liên tục để xác nhận

## 🚨 **Tại sao bước chân không tăng?**

### **Nguyên nhân chính:**

1. **Cảm biến cần thời gian "học":**

   - Cần 10-20 bước liên tục để kích hoạt
   - Một số thiết bị có cảm biến kém nhạy
   - Cần chuyển động đủ mạnh và đều đặn

2. **Vấn đề với thuật toán:**

   - Ứng dụng có thể quá nghiêm ngặt
   - Cần một số bước liên tục để kích hoạt đếm
   - Lắc điện thoại không được tính là bước chân

3. **Vấn đề với thiết bị:**
   - Cảm biến bị lỗi hoặc kém nhạy
   - Thiết bị cũ có cảm biến kém chất lượng
   - Cần cấp quyền Activity Recognition

## 🛠️ **Cách khắc phục**

### **1. Test cảm biến:**

- Mở Settings → "Test cảm biến bước chân"
- Kiểm tra xem cảm biến có hoạt động không

### **2. Cách đi bộ để đếm được:**

- **Đi bộ liên tục ít nhất 10-20 bước**
- **Giữ điện thoại trong túi quần hoặc tay**
- **Đi với tốc độ bình thường (không quá chậm)**
- **Tránh chạy xe, đi thang máy**

### **3. Kiểm tra quyền:**

- Đảm bảo đã cấp quyền "Activity Recognition"
- Kiểm tra trong Settings → Apps → Permissions

### **4. Reset dữ liệu:**

- Settings → "Reset bước chân hôm nay"
- Hoặc "Xóa tất cả dữ liệu" để reset hoàn toàn

## 📱 **Cách test hiệu quả**

### **Trên máy ảo:**

- Dữ liệu được mô phỏng (không thật)
- Chỉ để test giao diện

### **Trên thiết bị thật:**

1. **Test cơ bản:**

   - Đi bộ 20-30 bước liên tục
   - Chờ 5-10 giây để cảm biến cập nhật
   - Kiểm tra số bước chân

2. **Test nâng cao:**
   - Đi bộ 100 bước
   - Dừng lại 30 giây
   - Tiếp tục đi bộ 50 bước nữa
   - Kiểm tra tổng số bước

## 🔧 **Troubleshooting**

### **Nếu bước chân không tăng:**

1. **Kiểm tra cảm biến:**

   - Settings → "Test cảm biến bước chân"
   - Nếu lỗi → sử dụng chế độ mô phỏng

2. **Kiểm tra quyền:**

   - Settings → Apps → Permissions
   - Bật "Activity Recognition"

3. **Reset dữ liệu:**

   - Settings → "Reset bước chân hôm nay"
   - Restart ứng dụng

4. **Kiểm tra thiết bị:**
   - Thử ứng dụng khác đếm bước chân
   - Kiểm tra xem thiết bị có cảm biến không

### **Nếu bước chân tăng không chính xác:**

- Đây là bình thường với cảm biến
- Sai số ±5-10% là chấp nhận được
- Quan trọng là xu hướng tăng/giảm

## 💡 **Mẹo sử dụng**

1. **Giữ điện thoại ổn định:**

   - Trong túi quần (không quá chặt)
   - Hoặc cầm trong tay khi đi bộ

2. **Đi bộ đều đặn:**

   - Tốc độ bình thường
   - Không quá chậm hoặc quá nhanh

3. **Kiên nhẫn:**

   - Cảm biến cần thời gian để "học"
   - Đi ít nhất 20-30 bước liên tục

4. **Kiểm tra định kỳ:**
   - Test cảm biến mỗi tuần
   - Reset dữ liệu nếu cần

## 📊 **Hiểu về dữ liệu**

- **Bước chân**: Số bước thực tế đã đi
- **Quãng đường**: Tính từ số bước × chiều dài bước
- **Calo**: Ước tính dựa trên số bước và cân nặng
- **Thời gian hoạt động**: Ước tính dựa trên số bước

## ⚠️ **Lưu ý quan trọng**

- **Lắc điện thoại KHÔNG được tính là bước chân**
- **Chạy xe, đi thang máy KHÔNG được tính**
- **Cần đi bộ thật sự để đếm được**
- **Cảm biến cần thời gian để kích hoạt**

# Ứng dụng đếm bước chân (Step Counter App)

Ứng dụng Flutter đếm bước chân với giao diện đẹp và tính năng đầy đủ.

## Tính năng chính

### Màn hình chính (Home Screen)

- **Số bước chân hiện tại**: Hiển thị số bước real-time với font chữ lớn
- **Mục tiêu số bước**: Vòng tròn tiến độ hiển thị % hoàn thành mục tiêu
- **Quãng đường đã đi**: Tính từ số bước × chiều dài bước trung bình
- **Lượng calo tiêu hao**: Ước tính dựa trên số bước và cân nặng
- **Thời gian vận động**: Tổng thời gian đi bộ/chạy trong ngày
- **Biểu đồ thống kê**: Biểu đồ 7 ngày qua với fl_chart
- **Lịch sử**: Xem dữ liệu các ngày trước
- **Thông báo động viên**: Lời nhắc nhở khi chưa đạt mục tiêu

### Màn hình cài đặt (Settings)

- **Thông tin cá nhân**: Chiều cao, cân nặng
- **Mục tiêu**: Đặt mục tiêu bước chân hàng ngày
- **Chiều dài bước chân**: Tự động tính hoặc nhập thủ công
- **Tính năng nhanh**: Đặt mục tiêu mặc định, tính chiều dài bước tự động

### Màn hình lịch sử (History)

- **Xem dữ liệu**: 7 ngày, 30 ngày, 1 năm qua
- **Thống kê tổng**: Tổng bước, quãng đường, calo
- **Trung bình**: Số bước trung bình/ngày
- **Chi tiết từng ngày**: Bước, quãng đường, calo, thời gian

## Công nghệ sử dụng

- **Flutter**: Framework chính
- **Pedometer**: Đếm bước chân từ cảm biến
- **Shared Preferences**: Lưu trữ dữ liệu local
- **FL Chart**: Vẽ biểu đồ đẹp
- **Permission Handler**: Quản lý quyền truy cập
- **Intl**: Định dạng ngày tháng

## Cài đặt và chạy

### Yêu cầu

- Flutter SDK 3.9.2+
- Android Studio / VS Code
- Android device hoặc emulator

### Các bước cài đặt

1. **Clone repository**

```bash
git clone <repository-url>
cd app_cam_bien
```

2. **Cài đặt dependencies**

```bash
flutter pub get
```

3. **Chạy ứng dụng**

```bash
flutter run
```

4. **Build APK**

```bash
flutter build apk --release
```

## Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── step_data.dart       # Model dữ liệu bước chân
│   └── user_settings.dart   # Model cài đặt người dùng
├── screens/                  # Màn hình
│   ├── home_screen.dart     # Màn hình chính
│   ├── settings_screen.dart # Màn hình cài đặt
│   └── history_screen.dart  # Màn hình lịch sử
├── services/                 # Services
│   └── step_service.dart    # Service đếm bước chân
├── widgets/                  # Widget tùy chỉnh
│   ├── progress_ring_widget.dart    # Vòng tròn tiến độ
│   ├── stats_card_widget.dart       # Card thống kê
│   ├── step_chart_widget.dart       # Biểu đồ bước chân
│   └── step_counter_widget.dart     # Widget đếm bước
└── utils/                    # Utilities (nếu cần)
```

## Quyền cần thiết

Ứng dụng cần các quyền sau để hoạt động:

- `ACTIVITY_RECOGNITION`: Để đếm bước chân
- `WAKE_LOCK`: Để hoạt động khi màn hình tắt

## Tính năng nổi bật

### 🎯 Mục tiêu thông minh

- Đặt mục tiêu bước chân hàng ngày
- Vòng tròn tiến độ trực quan
- Thông báo động viên khi đạt mục tiêu

### 📊 Thống kê chi tiết

- Biểu đồ 7 ngày qua
- Lịch sử đầy đủ với bộ lọc
- Tính toán calo và quãng đường chính xác

### ⚙️ Cài đặt linh hoạt

- Tự động tính chiều dài bước chân
- Cài đặt mục tiêu tùy chỉnh
- Lưu trữ dữ liệu local

### 🎨 Giao diện đẹp

- Material Design 3
- Màu sắc hài hòa
- Responsive design
- Animation mượt mà

## Lưu ý

- Ứng dụng cần thiết bị có cảm biến đếm bước chân
- Dữ liệu được lưu trữ local trên thiết bị
- Cần cấp quyền truy cập cảm biến khi lần đầu chạy

## Phát triển thêm

Để phát triển thêm tính năng:

1. **Thêm màn hình mới**: Tạo file trong `lib/screens/`
2. **Thêm widget**: Tạo file trong `lib/widgets/`
3. **Thêm model**: Tạo file trong `lib/models/`
4. **Thêm service**: Tạo file trong `lib/services/`

## License

MIT License - Xem file LICENSE để biết thêm chi tiết.

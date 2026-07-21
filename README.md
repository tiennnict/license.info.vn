# license.info.vn — Công cụ rà quét & khôi phục bản quyền Windows / Office

Công cụ rà quét, phát hiện và khôi phục các trường hợp Windows hoặc Microsoft Office bị can thiệp kích hoạt trái phép (KMSpico, KMSAuto, TSforge/KMS4k, KMS38, HWID giả, Ohook...), sau đó hỗ trợ gỡ bỏ dấu vết và kích hoạt lại bằng phương thức hợp lệ.

## Cách sử dụng

Mở PowerShell với quyền **Administrator**, sau đó chạy:

```powershell
irm https://license.info.vn | iex
```

Hoặc tải về và chạy trực tiếp:

```powershell
irm https://license.info.vn -OutFile WinLicCheck.ps1
.\WinLicCheck.ps1
```

Lưu ý: cần ghi rõ tiền tố `https://`. PowerShell yêu cầu URI đầy đủ có scheme (http/https) khi gọi `Invoke-RestMethod`; nếu bỏ tiền tố, lệnh sẽ báo lỗi định dạng URI không hợp lệ.

## Tính năng chính

- Rà quét registry, WMI (SoftwareLicensingProduct/Service), tiến trình, dịch vụ, tác vụ định kỳ, tệp hosts, lịch sử PowerShell và log Microsoft Defender để tìm dấu hiệu can thiệp kích hoạt.
- Phân loại từng phát hiện theo mức độ tin cậy (D1–D4) và theo phương thức cụ thể (KMS cục bộ, KMS công cộng, TSforge, KMS38, vá nhị phân, Ohook...) thay vì kết luận chung chung.
- Phân biệt cấu hình KMS doanh nghiệp hợp lệ với KMS lậu để tránh dương tính giả trên máy đã dùng KMS host nội bộ.
- Sao lưu trạng thái cấp phép và yêu cầu xác nhận rõ ràng trước khi thực hiện bất kỳ thao tác ghi/xóa nào.
- Hỗ trợ gỡ bỏ dấu vết công cụ crack và kích hoạt lại bằng key OEM (BIOS/MSDM), key retail, hoặc để trống chờ nhập thủ công.

## Yêu cầu hệ thống

- Windows 10/11 (rà quét Windows) hoặc máy có cài Microsoft Office 2010–2021/365.
- PowerShell chạy với quyền Administrator (script tự yêu cầu nâng quyền khi chạy từ tệp `.ps1`; khi chạy qua `irm | iex` cần tự mở PowerShell dưới quyền Administrator trước).
- Kết nối mạng để phân giải một số tên miền KMS khi phân loại máy chủ kích hoạt (không bắt buộc để rà quét cơ bản).

## Nguyên tắc hoạt động

1. Công cụ chỉ xác định **CÓ hay KHÔNG có can thiệp kỹ thuật** vào cơ chế cấp phép. Nó **không tự khẳng định** một bản quyền là hợp pháp hay bất hợp pháp — kết luận đó cần đối chiếu với hợp đồng/hóa đơn mua sắm thực tế.
2. Mỗi phương thức phát hiện được đánh giá độc lập, không dùng một công thức chung cho mọi trường hợp, nhằm giảm rủi ro kết luận sai trên các cấu hình doanh nghiệp hợp lệ (ví dụ KMS host nội bộ, Azure KMS).
3. Trước mọi thao tác ghi hoặc xóa, công cụ sao lưu trạng thái hiện tại và yêu cầu người dùng xác nhận rõ ràng (gõ đúng từ khóa xác nhận).

## Cảnh báo và giới hạn trách nhiệm

Công cụ thao tác trực tiếp trên registry, dịch vụ hệ thống, tác vụ định kỳ và trạng thái cấp phép Windows/Office. Hãy sao lưu dữ liệu quan trọng và cân nhắc kỹ trước khi thực hiện các thao tác gỡ bỏ/kích hoạt lại trên máy đang vận hành sản xuất. Tác giả không chịu trách nhiệm với bất kỳ thiệt hại nào phát sinh từ việc sử dụng công cụ này; xem chi tiết điều khoản miễn trừ trong file [LICENSE](./LICENSE).

Công cụ được xây dựng cho mục đích **kiểm tra và khôi phục tuân thủ bản quyền**, không nhằm hỗ trợ hay hướng dẫn thực hiện các phương thức kích hoạt trái phép.

## Giấy phép

Phát hành theo giấy phép [Apache License 2.0](./LICENSE).

## Tác giả

tiennn.ict — [github.com/tiennnict](https://github.com/tiennnict)

Góp ý, báo lỗi: [github.com/tiennnict/license.info.vn/issues](https://github.com/tiennnict/license.info.vn/issues)

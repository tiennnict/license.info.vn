# =============================================================================
#  WinLicCheck.ps1  --  Cong cu Ra quet & Khoi phuc Ban quyen Windows / Office
# =============================================================================
#  Tac gia   : tiennn.ict
#  GitHub    : https://github.com/tiennnict/license.info.vn
#
#  Muc dich:
#    (1) Ra quet, phat hien can thiep kich hoat trai phep (Windows 10/11, Office 14-16)
#    (2) Go bo va xoa dau vet crack (co sao luu + xac nhan)
#    (3) Kich hoat lai bang key OEM (BIOS/MSDM), key retail, hoac de trong
#
#  Nguyen tac:
#    - "Xac dinh CO can thiep ky thuat" chu KHONG khang dinh "ban quyen hop phap".
#    - Ket luan theo TUNG phuong thuc, khong dung mot cong thuc chung.
#    - Sao luu + xac nhan truoc moi thao tac ghi. Khong pha huy chung cu.
#
#  Chay (khuyen nghi - PowerShell voi quyen Administrator):
#           irm https://license.info.vn | iex
#         hoac tai ve va chay truc tiep:
#           .\WinLicCheck.ps1
#
#  Xem them: https://github.com/tiennnict/license.info.vn
# =============================================================================

# --- Thiet lap moi truong -----------------------------------------------------
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { $OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { chcp 65001 > $null } catch {}

$Script:VERSION   = '1.1.0'
$Script:BUILDDATE = '21/07/2026'

# --- Kiem tra quyen Administrator & tu nang quyen -----------------------------
function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        return ([Security.Principal.WindowsPrincipal]$id).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

# Nhan dang chinh cong cu nay. Dung cho 2 muc dich:
#  (a) Tu nang quyen an toan khi chay qua "irm <link> | iex" - KHONG danh may/luu lai
#      chuoi "irm ... | iex" trong bat ky lich su nao (xem nhanh Invoke-RestMethod
#      ben duoi: goi noi bo trong script, khong di qua PSReadLine nen khong ghi vao
#      ConsoleHost_history.txt).
#  (b) Loai tru dong lenh NGUOI DUNG DA GO de KHOI CHAY chinh cong cu nay (vd:
#      "irm https://license.info.vn | iex") ra khoi ket qua "phat hien lich su lenh
#      crack" o Get-CrackHistoryHits phia duoi - tranh tu bao dong gia voi chinh minh.
$Script:SELF_URL   = 'https://license.info.vn'
$Script:SELF_NAMES = @('license.info.vn','WinLicCheck','tiennnict/license.info.vn','tiennnict.github.io')

$Script:IsAdmin = Test-IsAdmin
if (-not $Script:IsAdmin) {
    Write-Host ''
    Write-Host '==================================================================' -ForegroundColor Red
    Write-Host '  THIẾU QUYỀN QUẢN TRỊ VIÊN (Administrator) - ĐANG TỰ NÂNG QUYỀN' -ForegroundColor Red
    Write-Host '==================================================================' -ForegroundColor Red
    Write-Host ''
    Write-Host ' Công cụ cần quyền Administrator để:' -ForegroundColor Yellow
    Write-Host '   - Đọc registry SPP, chữ ký số tệp hệ thống, ngày sửa tệp ẩn/hệ thống'
    Write-Host '   - Gỡ bỏ dấu vết và kích hoạt lại bản quyền'
    Write-Host ''

    $elevated = $false
    if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
        # Chay tu tep .ps1 co san tren dia -> nang quyen truc tiep bang -File.
        Write-Host ' Đang tự khởi chạy lại với quyền Administrator (từ tệp)...' -ForegroundColor Cyan
        try {
            Start-Process -FilePath 'powershell.exe' -Verb RunAs `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            $elevated = $true
        } catch { Write-Host " Không thể tự nâng quyền: $_" -ForegroundColor Red }
    } else {
        # Chay qua "irm <link> | iex": khong co tep goc tren dia. De tranh tao ra bat ky
        # dong lenh dang "irm ... | iex" nao (nguy co tu bi ghi vao lich su PowerShell),
        # ta TU TAI NOI DUNG script (goi Invoke-RestMethod noi bo, khong ghep pipe-to-iex,
        # khong go tai dau nhac tuong tac -> KHONG di qua PSReadLine -> khong luu lich su),
        # roi truyen thang noi dung do cho tien trinh nang quyen qua -EncodedCommand.
        Write-Host ' Đang tự khởi chạy lại với quyền Administrator (tải lại nội bộ, không ghi lịch sử)...' -ForegroundColor Cyan
        $selfSource = $null
        try { $selfSource = Invoke-RestMethod -Uri $Script:SELF_URL -UseBasicParsing -ErrorAction Stop } catch {}
        if (-not $selfSource) { try { $selfSource = $MyInvocation.MyCommand.Definition } catch {} }

        if ($selfSource) {
            try {
                $bytes   = [Text.Encoding]::Unicode.GetBytes([string]$selfSource)
                $encoded = [Convert]::ToBase64String($bytes)
                Start-Process -FilePath 'powershell.exe' -Verb RunAs `
                    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
                $elevated = $true
            } catch { Write-Host " Không thể tự nâng quyền: $_" -ForegroundColor Red }
        } else {
            Write-Host ' Không tải lại được nội dung script để tự nâng quyền.' -ForegroundColor Red
        }
    }

    if ($elevated) {
        Write-Host ' Đã mở cửa sổ Administrator mới để tiếp tục. Cửa sổ này có thể đóng.' -ForegroundColor Green
        Read-Host ' Nhấn Enter để đóng cửa sổ này'
        return
    }
    Write-Host ''
    Write-Host ' Tự nâng quyền thất bại. Vui lòng làm thủ công:' -ForegroundColor Yellow
    Write-Host '   1. Bấm nút Start, gõ: powershell' -ForegroundColor White
    Write-Host '   2. Chuột phải vào "Windows PowerShell" -> Run as administrator' -ForegroundColor White
    Write-Host '   3. Chạy lại lệnh trước đó' -ForegroundColor White
    Write-Host ''
    Read-Host ' Nhấn Enter để thoát'
    return
}

# =============================================================================
#  BANG MAU & HAM XUAT GIAO DIEN
# =============================================================================
# Quy uoc mau:
#   Do (Red)      = VI PHAM / dau hieu D1 / canh bao nguy hiem
#   Vang (Yellow) = NGHI VAN / dau hieu D2-D3 / luu y
#   Xanh la(Green)= Sach / hop le / thanh cong
#   Lo (Cyan)     = Tieu de / thong tin
#   Xam (Gray)    = Chi tiet phu
#   Tim (Magenta) = Key / gia tri nhay cam

function Write-Title {
    param([string]$Text)
    Write-Host ''
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host ("  $Text") -ForegroundColor Cyan
    Write-Host ('=' * 70) -ForegroundColor Cyan
}
function Write-Sub    { param([string]$t) Write-Host ''; Write-Host "  $t" -ForegroundColor White; Write-Host ('  ' + ('-' * 66)) -ForegroundColor DarkGray }
function Write-Bad    { param([string]$t) Write-Host "  [X] $t" -ForegroundColor Red }
function Write-Warn   { param([string]$t) Write-Host "  [!] $t" -ForegroundColor Yellow }
function Write-Good   { param([string]$t) Write-Host "  [+] $t" -ForegroundColor Green }
function Write-Info   { param([string]$t) Write-Host "  [i] $t" -ForegroundColor Cyan }
function Write-Dim    { param([string]$t) Write-Host "      $t" -ForegroundColor DarkGray }
function Write-Plain  { param([string]$t) Write-Host "  $t" -ForegroundColor Gray }
function Write-KeyVal {
    param([string]$Label,[string]$Value,[string]$Color = 'White')
    Write-Host ("  {0,-26}" -f $Label) -ForegroundColor DarkGray -NoNewline
    Write-Host " $Value" -ForegroundColor $Color
}
function Pause-Return {
    # Sau khi nguoi dung Nhan Enter, xoa man hinh de mo TRANG MOI cho noi dung tiep theo -
    # ap dung dong nhat quy tac "sau moi lua chon deu mo trang moi" cho moi diem dung Enter.
    param([string]$Msg = 'Nhấn Enter để tiếp tục...')
    Write-Host ''
    [void](Read-Host "  $Msg")
    Clear-Host
}

function Ask-YesNo {
    # Dung (Y)es/(N)o thay vi co/khong - tranh truong hop nguoi dung khong go duoc tieng Viet
    # co dau. Chap nhan Y hoac Yes (khong phan biet hoa/thuong) la CO, N hoac No la KHONG,
    # bat ky gia tri nao khac deu coi la KHONG (ngoai truong hop bo trong -> dung mac dinh).
    param([string]$Prompt,[switch]$DefaultNo)
    $suffix = if ($DefaultNo) { '(Y)es/(N)o [mặc định N]' } else { '(Y)es/(N)o [mặc định Y]' }
    $ans = Read-Host "  $Prompt $suffix"
    if ([string]::IsNullOrWhiteSpace($ans)) { return (-not $DefaultNo) }
    return ($ans -match '^(y|yes)$')
}

function Ask-Confirm {
    # Xac nhan manh: nguoi dung phai go dung chuoi yeu cau (cho thao tac pha huy)
    param([string]$Prompt,[string]$Word = 'DONGY')
    Write-Host "  $Prompt" -ForegroundColor Yellow
    $ans = Read-Host "  Gõ chính xác [$Word] rồi Enter để xác nhận (bỏ trống = hủy)"
    return ($ans -ceq $Word)
}

# =============================================================================
#  KHUNG CHECKLIST / TIEN DO / VERBOSE  (dung chung cho RA QUET, GO BO, KHOI PHUC...)
# =============================================================================
#  Muc dich: moi giai doan (ra quet / sao luu / go bo / kich hoat lai) chay duoi dang
#  MOT CHECKLIST DUY NHAT - in danh sach 1 lan, sau do TUNG DONG duoc CAP NHAT TAI CHO
#  (dua con tro console ve dung dong roi ghi de) khi buoc do bat dau va khi hoan tat.
#  KHONG in lai toan bo danh sach, KHONG in rieng cac dong dien giai/ket qua chi tiet ra
#  man hinh (chi luu vao Detail/Findings de Show-TargetReport trinh bay day du ve sau) -
#  tranh tinh trang mot noi dung bi lap lai nhieu lan qua nhieu doan (checklist tinh ->
#  log chay tung buoc -> bang tong ket) nhu truoc.
#
#  Cach hien thi tung dong: "[mark] N. Tên bước: NHÃN - ghi chú"
#    CHUACHAY  [ ] trắng   - chưa chạy tới (chỉ có tên bước, chưa có nhãn/ghi chú)
#    DANGCHAY  [>] vàng    - "Đang thực thi..." + ghi chú đang làm gì
#    DAT       [v] xanh lá - "ĐẠT" + ghi chú kết quả
#    BATTHUONG [x] đỏ      - "BẤT THƯỜNG" + dấu hiệu phát hiện được (can thiệp kỹ thuật)
#    LUUY      [!] vàng    - "CẦN LƯU Ý" + lý do cần xác minh thêm
#    LOI       [!] đỏ      - "LỖI" + thông tin lỗi
#    BOQUA     [-] xám     - "BỎ QUA" + lý do không áp dụng
#
#  Neu console khong the dat lai vi tri con tro (vd output bi redirect ra tep, chay
#  trong host khong ho tro nhu ISE...), tu dong chuyen sang che do du phong: chi in
#  DUY NHAT 1 dong cho moi buoc, ngay luc buoc do hoan tat (bo qua trang thai cho/dang
#  chay) - van khong lap lai noi dung, chi la khong "song" (live) duoc tai cho.
#
#  Luu y ky thuat: dung bien $Script: (khong dung $Global:) de khong ro ri ra
#  phien PowerShell cua nguoi dung sau khi script ket thuc.

$Script:CL = $null           # checklist dang chay
$Script:ScanFresh = $false   # ket qua quet hien tai co con dung voi trang thai may khong
$Script:CLCursorOk = $null   # cache: console hien tai co dat lai duoc vi tri con tro khong

function Get-ConsoleWidth {
    try { $w = [Console]::BufferWidth; if ($w -gt 10) { return $w } } catch {}
    return 120
}

function Test-CursorSupport {
    if ($null -ne $Script:CLCursorOk) { return $Script:CLCursorOk }
    $ok = $false
    try {
        if (-not [Console]::IsOutputRedirected) {
            $l = [Console]::CursorLeft; $t = [Console]::CursorTop
            [Console]::SetCursorPosition($l, $t)   # vong lap khong doi - chi de xac nhan co ho tro that
            $ok = $true
        }
    } catch { $ok = $false }
    $Script:CLCursorOk = $ok
    return $ok
}

function Format-ChecklistLine {
    # Cat bot cho vua DUNG 1 dong console - tranh xuong dong ngoai y muon (vd ten buoc dai
    # gap doi tren console 80 cot mac dinh) lam LECH gia dinh "moi buoc = dung 1 hang" ma
    # Update-ChecklistItem dang dua vao. Dung chung cho ca dong danh sach cho ban dau
    # (Start-Checklist) lan dong cap nhat tai cho (Update-ChecklistItem) de bao dam nhat
    # quan tuyet doi ve so hang giua 2 lan in.
    param([string]$Text, [switch]$Pad)
    $width = Get-ConsoleWidth
    $line = $Text
    if ($line.Length -ge $width) { $line = $line.Substring(0, [Math]::Max(0, $width - 1)) }
    if ($Pad) { $line = $line.PadRight($width - 1) }
    return $line
}

function Get-ChecklistMarkInfo {
    param([string]$Status)
    switch ($Status) {
        'CHUACHAY'  { @{ Mark='[ ]'; Color='White';    Label=$null } }
        'DANGCHAY'  { @{ Mark='[>]'; Color='Yellow';   Label='Đang thực thi...' } }
        'DAT'       { @{ Mark='[v]'; Color='Green';    Label='HOÀN THÀNH' } }
        'BATTHUONG' { @{ Mark='[x]'; Color='Red';      Label='BẤT THƯỜNG' } }
        'LUUY'      { @{ Mark='[!]'; Color='Yellow';   Label='LƯU Ý' } }
        'LOI'       { @{ Mark='[!]'; Color='Yellow';   Label='LỖI' } }
        'BOQUA'     { @{ Mark='[-]'; Color='DarkGray'; Label='BỎ QUA' } }
        default     { @{ Mark='[ ]'; Color='White';    Label=$null } }
    }
}

function Update-ChecklistItem {
    # Ve lai (hoac in moi, neu khong dat lai duoc vi tri con tro) DUY NHAT 1 dong cho 1 buoc.
    #
    # QUAN TRONG: dung TOA DO TUONG DOI so voi vi tri con tro HIEN TAI, KHONG dung so dong
    # tuyet doi da luu san tu luc Start-Checklist. Ly do: neu console cuon (scroll) trong
    # luc checklist dang chay - vi du do cua so nho hon so dong da in, hoac do moi truong
    # host xu ly buffer khac voi Windows Console thong thuong - thi cac so dong tuyet doi
    # da luu se KHONG con dung nua, dan den ghi de nham dong (da gap: cap nhat buoc 1,2 lai
    # de len vi tri buoc 8,9). Bat bien dung o day: MOI LAN ham nay duoc goi, con tro dang
    # dung o dung 1 vi tri co dinh - ngay SAU dong trong o cuoi danh sach ("vi tri nghi").
    # Tu vi tri nghi doc duoc luc goi ham, suy nguoc ra dung dong cua tung buoc bang phep
    # tru don gian - luon dung du buffer co cuon bao nhieu, vi ca danh sach va vi tri nghi
    # cung dich chuyen mot luot voi nhau.
    param([int]$Index)
    if (-not $Script:CL -or $Index -lt 0 -or $Index -ge $Script:CL.Items.Count) { return }
    $it = $Script:CL.Items[$Index]
    $mi = Get-ChecklistMarkInfo -Status $it.Status

    if ($it.Status -eq 'DANGCHAY') {
        $suffix = ": $($mi.Label)" + $(if ($it.RunNote) { " $($it.RunNote)" } else { '' })
    } elseif ($mi.Label) {
        $suffix = ": $($mi.Label)" + $(if ($it.Note) { " - $($it.Note)" } else { '' })
    } else {
        $suffix = ''
    }
    $text = "   {0} {1,2}. {2}{3}" -f $mi.Mark, ($Index + 1), $it.Name, $suffix

    if ($Script:CL.UseCursor) {
        try {
            $count  = $Script:CL.Items.Count
            $park   = [Console]::CursorTop   # vi tri nghi hien tai - doc TUOI moi lan, khong dung so cu
            $target = $park - ($count - $Index) - 1
            if ($target -ge 0) {
                [Console]::SetCursorPosition(0, $target)
                Write-Host (Format-ChecklistLine -Text $text -Pad) -ForegroundColor $mi.Color -NoNewline
                [Console]::SetCursorPosition(0, $park)   # tra con tro ve DUNG vi tri nghi ban dau
                return
            }
        } catch { }
    }
    # Du phong (khong dat lai duoc vi tri con tro): chi in 1 lan duy nhat, luc buoc HOAN TAT -
    # bo qua trang thai CHUACHAY/DANGCHAY de khong in lai/lap noi dung.
    if ($it.Status -notin @('CHUACHAY','DANGCHAY')) { Write-Host (Format-ChecklistLine -Text $text) -ForegroundColor $mi.Color }
}

function Start-Checklist {
    param([string]$Title,[string[]]$Steps)
    $items = New-Object System.Collections.ArrayList
    foreach ($s in $Steps) {
        [void]$items.Add([PSCustomObject]@{
            Name = $s; Status = 'CHUACHAY'; Note = ''; RunNote = ''; Detail = @()
        })
    }
    $Script:CL = [PSCustomObject]@{
        Title = $Title; Items = $items; Index = -1; Started = Get-Date
        UseCursor = (Test-CursorSupport)
    }
    Write-Host ''
    Write-Host ('  ' + ('=' * 68)) -ForegroundColor Cyan
    Write-Host ("   DANH SÁCH CÔNG VIỆC: $Title") -ForegroundColor Cyan
    Write-Host ('  ' + ('=' * 68)) -ForegroundColor Cyan
    if ($Script:CL.UseCursor) {
        for ($i = 0; $i -lt $items.Count; $i++) {
            $line = "   [ ] {0,2}. {1}" -f ($i + 1), $items[$i].Name
            Write-Host (Format-ChecklistLine -Text $line) -ForegroundColor White
        }
        # Dong trong ngay sau danh sach = "vi tri nghi" co dinh ma Update-ChecklistItem
        # se dung lam moc doc lai TUOI moi lan (xem giai thich o Update-ChecklistItem).
        Write-Host ''
    }
}

function Start-Step {
    # Bat dau buoc ke tiep trong checklist. Tra ve doi tuong buoc de ghi ket qua.
    param([string]$Note = '')
    if (-not $Script:CL) { return $null }
    $Script:CL.Index++
    $i = $Script:CL.Index
    if ($i -ge $Script:CL.Items.Count) { return $null }
    $it = $Script:CL.Items[$i]
    $it.Status  = 'DANGCHAY'
    $it.RunNote = $Note
    Update-ChecklistItem -Index $i
    return $it
}

function Add-StepDetail {
    # Ghi lai dien giai chi tiet BEN TRONG mot buoc (de Show-TargetReport dung ve sau).
    # KHONG in ra man hinh nua - checklist chi con DUY NHAT 1 dong/buoc, cap nhat tai cho.
    param([string]$Text,[string]$Color = 'DarkGray')
    if ($Script:CL -and $Script:CL.Index -ge 0 -and $Script:CL.Index -lt $Script:CL.Items.Count) {
        $Script:CL.Items[$Script:CL.Index].Detail += $Text
    }
}

function Complete-Step {
    # Ket thuc buoc hien tai voi trang thai va ghi chu - cap nhat NGAY vao dong cua buoc do.
    param(
        [ValidateSet('DAT','BATTHUONG','LUUY','BOQUA','LOI')] [string]$Status = 'DAT',
        [string]$Note = ''
    )
    if (-not $Script:CL -or $Script:CL.Index -lt 0 -or $Script:CL.Index -ge $Script:CL.Items.Count) { return }
    $it = $Script:CL.Items[$Script:CL.Index]
    $it.Status = $Status
    $it.Note   = $Note
    Update-ChecklistItem -Index $Script:CL.Index
}

function Invoke-Step {
    # Chay mot buoc phat hien: tu dem so phat hien MOI do buoc do sinh ra, tu quyet
    # dinh trang thai DAT / BATTHUONG / LUUY. Dung cho cac module Invoke-Detect-*.
    # Chi tiet tung dau hieu (Signal/Vi tri/Y nghia...) KHONG in truc tiep o day nua -
    # da luu san trong $Script:Findings de Show-TargetReport trinh bay day du ve sau,
    # tranh lap lai cung mot noi dung 2 lan (mot lan luc quet, mot lan trong bao cao).
    param(
        [string]$Note = '',
        [scriptblock]$Action
    )
    $it = Start-Step -Note $Note
    $before = $Script:Findings.Count
    $err = $null
    try { & $Action } catch { $err = $_ }
    $new = $Script:Findings.Count - $before
    if ($err) {
        $msg = ($err.ToString() -replace '\s+',' ')
        Complete-Step -Status LOI -Note ("Không hoàn tất: " + $msg.Substring(0, [Math]::Min(90, $msg.Length)))
        return
    }
    if ($new -le 0) { Complete-Step -Status DAT -Note 'Không phát hiện dấu hiệu bất thường'; return }

    $added   = @($Script:Findings)[$before..($Script:Findings.Count - 1)]
    $needVer = @($added | Where-Object { $_.Verify })
    $real    = @($added | Where-Object { -not $_.Verify })
    if ($real.Count -gt 0) {
        Complete-Step -Status BATTHUONG -Note ("$($real.Count) dấu hiệu can thiệp" + $(if ($needVer.Count -gt 0) { " + $($needVer.Count) mục cần xác minh" } else { '' }))
    } else {
        Complete-Step -Status LUUY -Note "$($needVer.Count) mục cần xác minh với CNTT/chứng từ"
    }
}

# =============================================================================
#  TIEN ICH CHUNG
# =============================================================================
$Script:WINDOWS_APPID = '55c92734-d682-4d71-983e-d6ec3f16059f'
$Script:OFFICE_APPID  = '0ff1ce15-a989-479d-af46-f275c6370663'   # Office 2013+ (SPP)
$Script:OFFICE14_APPID= '59a52881-a989-479d-af46-f275c6370663'   # Office 2010 (OSPP)

function Mask-Key {
    param([string]$Key)
    if ([string]::IsNullOrWhiteSpace($Key)) { return '(không có)' }
    $k = ($Key -replace '[^A-Za-z0-9]','')
    if ($k.Length -lt 5) { return $Key }
    # In day du key that (khong che), dinh dang lai theo nhom 5 ky tu ngan cach bang dau '-'
    $groups = for ($i = 0; $i -lt $k.Length; $i += 5) {
        $len = [Math]::Min(5, $k.Length - $i)
        $k.Substring($i, $len)
    }
    return ($groups -join '-')
}

function Test-Internet {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $ar = $c.BeginConnect('8.8.8.8', 53, $null, $null)
        $ok = $ar.AsyncWaitHandle.WaitOne(1500) -and $c.Connected
        try { $c.EndConnect($ar) } catch {}
        $c.Close(); return $ok
    } catch { return $false }
}

function Get-WindowsInfo {
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $build = 0; [void][int]::TryParse($cv.CurrentBuildNumber, [ref]$build)
    $name = $cv.ProductName
    if ($build -ge 22000 -and $name) { $name = $name -replace 'Windows 10','Windows 11' }
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        ProductName = $name
        EditionID   = $cv.EditionID
        Build       = $build
        DisplayVer  = $cv.DisplayVersion
        Arch        = $env:PROCESSOR_ARCHITECTURE
        InstallDate = if ($os) { $os.InstallDate } else { $null }
        Caption     = if ($os) { $os.Caption } else { $name }
    }
}

# Phan giai va phan loai mot may chu KMS (khong phu thuoc danh sach den)
function Get-KmsHostClass {
    param([string]$KmsHost)
    if ([string]::IsNullOrWhiteSpace($KmsHost)) { return 'NONE' }
    $h = $KmsHost.Trim().Trim('"').ToLower()
    if ($h -eq '10.0.0.10')                                   { return 'MAS_ONLINE_PLACEHOLDER' }  # D1
    if ($h -eq '127.0.0.2')                                   { return 'MAS_TSFORGE_LOCK' }        # D1
    if ($h -match '^(127\.|::1|localhost|0\.0\.0\.0)')        { return 'LOCAL_EMULATOR' }          # D1
    if ($h -match 'kms\.core\.windows\.net')                  { return 'AZURE_OFFICIAL' }
    $privatePat = '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|169\.254\.|127\.|::1|fd|fe80)'
    # Neu la ten mien -> thu phan giai
    $ips = @()
    if ($h -match '^[0-9\.]+$' -or $h -match ':') { $ips = @($h) }
    else {
        try { $ips = [System.Net.Dns]::GetHostAddresses($h) | ForEach-Object { $_.ToString() } } catch { return 'PUBLIC_HOST_UNRESOLVED' }
    }
    if (-not $ips -or $ips.Count -eq 0) { return 'PUBLIC_HOST_UNRESOLVED' }
    $hasPublic = $ips | Where-Object { $_ -notmatch $privatePat }
    if ($hasPublic) { return 'PUBLIC_HOST' }          # D1
    return 'PRIVATE_HOST'                              # can xac minh voi IT
}

# Truy van san pham cap phep (Windows hoac Office) qua WMI/CIM - bat bien ngon ngu
function Get-LicenseProducts {
    param([string]$AppId)
    try {
        Get-CimInstance -ClassName SoftwareLicensingProduct -ErrorAction Stop |
            Where-Object { $_.ApplicationID -eq $AppId -and $_.PartialProductKey } |
            Select-Object Name, Description, ProductKeyChannel, PartialProductKey, LicenseStatus,
                          GracePeriodRemaining, KeyManagementServiceMachine, KeyManagementServicePort,
                          ID, ApplicationID, LicenseStatusReason
    } catch { @() }
}

# Office 2010 dung lop OSPP rieng
function Get-Office14Products {
    try {
        Get-CimInstance -ClassName OfficeSoftwareProtectionProduct -ErrorAction Stop |
            Where-Object { $_.PartialProductKey } |
            Select-Object Name, Description, ProductKeyChannel, PartialProductKey, LicenseStatus,
                          GracePeriodRemaining, KeyManagementServiceMachine, ID
    } catch { @() }
}

function Get-BiosOemKey {
    try {
        $sls = Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction Stop
        [PSCustomObject]@{
            Key         = $sls.OA3xOriginalProductKey
            Description = $sls.OA3xOriginalProductKeyDescription
            Pkpn        = $sls.OA3xOriginalProductKeyPkPn
            RearmCount  = $sls.RemainingWindowsReArmCount
        }
    } catch { [PSCustomObject]@{ Key=$null; Description=$null; Pkpn=$null; RearmCount=$null } }
}

# =============================================================================
#  GIAI MA KEY DAY DU TU DigitalProductId TRONG REGISTRY
# -----------------------------------------------------------------------------
#  DigitalProductId (HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion) la du
#  lieu nhi phan Windows tu luu de HIEN THI LAI product key CUA CHINH MAY NAY
#  (vd trong cac cong cu xem key hop phap nhu NirSoft ProduKey). Day CHI LA ma
#  hoa Base24 cong khai (obfuscation), KHONG PHAI ma hoa bao mat, va thuat toan
#  giai ma nay da duoc cong bo rong rai, khong lien quan crack/bypass ban quyen.
#  Nguon doi chieu thuat toan: woshub.com "How to Extract Your Windows Product
#  (License) Key from a Computer" - da kiem chung cho ca dinh dang truoc va tu
#  Windows 8 tro len (co chen ky tu 'N').
#
#  GIOI HAN QUAN TRONG (KHONG duoc bo qua khi hien thi cho nguoi dung):
#   - Neu may kich hoat qua "giay phep so" (lien ket tai khoan Microsoft/phan
#     cung, khong nhap key) hoac qua KMS, DigitalProductId thuong chi chua KEY
#     CHUNG (GVLK) cua bo cai, KHONG PHAI key that da mua. Phai doi chieu voi
#     kenh cap phep (OEM/Retail/MAK/Volume) truoc khi coi day la "key that".
#   - Neu la key MAK, Microsoft KHONG luu key that vao registry (vi ly do bao
#     mat) nen ket qua giai ma se khong phan anh key MAK dang dung.
function ConvertFrom-DigitalProductId {
    param([byte[]]$KeyBytes)   # dung 15 byte, la doan $DigitalProductId[52..66]

    if (-not $KeyBytes -or $KeyBytes.Count -lt 15) { return $null }

    # Lam viec tren ban sao de khong lam hong du lieu goc
    $bytes = [byte[]]($KeyBytes[0..14])
    $base24 = 'BCDFGHJKMPQRTVWXY2346789'
    $decodeStringLength = 24   # 25 lan lap -> 25 ky tu base24 truoc khi xu ly chen 'N'
    $decodeLength = 14         # chi so byte cuoi trong doan 15 byte (0..14)
    $decodedKey = ''

    $containsN = ([math]::Floor([int]$bytes[$decodeLength] / 8)) -band 1
    $bytes[$decodeLength] = [byte]($bytes[$decodeLength] -band 0xF7)

    for ($i = $decodeStringLength; $i -ge 0; $i--) {
        $digitMapIndex = 0
        for ($j = $decodeLength; $j -ge 0; $j--) {
            $digitMapIndex = ($digitMapIndex * 256) -bxor $bytes[$j]
            $bytes[$j] = [byte]([math]::Truncate($digitMapIndex / $base24.Length))
            $digitMapIndex = $digitMapIndex % $base24.Length
        }
        $decodedKey = $base24[$digitMapIndex] + $decodedKey
    }

    if ($containsN) {
        $firstLetterIndex = $base24.IndexOf($decodedKey[0])
        $decodedKey = $decodedKey.Remove(0, 1)
        $decodedKey = $decodedKey.Substring(0, $firstLetterIndex) + 'N' + $decodedKey.Remove(0, $firstLetterIndex)
    }

    if ($decodedKey.Length -ne 25) { return $null }
    for ($t = 20; $t -ge 5; $t -= 5) { $decodedKey = $decodedKey.Insert($t, '-') }
    return $decodedKey
}

# Doc DigitalProductId cua Windows tu registry va giai ma thanh key day du.
# Tra ve $null neu khong doc duoc hoac ket qua khong dung dinh dang 25 ky tu
# (khong bao gio nem loi ra ngoai - day chi la thong tin bo sung, khong duoc
# lam gian doan luong quet chinh neu that bai).
# MAK: sau khi kich hoat, Microsoft CHU DONG xoa key that khoi DigitalProductId vi ly
# do bao mat (tranh trich xuat lai key Volume Licensing) va thay bang chuoi gia toan
# ky tu 'B' (vd BBBBB-BBBBB-BBBBB-BBBBB-BBBBB). Day la thiet ke co chu dich cua
# Microsoft, KHONG PHAI gioi han cua cong cu nay va KHONG co cach nao doc lai key
# MAK that tu registry sau khi da kich hoat. Phai nhan dien va noi ro, KHONG duoc
# hien thi chuoi BBBBB... nhu the do la key that.
function Test-MakPlaceholderKey {
    param([string]$Key)
    if (-not $Key) { return $false }
    return ($Key -match '^(B{5}-){4}B{5}$')
}

function Get-WindowsRegistryProductKey {
    try {
        $raw = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
                                  -Name 'DigitalProductId' -ErrorAction Stop).DigitalProductId
        if (-not $raw -or $raw.Count -lt 67) { return $null }
        $key = ConvertFrom-DigitalProductId -KeyBytes $raw[52..66]
        if (-not $key) { return $null }
        if (Test-MakPlaceholderKey $key) { return $null }   # MAK da bi xoa - xem ham Test-MakPlaceholderKey
        if ($key -match '^[A-Za-z0-9]{5}(-[A-Za-z0-9]{5}){4}$') { return $key }
        return $null
    } catch { return $null }
}

# =============================================================================
#  QUET & GIAI MA DigitalProductId CHO OFFICE/VISIO/PROJECT (MSI/Volume/Retail)
# -----------------------------------------------------------------------------
#  Visio va Project khi cai qua MSI/Volume License dung CHUNG ha tang SPP voi
#  Office (cung ApplicationID '0ff1ce15-...' trong SoftwareLicensingProduct - xem
#  $Script:OFFICE_APPID), nen da duoc $Script:OffProds thu thap san. Diem con
#  thieu la: (1) chi lay 1 san pham dau tien lam "dai dien" thay vi liet ke het,
#  va (2) chua giai ma key day du tu registry cho Office/Visio/Project.
#
#  Theo nguon doi chieu (chentiangemalc.wordpress.com), thuat toan Base24 giai ma
#  DigitalProductId la MOT, dung chung cho ca Windows va Office tu ban XP tro len
#  (ngoai tru cac ban Office 365/Click-to-Run kieu subscription - vNext - vi cac
#  ban nay KHONG dung co che DigitalProductId truyen thong ma dung "giay phep so"
#  gan voi tai khoan Microsoft/phan cung, nen KHONG THE giai ma duoc theo cach
#  nay - day la gioi han cua chinh co che C2R/vNext, khong phai gioi han cong cu).
#
#  Vi tri registry: HKLM:\SOFTWARE\Microsoft\Office\<version>\Registration\{GUID}
#  (va ban sao WOW6432Node cho Office 32-bit tren Windows 64-bit). Moi {GUID} la
#  mot san pham/goi ngon ngu duoc cai (Office core, Visio, Project, ...) nen mot
#  may co the co NHIEU DigitalProductId - can quet het, khong dung lai o cai dau
#  tien tim thay.
function Get-OfficeRegistryProductKeys {
    # QUAN TRONG: TUYET DOI KHONG duyet de quy toan bo 'HKLM:\...\Microsoft\Office' - nhanh
    # nay chua ca cau hinh Outlook (profile/autodiscover cache), MRU, telemetry, ClickToRun,
    # add-in... co the len toi hang nghin subkey tren may da cai du Office, khien buoc nay
    # "dung yen" hang chuc giay den vai phut (da gap thuc te - xem bao loi). DigitalProductId
    # CHI nam duoi '<version>\Registration\{GUID}', nen chi duyet dung nhanh do.
    $versions = @('11.0', '12.0', '14.0', '15.0', '16.0')
    $hives = @('HKLM:\SOFTWARE\Microsoft\Office', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office')
    $paths = @()
    foreach ($hive in $hives) {
        foreach ($v in $versions) {
            $root = Join-Path $hive "$v\Registration"
            if (-not (Test-Path $root)) { continue }
            try { $paths += (Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.PSPath }) } catch {}
        }
    }

    $results = @()
    foreach ($p in ($paths | Select-Object -Unique)) {
        try {
            $raw = (Get-ItemProperty -Path $p -Name 'DigitalProductId' -ErrorAction Stop).DigitalProductId
        } catch { continue }
        if (-not $raw -or $raw.Count -lt 67) { continue }

        $isMak = $false
        $key = ConvertFrom-DigitalProductId -KeyBytes $raw[52..66]
        if ($key -and (Test-MakPlaceholderKey $key)) { $isMak = $true; $key = $null }
        elseif ($key -and -not ($key -match '^[A-Za-z0-9]{5}(-[A-Za-z0-9]{5}){4}$')) { $key = $null }

        # Rut gon duong dan de hien thi: bo tien to provider, giu tu 'Office\...' tro di
        $shortPath = ($p -replace '^Microsoft\.PowerShell\.Core\\Registry::', '') -replace '^HKEY_LOCAL_MACHINE\\', 'HKLM:\'

        $results += [PSCustomObject]@{
            RegistryPath = $shortPath
            Key          = $key
            IsMak        = $isMak
        }
    }
    return $results
}

function Convert-LicenseStatus {
    param($Code)
    switch ([int]$Code) {
        0 { 'Chưa được cấp phép (Unlicensed)' }
        1 { 'Đã kích hoạt (Licensed)' }
        2 { 'Thời gian ân hạn ban đầu (OOB Grace)' }
        3 { 'Thời gian ân hạn OOT' }
        4 { 'Ân hạn không chính hãng (Non-Genuine Grace)' }
        5 { 'Chế độ thông báo (Notification)' }
        6 { 'Ân hạn mở rộng (Extended Grace)' }
        default { "Không xác định ($Code)" }
    }
}

# =============================================================================
#  ENGINE PHAT HIEN
# =============================================================================
# Moi phat hien la mot doi tuong. Category quyet dinh cach phan loai residual/active:
#   ActiveConfig   = cau hinh/DLL dang truc tiep dieu khien kich hoat
#   Artifact       = hien vat ton du (thu muc/tep/tac vu) - co the la rac
#   Behavioral     = dau vet hanh vi (lich su/prefetch/defender) - de xoa, de trung
#   LicenseAnomaly = bat thuong thuoc tinh cap phep tu WMI
$Script:Findings = New-Object System.Collections.Generic.List[object]

function New-Finding {
    param(
        [ValidateSet('Windows','Office')] [string]$Target,
        [string]$Method,
        [ValidateSet('D1','D2','D3','D4')] [string]$Confidence,
        [ValidateSet('ActiveConfig','Artifact','Behavioral','LicenseAnomaly')] [string]$Category,
        [string]$Signal,      # Dau hieu la gi
        [string]$Location,    # Nam o dau
        [string]$Meaning,     # Phan anh dieu gi
        [string]$Evidence,    # Gia tri cu the tim thay
        [hashtable]$Data,     # du lieu ky thuat kem theo (duong dan, ten task...) phuc vu go bo
        [switch]$Verify       # TRUE = "can xac minh voi CNTT/chung tu", KHONG tu ket luan la crack
    )
    $Script:Findings.Add([PSCustomObject]@{
        Target=$Target; Method=$Method; Confidence=$Confidence; Category=$Category
        Signal=$Signal; Location=$Location; Meaning=$Meaning; Evidence=$Evidence
        Data=$Data; Verify=[bool]$Verify
    })
}

# --- Danh sach tham chieu (hop nhat tu MAS_AIO.cmd + WinLicManager + nghien cuu) ---
$Script:CRACK_SERVICES = @(
    'KMSpico','KMService','WinKSO','KMSELDI','KMS_VL_ALL','KMSAuto','AutoKMS',
    'KMSSS','KMSEmulator','vlmcsd','Activation-Renewal','SppExtComObjHook'
)
$Script:CRACK_TASK_PATTERNS = @(
    'AutoKMS','AutoPico','KMSAuto','KMSpico','AutoRearm','KMS_VL_ALL','vlmcsd',
    'Activation-Renewal','KMSEmulator','Re-Loader','SmartKMS'
)
$Script:CRACK_PROC = @(
    'KMSpico','KMSELDI','AutoKMS','KMSAuto','KMSAutoNet','KMSAutoS','AAct','AAct_x64',
    'KMSguard','WinKSO','KMService','vlmcsd','Re-Loader','SppExtComObjHook'
)
# Thu muc/tep hien vat (dung env var giai quyet luc chay)
function Get-CrackArtifactPaths {
    $pf   = $env:ProgramFiles
    $pf86 = ${env:ProgramFiles(x86)}
    $pgd  = $env:ProgramData
    $win  = $env:SystemRoot
    $sys  = Join-Path $win 'System32'
    $paths = @(
        @{ P="$win\AutoKMS";              T='KMS tool folder (AutoKMS)' }
        @{ P="$win\AutoRearm";            T='AutoRearm folder' }
        @{ P="$win\AutoPico";             T='AutoPico folder' }
        @{ P="$win\KMS";                  T='KMS tool folder' }
        @{ P="$pf\KMSpico";               T='KMSpico' }
        @{ P="$pf86\KMSpico";             T='KMSpico (x86)' }
        @{ P="$pgd\KMSpico";              T='KMSpico (ProgramData)' }
        @{ P="$pf\KMSAuto Net";           T='KMSAuto Net' }
        @{ P="$pf86\KMSAuto Net";         T='KMSAuto Net (x86)' }
        @{ P="$pf\KMSAuto";               T='KMSAuto' }
        @{ P="$pgd\KMSAutoS";             T='KMSAuto (ProgramData)' }
        @{ P="$pf\AAct";                  T='AAct' }
        @{ P="$pf86\AAct";                T='AAct (x86)' }
        @{ P="$pf\Activation-Renewal";    T='MAS Online KMS renewal (folder)' }
        @{ P="$pgd\Activation-Renewal";   T='MAS Online KMS renewal (ProgramData)' }
        @{ P="$sys\KMSELDI.exe";          T='KMSELDI.exe' }
        @{ P="$sys\SppExtComObjHook.dll"; T='SPP hook DLL (KMSpico Win8/8.1)' }
        @{ P="$sys\SppExtComObj.exe.bak"; T='Ban sao luu truoc khi va SPP' }
    )
    return $paths
}

# --- 1. Cau hinh KMS (registry + WMI) ----------------------------------------
function Invoke-Detect-WindowsKms {
    param($WinProducts)

    # 1a. WMI: KeyManagementServiceMachine cua san pham Windows
    foreach ($p in $WinProducts) {
        if ($p.KeyManagementServiceMachine) {
            $cls = Get-KmsHostClass $p.KeyManagementServiceMachine
            switch ($cls) {
                'LOCAL_EMULATOR' { New-Finding -Target Windows -Method 'KMS cuc bo' -Confidence D1 -Category ActiveConfig `
                    -Signal 'Máy chủ KMS trỏ về địa chỉ loopback' -Location "WMI SoftwareLicensingProduct -> KeyManagementServiceMachine = $($p.KeyManagementServiceMachine)" `
                    -Meaning 'Có giả lập KMS chạy cục bộ trên chính máy (KMSpico/KMSAuto/vlmcsd...). KMS thật không bao giờ là localhost.' `
                    -Evidence $p.KeyManagementServiceMachine -Data @{ KmsHost=$p.KeyManagementServiceMachine } }
                'MAS_ONLINE_PLACEHOLDER' { New-Finding -Target Windows -Method 'Online KMS (MAS)' -Confidence D1 -Category ActiveConfig `
                    -Signal 'Máy chủ KMS = 10.0.0.10 (IP giả của MAS)' -Location "WMI -> KeyManagementServiceMachine = 10.0.0.10" `
                    -Meaning 'Địa chỉ không định tuyến, MAS để lại để chặn banner Office. Dấu hiệu đặc trưng của MAS Online KMS.' `
                    -Evidence '10.0.0.10' -Data @{ KmsHost='10.0.0.10' } }
                'MAS_TSFORGE_LOCK' { New-Finding -Target Windows -Method 'TSforge (KMS4k/KMS38)' -Confidence D1 -Category ActiveConfig `
                    -Signal 'Máy chủ KMS = 127.0.0.2 (chữ ký TSforge của MAS)' -Location 'WMI -> KeyManagementServiceMachine = 127.0.0.2' `
                    -Meaning 'MAS ghi 127.0.0.2 khi kích hoạt bằng KMS4k/TSforge (khóa KMS38). Không KMS hợp pháp nào dùng địa chỉ này.' `
                    -Evidence '127.0.0.2' -Data @{ KmsHost='127.0.0.2' } }
                'PUBLIC_HOST' { New-Finding -Target Windows -Method 'Online KMS (công cộng)' -Confidence D1 -Category ActiveConfig `
                    -Signal 'Máy chủ KMS phân giải ra IP công cộng' -Location "WMI -> $($p.KeyManagementServiceMachine)" `
                    -Meaning 'Microsoft KHÔNG cung cấp máy chủ KMS công cộng. Mọi KMS công cộng đều là dịch vụ lậu.' `
                    -Evidence $p.KeyManagementServiceMachine -Data @{ KmsHost=$p.KeyManagementServiceMachine } }
                'PUBLIC_HOST_UNRESOLVED' { New-Finding -Target Windows -Method 'Online KMS (công cộng)' -Confidence D2 -Category ActiveConfig `
                    -Signal 'Máy chủ KMS là tên miền bên ngoài (không phân giải được lúc quét)' -Location "WMI -> $($p.KeyManagementServiceMachine)" `
                    -Meaning 'Tên miền KMS bên ngoài; cần xác minh. Microsoft không cung cấp KMS công cộng.' `
                    -Evidence $p.KeyManagementServiceMachine -Data @{ KmsHost=$p.KeyManagementServiceMachine } }
                'AZURE_OFFICIAL' { New-Finding -Target Windows -Method 'Cấu hình KMS Azure' -Confidence D3 -Category LicenseAnomaly -Verify `
                    -Signal 'Máy chủ KMS = kms.core.windows.net' -Location "WMI -> $($p.KeyManagementServiceMachine)" `
                    -Meaning 'Điểm cuối KMS hợp pháp của Microsoft, CHỈ hợp lệ trong máy ảo Azure. Nếu không phải VM Azure -> bất thường.' `
                    -Evidence $p.KeyManagementServiceMachine -Data @{ KmsHost=$p.KeyManagementServiceMachine } }
                'PRIVATE_HOST' { New-Finding -Target Windows -Method 'KMS doanh nghiệp (cần xác minh)' -Confidence D3 -Category LicenseAnomaly -Verify `
                    -Signal 'Máy chủ KMS trên địa chỉ nội bộ' -Location "WMI -> $($p.KeyManagementServiceMachine)" `
                    -Meaning 'Phù hợp với triển khai KMS doanh nghiệp hợp lệ. Cần xác nhận với bộ phận CNTT.' `
                    -Evidence $p.KeyManagementServiceMachine -Data @{ KmsHost=$p.KeyManagementServiceMachine } }
            }
        }
    }

    # 1b. Registry: doc de quy toan bo cay SPP tim gia tri KeyManagementServiceName bat thuong
    $sppRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform'
    )
    foreach ($root in $sppRoots) {
        if (-not (Test-Path $root)) { continue }
        $keys = @($root)
        try { $keys += (Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.PSPath }) } catch {}
        foreach ($k in $keys) {
            $kms = (Get-ItemProperty -Path $k -Name 'KeyManagementServiceName' -ErrorAction SilentlyContinue).KeyManagementServiceName
            if (-not $kms) { continue }
            $cls = Get-KmsHostClass $kms
            $short = ($k -replace '.*SoftwareProtectionPlatform','SPP')
            switch ($cls) {
                'MAS_TSFORGE_LOCK' { New-Finding -Target Windows -Method 'TSforge (KMS4k/KMS38)' -Confidence D1 -Category ActiveConfig `
                    -Signal 'Giá trị 127.0.0.2 trong subkey SPP' -Location "$short -> KeyManagementServiceName = 127.0.0.2" `
                    -Meaning 'Chữ ký TSforge/KMS4k của MAS ghi trực tiếp vào registry (khóa KMS38).' `
                    -Evidence "127.0.0.2 @ $short" -Data @{ RegKey=$k; RegVal='KeyManagementServiceName' } }
                'MAS_ONLINE_PLACEHOLDER' { New-Finding -Target Windows -Method 'Online KMS (MAS)' -Confidence D1 -Category ActiveConfig `
                    -Signal 'Giá trị 10.0.0.10 trong registry SPP' -Location "$short -> KeyManagementServiceName = 10.0.0.10" `
                    -Meaning 'IP giả MAS để lại để chặn banner Office.' `
                    -Evidence "10.0.0.10 @ $short" -Data @{ RegKey=$k; RegVal='KeyManagementServiceName' } }
                'LOCAL_EMULATOR' { New-Finding -Target Windows -Method 'KMS cuc bo' -Confidence D1 -Category ActiveConfig `
                    -Signal 'Máy chủ KMS loopback trong registry SPP' -Location "$short -> KeyManagementServiceName = $kms" `
                    -Meaning 'Cấu hình trỏ về giả lập KMS cục bộ.' `
                    -Evidence "$kms @ $short" -Data @{ RegKey=$k; RegVal='KeyManagementServiceName' } }
                'PUBLIC_HOST' { New-Finding -Target Windows -Method 'Online KMS (công cộng)' -Confidence D1 -Category ActiveConfig `
                    -Signal 'Máy chủ KMS công cộng trong registry SPP' -Location "$short -> $kms" `
                    -Meaning 'KMS công cộng = dịch vụ lậu.' -Evidence "$kms @ $short" -Data @{ RegKey=$k; RegVal='KeyManagementServiceName' } }
            }
        }
    }

    # 1c. Khoa chinh sach NoGenTicket (chan gui xac thuc)
    $polKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform'
    $ngt = (Get-ItemProperty -Path $polKey -Name 'NoGenTicket' -ErrorAction SilentlyContinue).NoGenTicket
    if ($ngt -eq 1) {
        New-Finding -Target Windows -Method 'Can thiệp Registry' -Confidence D2 -Category ActiveConfig `
            -Signal "Khoa 'NoGenTicket' = 1" -Location "$polKey" `
            -Meaning 'Chặn hệ thống gửi về xác thực chính hãng - thường do công cụ crack đặt.' `
            -Evidence 'NoGenTicket=1' -Data @{ RegKey=$polKey; RegVal='NoGenTicket' }
    }
}

# --- 2. Cong 1688 lang nghe tren loopback -------------------------------------
function Invoke-Detect-KmsPort {
    $conns = @()
    try {
        $conns = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
            Where-Object { $_.LocalPort -eq 1688 -and $_.LocalAddress -in @('127.0.0.1','0.0.0.0','::','::1') }
    } catch {
        # PowerShell cu / thieu module: dung netstat
        try {
            $ns = netstat -ano | Select-String ':1688\s' | Select-String 'LISTENING'
            foreach ($line in $ns) {
                if ($line -match '(\d+)\s*$') {
                    $procId = [int]$Matches[1]
                    $conns += [PSCustomObject]@{ OwningProcess = $procId; LocalPort = 1688 }
                }
            }
        } catch {}
    }
    foreach ($c in $conns) {
        $proc = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
        $sig = if ($proc -and $proc.Path) { (Get-AuthenticodeSignature -FilePath $proc.Path -ErrorAction SilentlyContinue) } else { $null }
        $signed = $sig -and $sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -match 'Microsoft'
        $isSppsvc = $proc -and $proc.Name -match 'sppsvc'
        if ($signed -and $isSppsvc) {
            # Co the la KMS host hop phap -> ghi nhan D3 de xac minh
            New-Finding -Target Windows -Method 'KMS Host (cần xác minh)' -Confidence D3 -Category LicenseAnomaly -Verify `
                -Signal 'Cổng 1688 lắng nghe bởi sppsvc.exe có chữ ký Microsoft' -Location "TCP 1688 <- $($proc.Name) (PID $($c.OwningProcess))" `
                -Meaning 'Có thể máy này LÀ KMS host hợp pháp của đơn vị (kênh CSVLK). Cần xác nhận với CNTT.' `
                -Evidence "sppsvc PID $($c.OwningProcess)" -Data @{}
        } else {
            $pname = if ($proc) { $proc.Name } else { "PID $($c.OwningProcess)" }
            New-Finding -Target Windows -Method 'KMS cuc bo' -Confidence D1 -Category ActiveConfig `
                -Signal 'Cổng 1688 đang lắng nghe bởi tiến trình KHÔNG có chữ ký Microsoft' -Location "TCP 1688 <- $pname (PID $($c.OwningProcess))" `
                -Meaning 'Đây là dấu hiệu đơn lẻ mạnh nhất của giả lập KMS cục bộ đang chạy.' `
                -Evidence "$pname @ 1688 (Signature: $(if($sig){$sig.Status}else{'không rõ'}))" `
                -Data @{ ProcId=$c.OwningProcess; ProcPath=$(if($proc){$proc.Path}) }
        }
    }
}

# --- 3. Hien vat cong cu (thu muc/tep/service/tien trinh) ---------------------
function Invoke-Detect-ToolArtifacts {
    foreach ($entry in (Get-CrackArtifactPaths)) {
        if (Test-Path -LiteralPath $entry.P -ErrorAction SilentlyContinue) {
            $conf = if ($entry.P -match 'SppExtComObjHook|SppExtComObj\.exe\.bak') { 'D1' } else { 'D1' }
            New-Finding -Target Windows -Method 'Hiện vật công cụ KMS' -Confidence $conf -Category Artifact `
                -Signal "Tồn tại: $($entry.T)" -Location $entry.P `
                -Meaning 'Thư mục/tệp do công cụ kích hoạt trái phép tạo ra. Microsoft không đặt tệp tại vị trí này.' `
                -Evidence $entry.P -Data @{ Path=$entry.P; Kind='FileOrFolder' }
        }
    }
    # Service
    foreach ($svcName in $Script:CRACK_SERVICES) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            New-Finding -Target Windows -Method 'Hiện vật công cụ KMS' -Confidence D1 -Category Artifact `
                -Signal "Service crack: $svcName" -Location "Services -> $svcName ($($svc.Status))" `
                -Meaning 'Service chạy ngầm của công cụ KMS để tồn tại qua khởi động lại và định kỳ kích hoạt lại.' `
                -Evidence $svcName -Data @{ Service=$svcName }
        }
    }
    # Tien trinh dang chay
    $procs = Get-Process -ErrorAction SilentlyContinue
    foreach ($pn in $Script:CRACK_PROC) {
        $m = $procs | Where-Object { $_.Name -like "*$pn*" }
        foreach ($mp in $m) {
            New-Finding -Target Windows -Method 'Hiện vật công cụ KMS' -Confidence D2 -Category Behavioral `
                -Signal "Tiến trình đang chạy: $($mp.Name)" -Location "Process PID $($mp.Id)" `
                -Meaning 'Công cụ kích hoạt đang hoạt động tại thời điểm quét.' `
                -Evidence "$($mp.Name) (PID $($mp.Id))" -Data @{ ProcId=$mp.Id }
        }
    }
}

# --- 4. Va nhi phan / hook thu vien SPP (kiem tra chu ky so) ------------------
function Invoke-Detect-BinaryPatch {
    $sys = Join-Path $env:SystemRoot 'System32'
    $critical = @('sppc.dll','sppcext.dll','sppobjs.dll','sppsvc.exe','slc.dll',
                  'SppExtComObj.exe','clipc.dll','ClipSVC.dll')
    foreach ($f in $critical) {
        $path = Join-Path $sys $f
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $sig = Get-AuthenticodeSignature -FilePath $path -ErrorAction SilentlyContinue
        if (-not $sig) { continue }
        $ok = ($sig.Status -eq 'Valid') -and ($sig.SignerCertificate.Subject -match 'Microsoft')
        # Chap nhan chu ky theo catalog (Status Valid nhung SignerCertificate rong)
        if ($sig.Status -eq 'Valid' -and -not $sig.SignerCertificate) { $ok = $true }
        if (-not $ok) {
            New-Finding -Target Windows -Method 'Vá nhị phân hệ thống' -Confidence D1 -Category ActiveConfig `
                -Signal "Tệp cấp phép hệ thống thiếu chữ ký Microsoft hợp lệ: $f" -Location $path `
                -Meaning 'Tệp cấp phép bị thay thế/vá để bỏ qua kiểm tra bản quyền.' `
                -Evidence "$f (Status: $($sig.Status))" -Data @{ Path=$path }
        }
    }
}

# --- 5. TSforge (bat thuong thuoc tinh cap phep) ------------------------------
function Invoke-Detect-TSforge {
    param($Products, [string]$Target)
    foreach ($p in $Products) {
        $desc = "$($p.Description)"
        $chan = "$($p.ProductKeyChannel)"
        $isLicensed  = ($p.LicenseStatus -eq 1)
        $grace = $p.GracePeriodRemaining
        $isVolumeGvlk = ($desc -match 'VOLUME_KMSCLIENT') -or ($chan -match 'Volume')

        # 5a. Kich hoat qua dien thoai bat thuong (ZeroCID)
        if ($isLicensed -and $desc -match 'phone|Telephone') {
            New-Finding -Target $Target -Method 'TSforge (ZeroCID)' -Confidence D2 -Category LicenseAnomaly `
                -Signal 'Báo cáo kích hoạt qua ĐIỆN THOẠI' -Location "WMI Description: $desc" `
                -Meaning 'Hệ thống báo kích hoạt điện thoại mà không có quy trình điện thoại thực tế - dấu hiệu đặc trưng ZeroCID.' `
                -Evidence $desc -Data @{}
        }

        # 5b. Phan tich han het (KMS38 / KMS4k / chu ky 180 ngay)
        if ($isLicensed -and $grace -ne $null -and $grace -gt 0) {
            $expiry = (Get-Date).AddMinutes([double]$grace)
            $days = ($expiry - (Get-Date)).TotalDays
            if ($expiry.Year -ge 2100) {
                New-Finding -Target $Target -Method 'TSforge (KMS4k)' -Confidence D1 -Category LicenseAnomaly `
                    -Signal "Hạn kích hoạt năm $($expiry.Year) (hàng nghìn năm sau)" -Location "WMI GracePeriodRemaining -> $($expiry.ToString('yyyy-MM-dd'))" `
                    -Meaning 'TSforge KMS4k giả mạo hợp đồng KMS tới ~4000 năm. Không có cơ chế hợp pháp nào tạo ra điều này.' `
                    -Evidence $expiry.ToString('yyyy-MM-dd') -Data @{}
            } elseif ($expiry.Year -ge 2037) {
                New-Finding -Target $Target -Method 'KMS38' -Confidence D1 -Category LicenseAnomaly `
                    -Signal "Hạn kích hoạt năm $($expiry.Year) (~2038)" -Location "WMI GracePeriodRemaining -> $($expiry.ToString('yyyy-MM-dd'))" `
                    -Meaning 'KMS38 kéo hạn đến 19/01/2038 (giới hạn số nguyên 32-bit). Không phải cơ chế cấp phép hợp pháp.' `
                    -Evidence $expiry.ToString('yyyy-MM-dd') -Data @{}
            } elseif ($isVolumeGvlk -and $days -gt 181) {
                New-Finding -Target $Target -Method 'TSforge/KMS bất thường' -Confidence D1 -Category LicenseAnomaly `
                    -Signal "Kênh Volume nhưng thời hạn > 180 ngày ($([int]$days) ngày)" -Location 'WMI GracePeriodRemaining' `
                    -Meaning 'KMS that gioi han cung 180 ngay. Thoi han vuot nguong -> gia mao.' `
                    -Evidence "$([int]$days) ngay" -Data @{}
            } elseif ($isVolumeGvlk -and $days -ge 165 -and $days -le 195) {
                # Chu ky 180 ngay CO THE la KMS doanh nghiep hop le -> dua vao nhom "can xac minh",
                # khong tu dong ket luan la crack (tranh duong tinh gia tren may doanh nghiep).
                New-Finding -Target $Target -Method 'KMS chu ky 180 ngày (cần xác minh)' -Confidence D3 -Category LicenseAnomaly -Verify `
                    -Signal "Kênh Volume + đếm ngược ~180 ngày ($([int]$days) ngày)" -Location 'WMI GracePeriodRemaining' `
                    -Meaning 'Chu kỳ gia hạn KMS 180 ngày. HỢP LỆ nếu đơn vị có KMS host nội bộ; nếu là máy cá nhân không có KMS host thì nhiều khả năng là KMS lậu. Cần xác minh với CNTT/chứng từ.' `
                    -Evidence "$([int]$days) ngay" -Data @{}
            }
        }

        # 5c. GVLK + kich hoat vinh vien (khong dem nguoc) tren kenh Volume
        if ($isLicensed -and $isVolumeGvlk -and ($grace -eq 0 -or $grace -eq $null)) {
            New-Finding -Target $Target -Method 'TSforge/KMS bất thường' -Confidence D1 -Category LicenseAnomaly `
                -Signal 'Kênh Volume (GVLK) + kích hoạt VĨNH VIỄN (không có đếm ngược gia hạn)' -Location "WMI: $desc" `
                -Meaning 'KMS doanh nghiệp hợp lệ LUÔN có đếm ngược 180 ngày. Volume + vĩnh viễn = KMS38/TSforge/lậu.' `
                -Evidence "$chan / grace=$grace" -Data @{}
        }
    }
}

# --- 6. HWID / GenuineTicket / gatherosstate ---------------------------------
function Invoke-Detect-HWID {
    $ticket = "$env:ProgramData\Microsoft\Windows\ClipSVC\GenuineTicket\GenuineTicket.xml"
    $ticketNoExt = "$env:ProgramData\Microsoft\Windows\ClipSVC\GenuineTicket\GenuineTicket"
    foreach ($t in @($ticket, $ticketNoExt)) {
        if (Test-Path -LiteralPath $t) {
            New-Finding -Target Windows -Method 'HWID / Digital License' -Confidence D3 -Category Artifact `
                -Signal 'Tồn dư GenuineTicket trong thư mục ClipSVC' -Location $t `
                -Meaning 'Vé kích hoạt thường bị tiêu thụ và xóa. Tồn dư CÓ THỂ là dấu vết HWID/MAS, nhưng cũng sinh ra trong nâng cấp hợp lệ. KHÔNG thể kết luận chỉ bằng dấu hiệu này.' `
                -Evidence $t -Data @{ Path=$t }
        }
    }
    # Prefetch gatherosstate (chi la dinh huong)
    $pf = "$env:SystemRoot\Prefetch"
    if (Test-Path $pf) {
        $g = Get-ChildItem -Path $pf -Filter 'GATHEROSSTATE.EXE-*.pf' -Force -ErrorAction SilentlyContinue
        if ($g) {
            New-Finding -Target Windows -Method 'HWID / Digital License' -Confidence D3 -Category Behavioral `
                -Signal 'Prefetch của gatherosstate.exe' -Location "$pf" `
                -Meaning 'gatherosstate.exe không có sẵn trên ổ C; nó chỉ chạy khi ai đó mang từ ISO vào (nâng cấp) hoặc chạy công cụ HWID. Cần đối chiếu với lịch sử nâng cấp.' `
                -Evidence ($g | Select-Object -First 1).Name -Data @{}
        }
    }
}

# --- 7. Lam dung rearm --------------------------------------------------------
function Invoke-Detect-Rearm {
    $ar = "$env:SystemRoot\AutoRearm"
    if (Test-Path -LiteralPath $ar) {
        New-Finding -Target Windows -Method 'Lạm dụng Rearm' -Confidence D1 -Category Artifact `
            -Signal 'Thư mục AutoRearm' -Location $ar `
            -Meaning 'Công cụ tự động rearm để kéo dài thời gian ân hạn vô hạn.' `
            -Evidence $ar -Data @{ Path=$ar }
    }
}

# --- 8. Tac vu dinh ky (phan biet SPP he thong voi tac vu crack) --------------
function Invoke-Detect-ScheduledTasks {
    $tasks = @()
    try { $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue } catch {}
    $crackFolderPat = '(?i)AutoKMS|AutoPico|AutoRearm|KMSpico|KMSAuto|KMS_VL_ALL|Activation-Renewal|vlmcsd|Re-Loader'
    foreach ($t in $tasks) {
        $path = "$($t.TaskPath)"
        $name = "$($t.TaskName)"
        # LOAI TRU tac vu SPP hop le cua he thong (SvcRestartTask...) nam trong \Microsoft\Windows\SoftwareProtectionPlatform\
        if ($path -match '(?i)\\Microsoft\\Windows\\') {
            # Chi xet neu action tro toi thu muc crack (tac vu he thong bi crack chiem dung - hiem)
        }
        $isSystemPath = $path -match '(?i)^\\Microsoft\\'
        $nameMatch = $name -match $crackFolderPat
        # Kiem tra action co tro toi thu muc/tep crack khong
        $actionMatch = $false; $actionDetail = ''
        try {
            foreach ($a in $t.Actions) {
                $exec = "$($a.Execute) $($a.Arguments)"
                if ($exec -match $crackFolderPat -or $exec -match '(?i)Activation-Renewal|AutoKMS|KMSpico|KMSAuto') {
                    $actionMatch = $true; $actionDetail = $exec.Trim()
                }
            }
        } catch {}

        # Ket luan: tac vu crack neu (ten khop VA khong phai duong dan he thong) HOAC (action tro toi thu muc crack)
        if (($nameMatch -and -not $isSystemPath) -or $actionMatch) {
            New-Finding -Target Windows -Method 'Tác vụ định kỳ crack' -Confidence D2 -Category Artifact `
                -Signal "Tác vụ: $path$name" -Location "Task Scheduler: $path$name" `
                -Meaning 'Tác vụ định kỳ để tự động kích hoạt lại/gia hạn. Đã loại trừ tác vụ SPP hợp lệ của Windows.' `
                -Evidence $(if($actionDetail){"$name -> $actionDetail"}else{$name}) `
                -Data @{ TaskPath=$path; TaskName=$name }
        }
    }
}

# --- 9. Microsoft Defender (lich su phat hien + ngoai le) ---------------------
function Invoke-Detect-Defender {
    $threatPat = '(?i)AutoKMS|KMS_?Auto|KMSpico|Keygen|HackTool.*KMS|Kms(pico|auto)'
    try {
        $dets = Get-MpThreatDetection -ErrorAction SilentlyContinue
        $threats = Get-MpThreat -ErrorAction SilentlyContinue
        $names = @()
        foreach ($th in $threats) { if ($th.ThreatName -match $threatPat) { $names += $th.ThreatName } }
        foreach ($d in $dets) {
            $tn = ($threats | Where-Object { $_.ThreatID -eq $d.ThreatID }).ThreatName
            if ($tn -match $threatPat) {
                New-Finding -Target Windows -Method 'Lịch sử Defender' -Confidence D2 -Category Behavioral `
                    -Signal "Defender từng phát hiện: $tn" -Location "Windows Defender ($($d.InitialDetectionTime))" `
                    -Meaning 'Defender đã từng phát hiện công cụ kích hoạt trái phép trên máy này.' `
                    -Evidence "$tn @ $($d.InitialDetectionTime)" -Data @{}
            }
        }
        if (-not $dets -and $names.Count -gt 0) {
            New-Finding -Target Windows -Method 'Lịch sử Defender' -Confidence D2 -Category Behavioral `
                -Signal "Defender ghi nhận: $($names -join ', ')" -Location 'Windows Defender' `
                -Meaning 'Defender đã từng phát hiện công cụ kích hoạt trái phép.' -Evidence ($names -join ', ') -Data @{}
        }
    } catch {}
    # Ngoại lệ Defender tro toi thu muc/tien trinh crack
    try {
        $pref = Get-MpPreference -ErrorAction SilentlyContinue
        foreach ($e in @($pref.ExclusionPath)) {
            if ($e -match '(?i)KMS|AutoPico|AAct|Activation|massgrave|HWID') {
                New-Finding -Target Windows -Method 'Ngoại lệ Defender' -Confidence D2 -Category ActiveConfig `
                    -Signal "Ngoại lệ Defender nghi van: $e" -Location 'Get-MpPreference -> ExclusionPath' `
                    -Meaning 'Ngoại lệ được thêm để che giấu công cụ kích hoạt khỏi Defender - hành vi điển hình của crack.' `
                    -Evidence $e -Data @{ ExclusionPath=$e }
            }
        }
        foreach ($e in @($pref.ExclusionProcess)) {
            if ($e -match '(?i)KMS|AutoPico|AAct|vlmcsd|massgrave') {
                New-Finding -Target Windows -Method 'Ngoại lệ Defender' -Confidence D2 -Category ActiveConfig `
                    -Signal "Ngoại lệ tiến trình nghi vấn: $e" -Location 'Get-MpPreference -> ExclusionProcess' `
                    -Meaning 'Ngoại lệ tiến trình để che giấu công cụ kích hoạt.' -Evidence $e -Data @{ ExclusionProcess=$e }
            }
        }
    } catch {}
}

# --- 10. Lich su PowerShell (phan biet LENH CRACK voi lenh tim kiem) ----------
# Tra ve: cac tep va cac dong khop mau crack (de bao cao va de xoa chon loc)
function Test-IsSelfInvocationLine {
    # Nhan dien dong lenh dung de GOI CHINH CONG CU NAY (vd: "irm https://license.info.vn | iex").
    # Nguoi dung go dong nay de KHOI CHAY cong cu kiem tra ban quyen - khong phai lenh crack -
    # nen phai loai khoi ket qua phat hien/xoa "lich su lenh crack" ben duoi, tranh tu bao dong gia.
    param([string]$Line)
    if ([string]::IsNullOrWhiteSpace($Line)) { return $false }
    foreach ($n in $Script:SELF_NAMES) {
        if ($Line -match [regex]::Escape($n)) { return $true }
    }
    return $false
}

function Get-CrackHistoryHits {
    # Mau ten mien/tu khoa crack (khong the nham lan): get.activated.win, massgrave...
    $reDomain = '(?i)(get\.activated\.win|activated\.win|massgrave(l)?|\bmas[_-]?aio\b|kms38_activation|\bohook\b|\btsforge\b)'
    # Mau tai-ve-roi-thuc-thi
    $rePipe   = '(?i)\b(irm|iwr|invoke-restmethod|invoke-webrequest|curl|wget)\b.{0,200}\|\s*(iex|invoke-expression|\.\s*\(|&)\b'
    # Tu khoa kich hoat de phan biet pipe crack voi pipe cai dat phan mem thong thuong
    $reActWord= '(?i)(activ|kms|hwid|ohook|tsforge|slmgr\s*/(ipk|skms|ato).*?(127\.0\.0|10\.0\.0\.10))'

    $hits = @()
    $profiles = @()
    try {
        $profiles = Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Join-Path $_.FullName 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'
        }
    } catch {}
    foreach ($hp in $profiles) {
        if (-not (Test-Path -LiteralPath $hp)) { continue }
        $lines = @()
        try { $lines = Get-Content -LiteralPath $hp -Force -ErrorAction SilentlyContinue } catch {}
        $matched = @()
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $ln = $lines[$i]
            if (Test-IsSelfInvocationLine -Line $ln) { continue }   # dong goi chinh cong cu nay -> bo qua
            $isCrack = $false
            if ($ln -match $reDomain) { $isCrack = $true }                       # chac chan crack
            elseif (($ln -match $rePipe) -and ($ln -match $reActWord)) { $isCrack = $true }  # pipe + tu khoa kich hoat
            if ($isCrack) { $matched += [PSCustomObject]@{ Index=$i; Line=$ln } }
        }
        if ($matched.Count -gt 0) {
            $hits += [PSCustomObject]@{ File=$hp; Matches=$matched; Total=$lines.Count }
        }
    }
    return $hits
}

function Invoke-Detect-PSHistory {
    $hits = Get-CrackHistoryHits
    foreach ($h in $hits) {
        $sample = ($h.Matches | Select-Object -First 2 | ForEach-Object { $_.Line.Trim() }) -join '  |  '
        New-Finding -Target Windows -Method 'Lịch sử lệnh crack' -Confidence D3 -Category Behavioral `
            -Signal "$($h.Matches.Count) dòng lệnh gọi crack trong lịch sử PowerShell" -Location $h.File `
            -Meaning 'Lịch sử ghi nhận lệnh tải/chạy công cụ kích hoạt (vd irm get.activated.win | iex). Đã phân biệt với lệnh tìm kiếm thông thường và đã loại trừ dòng lệnh gọi chính công cụ WinLicCheck này. Đây là dấu vết, không phải cơ chế đang hoạt động.' `
            -Evidence $sample -Data @{ File=$h.File }
    }
}

# --- 11. Tep hosts (chan may chu kich hoat cua Microsoft) --------------------
function Invoke-Detect-Hosts {
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (-not (Test-Path -LiteralPath $hostsPath)) { return }
    $actDomains = '(?i)(sls\.microsoft\.com|activation\.sls|licensing\.mp\.microsoft|displaycatalog\.mp\.microsoft|purchase\.mp\.microsoft|licensing\.microsoft\.com|validation\.sls)'
    $lines = @()
    try { $lines = Get-Content -LiteralPath $hostsPath -Force -ErrorAction SilentlyContinue } catch {}
    $bad = @()
    foreach ($ln in $lines) {
        $t = $ln.Trim()
        if ($t.StartsWith('#') -or [string]::IsNullOrWhiteSpace($t)) { continue }
        if ($t -match $actDomains -and $t -match '^\s*(0\.0\.0\.0|127\.|::1)') { $bad += $t }
    }
    if ($bad.Count -gt 0) {
        New-Finding -Target Windows -Method 'Can thiệp tệp hosts' -Confidence D3 -Category ActiveConfig `
            -Signal "$($bad.Count) dòng chặn máy chủ kích hoạt Microsoft" -Location $hostsPath `
            -Meaning 'Tệp hosts trỏ tên miền kích hoạt của Microsoft về loopback để chặn xác thực. (Lưu ý: có thể do phần mềm khác; sẽ chỉ xóa các dòng này, giữ phần còn lại.)' `
            -Evidence ($bad -join ' ; ') -Data @{ Path=$hostsPath; BadLines=$bad }
    }
}

# =============================================================================
#  PHAT HIEN OFFICE
# =============================================================================
$Script:OHOOK_HASHES = @{
    '09865EA5993215965E8F27A74B8A41D15FD0F60F5F404CB7A8B3C7757ACDAB02' = 'Ohook 0.5 (sppc32)'
    '393A1FA26DEB3663854E41F2B687C188A9EACD87B23F17EA09422C4715CB5A9F' = 'Ohook 0.5 (sppc64)'
}

# Tu Version 1910, Microsoft 365 Apps (subscription: M365 Apps for enterprise/business,
# M365 Family/Personal) va ban subscription cua Project/Visio KHONG con dang ky qua
# SPP/OSPP (SoftwareLicensingProduct/OfficeSoftwareProtectionProduct tra ve RONG voi cac
# ban nay) ma dung co che kich hoat rieng goi la "vNext". Neu chi doc SPP/OSPP nhu truoc
# day, cong cu se bao "khong cai Office" ngay ca khi may dang cai M365 co ban quyen.
# Nguon xac nhan: hoc.microsoft.com (Microsoft Learn) -
#   "Check the license and activation status for Microsoft 365 Apps" (vnextdiag):
#   - HKCU\Software\Microsoft\Office\16.0\Common\Licensing\LicensingNext
#     (moi gia tri = 1 san pham; gia tri du lieu = 2 nghia la dang dung kich hoat kieu moi)
#   - %LOCALAPPDATA%\Microsoft\Office\Licenses\<id>\ chua 1 tep giay phep cho MOI san pham
#     da kich hoat thanh cong bang co che moi
# Doc ca HKCU cua phien hien tai lan cac ho so nguoi dung khac dang tai (HKEY_USERS) va
# thu muc Licenses cua moi ho so tren may - vi cong cu tu nang quyen Administrator nen co
# the dang chay o mot tai khoan khac voi tai khoan da dang nhap Office.
function Get-OfficeVNextLicenses {
    $result = New-Object System.Collections.Generic.List[object]

    $sids = @('HKCU:')
    try { $sids += (Get-ChildItem 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-1-5-21' } | ForEach-Object { "Registry::$($_.Name)" }) } catch {}
    foreach ($s in $sids) {
        $rk = Join-Path $s 'Software\Microsoft\Office\16.0\Common\Licensing\LicensingNext'
        $item = Get-Item -Path $rk -ErrorAction SilentlyContinue
        if (-not $item) { continue }
        foreach ($name in @($item.Property)) {
            $val = $null
            try { $val = $item.GetValue($name) } catch {}
            $result.Add([PSCustomObject]@{ Source = 'LicensingNext'; Hive = $s; LicenseId = $name; Value = $val })
        }
    }

    $licenseDirs = @()
    if ($env:LOCALAPPDATA) { $licenseDirs += (Join-Path $env:LOCALAPPDATA 'Microsoft\Office\Licenses') }
    try {
        Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $licenseDirs += (Join-Path $_.FullName 'AppData\Local\Microsoft\Office\Licenses')
        }
    } catch {}
    foreach ($dir in ($licenseDirs | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        $files = Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $result.Add([PSCustomObject]@{ Source = 'LicensesFolder'; Hive = $null; LicenseId = $f.BaseName; Value = $f.FullName })
        }
    }
    return @($result)
}

function Get-OfficeInventory {
    $inv = @()
    $c2r = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue
    if ($c2r -and $c2r.InstallationPath) {
        $inv += [PSCustomObject]@{ Type='C2R'; Root=$c2r.InstallationPath; Version=$c2r.VersionToReport
            Platform=$c2r.Platform; ProductIds=$c2r.ProductReleaseIds }
    }
    foreach ($v in '14.0','15.0','16.0') {
        foreach ($hive in 'HKLM:\SOFTWARE\Microsoft\Office','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office') {
            $ir = (Get-ItemProperty (Join-Path $hive "$v\Common\InstallRoot") -Name Path -ErrorAction SilentlyContinue).Path
            if ($ir -and (Test-Path $ir)) { $inv += [PSCustomObject]@{ Type='MSI'; Root=$ir; Version=$v; Platform=$null; ProductIds=$null } }
        }
    }
    return $inv
}

function Invoke-Detect-Ohook {
    # Tap hop cac thu muc VFS + Office MSI + Microsoft Shared
    $vfsDirs = @()
    foreach ($base in @("$env:ProgramFiles\Microsoft Office","${env:ProgramFiles(x86)}\Microsoft Office",
                        "$env:ProgramFiles\Microsoft Office 15","${env:ProgramFiles(x86)}\Microsoft Office 15")) {
        $vfsDirs += (Join-Path $base 'root\vfs\System')
        $vfsDirs += (Join-Path $base 'root\vfs\SystemX86')
    }
    foreach ($pf in @("$env:ProgramFiles","${env:ProgramFiles(x86)}")) {
        foreach ($o in '14','15','16') { $vfsDirs += (Join-Path $pf "Microsoft Office\Office$o") }
    }
    foreach ($d in ($vfsDirs | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $d)) { continue }
        $dlls = Get-ChildItem -LiteralPath $d -Filter 'sppc*.dll' -Force -ErrorAction SilentlyContinue
        foreach ($dll in $dlls) {
            $hash = (Get-FileHash -LiteralPath $dll.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
            $sig  = Get-AuthenticodeSignature -FilePath $dll.FullName -ErrorAction SilentlyContinue
            $known = if ($hash -and $Script:OHOOK_HASHES.ContainsKey($hash)) { $Script:OHOOK_HASHES[$hash] } else { $null }
            $meaning = 'Tệp sppc.dll tự viết đặt trong thư mục VFS của Office - hook luôn trả về "đã kích hoạt". Microsoft không đặt tệp này ở đây.'
            if ($known) { $meaning += " (Khop chinh xac $known)" }
            New-Finding -Target Office -Method 'Ohook' -Confidence D1 -Category ActiveConfig `
                -Signal "DLL hook Office: $($dll.Name)" -Location $dll.FullName `
                -Meaning $meaning -Evidence "$($dll.Name) | SHA256=$(if($hash){$hash.Substring(0,16)+'...'}) | Sig=$(if($sig){$sig.Status})" `
                -Data @{ Path=$dll.FullName; Kind='OhookDll' }
        }
    }
    # Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPC.DLL (<100KB) + sppcs.dll
    foreach ($cpf in @("$env:CommonProgramFiles","${env:CommonProgramFiles(x86)}")) {
        if (-not $cpf) { continue }
        $shared = Join-Path $cpf 'Microsoft Shared\OfficeSoftwareProtectionPlatform'
        $osppc = Join-Path $shared 'OSPPC.DLL'
        $sppcs = Join-Path $shared 'sppcs.dll'
        if (Test-Path -LiteralPath $sppcs) {
            New-Finding -Target Office -Method 'Ohook' -Confidence D1 -Category ActiveConfig `
                -Signal 'Tồn tại sppcs.dll trong Microsoft Shared' -Location $sppcs `
                -Meaning 'ohook đổi tên OSPPC.DLL gốc thành sppcs.dll và thay bằng DLL hook. Sự tồn tại của sppcs.dll = có hook.' `
                -Evidence $sppcs -Data @{ Path=$sppcs; Kind='OhookShared' }
        }
        if (Test-Path -LiteralPath $osppc) {
            $sz = (Get-Item -LiteralPath $osppc -Force).Length
            if ($sz -lt 100000) {
                New-Finding -Target Office -Method 'Ohook' -Confidence D1 -Category ActiveConfig `
                    -Signal "OSPPC.DLL kích thước bất thường ($sz byte < 100KB)" -Location $osppc `
                    -Meaning 'Bản OSPPC.DLL gốc luôn >= 100KB. Tệp nhỏ là DLL hook thay thế.' `
                    -Evidence "$osppc ($sz byte)" -Data @{ Path=$osppc; Kind='OhookSharedHook' }
            }
        }
    }
    # Resiliency: TimeOfLastHeartbeatFailure tuong lai xa (chan banner M365)
    $sids = @('HKCU:')
    try { $sids += (Get-ChildItem 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-1-5-21' } | ForEach-Object { "Registry::$($_.Name)" }) } catch {}
    foreach ($s in $sids) {
        $rk = Join-Path $s 'Software\Microsoft\Office\16.0\Common\Licensing\Resiliency'
        $val = (Get-ItemProperty -Path $rk -Name 'TimeOfLastHeartbeatFailure' -ErrorAction SilentlyContinue).TimeOfLastHeartbeatFailure
        if ($val -and $val -match '20[3-9]\d|2[1-9]\d\d') {
            New-Finding -Target Office -Method 'Ohook' -Confidence D2 -Category ActiveConfig `
                -Signal "TimeOfLastHeartbeatFailure đặt tương lai xa: $val" -Location "$rk" `
                -Meaning 'ohook đặt giá trị này ở tương lai xa để chặn banner "There was a problem checking this device license status" của Microsoft 365.' `
                -Evidence $val -Data @{ RegKey=$rk; RegVal='TimeOfLastHeartbeatFailure' }
        }
    }
}

function Invoke-Detect-OfficeKms {
    # OSPP registry (Office 2010, va Office 2013 MSI tren Win7)
    foreach ($k in 'HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform','HKLM:\SOFTWARE\WOW6432Node\Microsoft\OfficeSoftwareProtectionPlatform') {
        $kms = (Get-ItemProperty -Path $k -Name 'KeyManagementServiceName' -ErrorAction SilentlyContinue).KeyManagementServiceName
        if ($kms) {
            $cls = Get-KmsHostClass $kms
            if ($cls -in @('LOCAL_EMULATOR','MAS_ONLINE_PLACEHOLDER','MAS_TSFORGE_LOCK','PUBLIC_HOST','PUBLIC_HOST_UNRESOLVED')) {
                New-Finding -Target Office -Method 'KMS Office (OSPP)' -Confidence D1 -Category ActiveConfig `
                    -Signal "Máy chủ KMS Office bất hợp pháp: $kms" -Location "$k -> KeyManagementServiceName" `
                    -Meaning 'Office 2010/2013 trỏ tới máy chủ KMS lậu (loopback/công cộng/10.0.0.10).' `
                    -Evidence "$kms ($cls)" -Data @{ RegKey=$k; RegVal='KeyManagementServiceName' }
            }
        }
    }
    # Office 2010 OSPP products bat thuong
    $o14 = Get-Office14Products
    foreach ($p in $o14) {
        if ($p.KeyManagementServiceMachine) {
            $cls = Get-KmsHostClass $p.KeyManagementServiceMachine
            if ($cls -in @('LOCAL_EMULATOR','MAS_ONLINE_PLACEHOLDER','MAS_TSFORGE_LOCK','PUBLIC_HOST')) {
                New-Finding -Target Office -Method 'KMS Office (OSPP)' -Confidence D1 -Category ActiveConfig `
                    -Signal "Office 2010 trỏ KMS bất hợp pháp: $($p.KeyManagementServiceMachine)" -Location 'WMI OfficeSoftwareProtectionProduct' `
                    -Meaning 'Office 2010 kích hoạt qua KMS lậu.' -Evidence $p.KeyManagementServiceMachine -Data @{}
            }
        }
    }
}

function Invoke-Detect-OfficeRetailToVolume {
    $inv = Get-OfficeInventory
    foreach ($o in ($inv | Where-Object { $_.Type -eq 'C2R' -and $_.ProductIds })) {
        if ($o.ProductIds -match '(?i)Mondo.*Volume') {
            New-Finding -Target Office -Method 'Chuyển Retail->Volume' -Confidence D2 -Category ActiveConfig `
                -Signal 'ProductReleaseIds chứa Mondo...Volume' -Location "HKLM\...\ClickToRun\Configuration -> ProductReleaseIds" `
                -Meaning 'Microsoft không bán SKU Mondo cho khách hàng cuối. Mondo hầu như luôn là kết quả chuyển đổi từ Microsoft 365 để kích hoạt KMS.' `
                -Evidence $o.ProductIds -Data @{}
        } elseif ($o.ProductIds -match '(?i)Volume') {
            New-Finding -Target Office -Method 'Chuyển Retail->Volume' -Confidence D3 -Category LicenseAnomaly `
                -Signal 'ProductReleaseIds chứa *Volume' -Location "HKLM\...\ClickToRun\Configuration -> ProductReleaseIds" `
                -Meaning 'Sản phẩm Office đang ở dạng Volume. Hợp lệ NẾU đơn vị có thỏa thuận VL; cần đối chiếu chứng từ. Nếu đơn vị mua bản Retail/Home -> dấu hiệu bị chuyển đổi.' `
                -Evidence $o.ProductIds -Data @{}
        }
    }
}

# --- 12. Dau thoi gian kho SPP (data.dat/tokens.dat) - DO TIN CAY THAP --------
# Doc LastWriteTime cua tep AN + HE THONG bang -Force. TSforge sua truc tiep kho nay.
function Invoke-Detect-SppTimestamp {
    $store = "$env:SystemRoot\System32\spp\store\2.0"
    if (-not (Test-Path -LiteralPath $store)) { $store = "$env:SystemRoot\System32\spp\store" }
    foreach ($rel in 'data.dat','tokens.dat') {
        $p = Join-Path $store $rel
        if (-not (Test-Path -LiteralPath $p)) { continue }
        $mod = (Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue).LastWriteTime
        if (-not $mod) { continue }

        # Ngay cai Windows (registry InstallDate = unix epoch)
        $installDate = $null
        try {
            $u = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name InstallDate -ErrorAction Stop).InstallDate
            $installDate = (Get-Date '1970-01-01').AddSeconds([double]$u).ToLocalTime()
        } catch {}

        # Co su kien Windows Update gan moc thoi gian sua tep khong? (Neu co -> hop le)
        $nearWU = $false
        try {
            $evs = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WindowsUpdateClient'} -MaxEvents 200 -ErrorAction SilentlyContinue |
                   Where-Object { [math]::Abs(($_.TimeCreated - $mod).TotalHours) -lt 48 }
            $nearWU = ($evs -and @($evs).Count -gt 0)
        } catch {}

        if (-not $nearWU -and $installDate -and $mod -gt $installDate.AddDays(2)) {
            New-Finding -Target Windows -Method 'Kho SPP bị sửa (độ tin cậy thấp)' -Confidence D3 -Category Behavioral `
                -Signal "$rel có LastWriteTime mới hơn ngày cài đặt và không gần sự kiện Windows Update" `
                -Location $p `
                -Meaning 'TSforge sửa trực tiếp kho SPP. Dấu thời gian bất thường là dấu hiệu ĐỘ TIN CẬY THẤP (Windows Update/khắc phục sự cố hợp lệ cũng có thể sửa tệp này). Chỉ mang tính định hướng.' `
                -Evidence "LastWrite=$($mod.ToString('yyyy-MM-dd HH:mm')) / Install=$(if($installDate){$installDate.ToString('yyyy-MM-dd')}else{'?'})" `
                -Data @{}
        }
    }
}

# =============================================================================
#  DIEU PHOI QUET & TRANG THAI
# =============================================================================
$Script:WinInfo   = $null
$Script:Bios      = $null
$Script:WinProds  = @()
$Script:OffProds  = @()
$Script:Off14     = @()
$Script:OffVNext  = @()
$Script:OfficeRegKeys = @()   # cache ket qua Get-OfficeRegistryProductKeys - xem Invoke-FullScan
$Script:ForceRescanNow = $false   # bao hieu can quet lai NGAY (vd sau dang nhap lay Digital License)

function Invoke-FullScan {
    $Script:Findings.Clear()

    Start-Checklist -Title 'RÀ QUÉT TOÀN HỆ THỐNG' -Steps @(
        'Thu thập thông tin hệ điều hành & key BIOS/OEM',
        'Truy vấn trạng thái cấp phép Windows (WMI/SPP)',
        'Truy vấn trạng thái cấp phép Office (SPP + OSPP 2010)',
        'Windows: máy chủ KMS được cấu hình',
        'Windows: cổng 1688 & tiến trình giả lập KMS cục bộ',
        'Windows: hiện vật công cụ crack trên đĩa (KMSpico/KMSAuto/MAS...)',
        'Windows: toàn vẹn tệp nhị phân SPP (chữ ký số)',
        'Windows: dấu hiệu TSforge (ZeroCID/KMS4k/StaticCID)',
        'Windows: giấy phép số HWID / GenuineTicket',
        'Windows: lạm dụng rearm (đặt lại bộ đếm hạn dùng)',
        'Windows: tác vụ theo lịch bất thường (loại trừ tác vụ SPP hệ thống)',
        'Windows: ngoại lệ Microsoft Defender & lịch sử phát hiện',
        'Windows: lịch sử lệnh PowerShell gọi công cụ crack',
        'Windows: tệp hosts chặn máy chủ kích hoạt Microsoft',
        'Windows: dấu thời gian kho giấy phép SPP (tệp ẩn/hệ thống)',
        'Office: móc nối Ohook (sppc.dll / OSPPC.DLL)',
        'Office: máy chủ KMS của Office',
        'Office: chuyển đổi Retail sang Volume',
        'Office: dấu hiệu TSforge trên sản phẩm Office'
    )

    # --- 1-3: Thu thap du lieu nen -------------------------------------------
    $it = Start-Step -Note 'Đọc registry CurrentVersion, WMI Win32_OperatingSystem, bảng MSDM trong BIOS'
    try {
        $Script:WinInfo = Get-WindowsInfo
        $Script:Bios    = Get-BiosOemKey
        Add-StepDetail ("Hệ điều hành: {0} (build {1}, {2})" -f $Script:WinInfo.ProductName, $Script:WinInfo.Build, $Script:WinInfo.Arch)
        if ($Script:Bios -and $Script:Bios.Key) {
            Add-StepDetail ("Có key OEM nhúng trong BIOS/MSDM: {0}" -f (Mask-Key $Script:Bios.Key)) 'Green'
            Complete-Step -Status DAT -Note 'Đã đọc được key OEM từ BIOS'
        } else {
            Add-StepDetail 'Không có key OEM nhúng trong BIOS (máy tự lắp/nâng cấp hoặc firmware không có bảng MSDM)'
            Complete-Step -Status DAT -Note 'Không có key BIOS (bình thường với nhiều dòng máy)'
        }
    } catch { Complete-Step -Status LOI -Note 'Không đọc được thông tin hệ thống' }

    $it = Start-Step -Note 'Lớp SoftwareLicensingProduct, lọc theo ApplicationID của Windows'
    try {
        $Script:WinProds = Get-LicenseProducts $Script:WINDOWS_APPID
        $n = @($Script:WinProds).Count
        if ($n -eq 0) {
            Add-StepDetail 'Không tìm thấy sản phẩm Windows nào có khóa cài đặt' 'Yellow'
            Complete-Step -Status LUUY -Note 'Không đọc được sản phẩm Windows (SPP có thể bị hỏng)'
        } else {
            foreach ($p in $Script:WinProds) {
                $st = switch ([int]$p.LicenseStatus) { 1 {'Đã kích hoạt'} 2 {'Hết hạn dùng thử'} 3 {'Hạn gia hạn'} 5 {'Chưa cấp phép'} 6 {'Kích hoạt bổ sung'} default {"Trạng thái $($p.LicenseStatus)"} }
                Add-StepDetail ("{0} | kênh {1} | {2}" -f $p.Name, $p.ProductKeyChannel, $st)
            }
            Complete-Step -Status DAT -Note "$n sản phẩm Windows"
        }
    } catch { Complete-Step -Status LOI -Note 'Truy vấn WMI thất bại' }

    $it = Start-Step -Note 'SoftwareLicensingProduct (Office 2013+), OfficeSoftwareProtectionProduct (Office 2010) và LicensingNext (Microsoft 365 Apps - kích hoạt kiểu vNext từ version 1910)'
    # Truy van tung nguon RIENG (khong dung 1 try/catch bao trum ca khoi) de 1 nguon loi khong
    # chan cac nguon con lai - vd SPP/OSPP co dien loi van khong ngan doc duoc LicensingNext.
    $classicOk = $true
    try { $Script:OffProds = Get-LicenseProducts $Script:OFFICE_APPID } catch { $Script:OffProds = @(); $classicOk = $false }
    try { $Script:Off14    = Get-Office14Products } catch { $Script:Off14 = @(); $classicOk = $false }
    try { $Script:OffVNext = Get-OfficeVNextLicenses } catch { $Script:OffVNext = @() }
    # Quet + giai ma DigitalProductId cua Office/Visio/Project MOT LAN duy nhat o day va
    # luu vao cache - KHONG duoc goi lai Get-OfficeRegistryProductKeys() moi lan hien bao
    # cao (truoc day goi 2 lan/lan xem trang chi tiet, cong voi pham vi quet qua rong, la
    # nguyen nhan gay "dung yen" sau khi in tieu de trang chi tiet Office - xem bao loi).
    try { $Script:OfficeRegKeys = @(Get-OfficeRegistryProductKeys) } catch { $Script:OfficeRegKeys = @() }

    $nClassic  = @($Script:OffProds).Count + @($Script:Off14).Count
    $nVNext    = @($Script:OffVNext | Select-Object -ExpandProperty LicenseId -Unique).Count
    $n         = $nClassic + $nVNext
    $installed = @(Get-OfficeInventory).Count -gt 0

    if (-not $classicOk) {
        # Khong doc duoc SPP/OSPP CO DIEN (Office 2013+ / Office 2010) - day la LUU Y, KHONG
        # phai LOI: co the do Office dung co che vNext cua Microsoft 365 (khong dang ky qua
        # SPP/OSPP), hoac dich vu SPP tam thoi khong phan hoi - khong dong nghia Office co van de.
        Add-StepDetail 'Không đọc được thông tin cấp phép qua SPP/OSPP 2010 cổ điển' 'Yellow'
        if ($nVNext -gt 0) { Add-StepDetail ("Đã đọc được $nVNext mục trong LicensingNext/Licenses (dấu hiệu Microsoft 365 kiểu vNext)") 'Green' }
        elseif ($installed) { Add-StepDetail 'Office có cài trên máy nhưng không đọc được cả SPP/OSPP cổ điển lẫn LicensingNext - xem trang chi tiết Office' 'Yellow' }
        Complete-Step -Status LUUY -Note 'Không đọc được SPP/OSPP 2010 cổ điển - xem chi tiết Office để biết thêm'
    }
    elseif ($n -eq 0 -and $installed) {
        # Office CO cai tren may (Get-OfficeInventory thay duoc) nhung khong doc duoc thong
        # tin cap phep qua ca SPP/OSPP co dien lan LicensingNext - LUU Y can xem chi tiet,
        # KHONG duoc ket luan la "may khong cai Office" (BO QUA) vi thuc te co cai.
        Add-StepDetail 'Phát hiện Office đã cài trên máy nhưng không đọc được thông tin cấp phép qua SPP/OSPP cổ điển lẫn LicensingNext (Microsoft 365)' 'Yellow'
        Complete-Step -Status LUUY -Note 'Có Office nhưng không đọc được trạng thái cấp phép - xem trang chi tiết Office'
    }
    elseif ($n -eq 0) {
        Add-StepDetail 'Không phát hiện sản phẩm Office nào được cấp phép trên máy (đã kiểm tra cả SPP/OSPP cổ điển lẫn LicensingNext của Microsoft 365)'
        Complete-Step -Status BOQUA -Note 'Máy không cài Office (hoặc Office chưa đăng ký cấp phép)'
    } else {
        foreach ($p in @($Script:OffProds) + @($Script:Off14)) {
            Add-StepDetail ("{0} | kênh {1} | trạng thái {2}" -f $p.Name, $p.ProductKeyChannel, $p.LicenseStatus)
        }
        if ($nVNext -gt 0) { Add-StepDetail ("Microsoft 365 (kích hoạt kiểu vNext): $nVNext mục trong LicensingNext/Licenses") }
        Complete-Step -Status DAT -Note "$n sản phẩm Office"
    }

    # --- 4-15: Cac module phat hien Windows -----------------------------------
    Invoke-Step -Note 'So khớp KeyManagementServiceMachine với 10.0.0.10 (MAS), 127.0.0.2 (TSforge), IP nội bộ và máy chủ công cộng' `
        -Action { Invoke-Detect-WindowsKms -WinProducts $Script:WinProds }

    Invoke-Step -Note 'Get-NetTCPConnection/netstat trên cổng 1688; đối chiếu chữ ký số tiến trình lắng nghe' `
        -Action { Invoke-Detect-KmsPort }

    Invoke-Step -Note 'Quét thư mục ProgramData/Program Files/Windows theo danh mục hiện vật đã biết' `
        -Action { Invoke-Detect-ToolArtifacts }

    Invoke-Step -Note 'Get-AuthenticodeSignature trên sppsvc.exe, sppc.dll, slc.dll, sppcext.dll' `
        -Action { Invoke-Detect-BinaryPatch }

    Invoke-Step -Note 'Kiểm tra khóa SPP theo từng sản phẩm, chu kỳ GVLK bất thường, cấu hình vĩnh viễn trái quy luật' `
        -Action { Invoke-Detect-TSforge -Products $Script:WinProds -Target 'Windows' }

    Invoke-Step -Note 'Kiểm tra GenuineTicket.xml, ClipSVC và tính nhất quán của giấy phép số' `
        -Action { Invoke-Detect-HWID }

    Invoke-Step -Note 'So sánh số lần rearm còn lại với giá trị mặc định của phiên bản' `
        -Action { Invoke-Detect-Rearm }

    Invoke-Step -Note 'Duyệt Task Scheduler, bỏ qua nhánh \Microsoft\ của hệ thống, tìm tác vụ tự gia hạn kích hoạt' `
        -Action { Invoke-Detect-ScheduledTasks }

    Invoke-Step -Note 'Get-MpPreference (đường dẫn loại trừ) và Get-MpThreatDetection (lịch sử phát hiện HackTool)' `
        -Action { Invoke-Detect-Defender }

    Invoke-Step -Note 'Đọc ConsoleHost_history.txt của mọi hồ sơ; phân biệt lệnh gọi crack với lệnh tìm kiếm; loại trừ lệnh gọi chính công cụ này' `
        -Action { Invoke-Detect-PSHistory }

    Invoke-Step -Note 'Đọc tệp hosts (kèm thuộc tính ẩn/hệ thống), tìm dòng trỏ tên miền kích hoạt về loopback' `
        -Action { Invoke-Detect-Hosts }

    Invoke-Step -Note 'Get-Item -Force trên data.dat/tokens.dat (tệp ẩn+hệ thống); đối chiếu ngày cài đặt và sự kiện Windows Update' `
        -Action { Invoke-Detect-SppTimestamp }

    # --- 16-19: Cac module phat hien Office -----------------------------------
    # Coi la "co cai Office" neu: co san pham SPP/OSPP cap phep, HOAC co giay phep kieu
    # vNext (Microsoft 365 Apps), HOAC Get-OfficeInventory tim thay ban cai C2R/MSI tren
    # dia (bao gom ca Program Files (x86) - truong hop Office 32-bit tren Windows 64-bit).
    $officeDaCai = (@($Script:OffProds).Count + @($Script:Off14).Count + @($Script:OffVNext).Count -gt 0) -or (@(Get-OfficeInventory).Count -gt 0)
    if (-not $officeDaCai) {
        for ($k = 0; $k -lt 4; $k++) {
            [void](Start-Step -Note 'Bỏ qua vì máy không cài Office')
            Complete-Step -Status BOQUA -Note 'Không áp dụng'
        }
    } else {
        Invoke-Step -Note 'Tìm sppc.dll/sppc32.dll/sppc64.dll trong VFS của Office C2R và OSPPC.DLL trong Microsoft Shared (MSI)' `
            -Action { Invoke-Detect-Ohook }

        Invoke-Step -Note 'Đọc KeyManagementServiceName trong nhánh OSPP/ClickToRun và thuộc tính WMI của sản phẩm Office' `
            -Action { Invoke-Detect-OfficeKms }

        Invoke-Step -Note 'So sánh kênh cấp phép hiện tại với gói cài đặt gốc (dấu hiệu đổi Retail thành Volume)' `
            -Action { Invoke-Detect-OfficeRetailToVolume }

        Invoke-Step -Note 'Áp dụng bộ kiểm tra TSforge cho các sản phẩm Office' `
            -Action { Invoke-Detect-TSforge -Products $Script:OffProds -Target 'Office' }
    }

    $nAll = $Script:Findings.Count
    $nWin = @($Script:Findings | Where-Object { $_.Target -eq 'Windows' }).Count
    $nOff = @($Script:Findings | Where-Object { $_.Target -eq 'Office' }).Count
    Write-Host ''
    if ($nAll -eq 0) {
        Write-Good 'Hoàn tất rà quét: không ghi nhận dấu hiệu can thiệp kỹ thuật nào.'
    } else {
        Write-Warn "Hoàn tất rà quét: ghi nhận $nAll dấu hiệu (Windows: $nWin, Office: $nOff). Xem chi tiết ở menu kết luận."
    }
    # Danh dau du lieu quet la MOI - tranh quet lai thua o menu ket luan
    $Script:ScanFresh = $true
}

# Mot phat hien co phai "co che dang hoat dong bat hop phap" khong (khac voi ton du)
# Dung co Verify (bool) thay vi so khop ten -> bat bien voi dich thuat/dau tieng Viet.
function Test-ActiveIllegit {
    param($f)
    if ($f.Verify) { return $false }   # nhom "can xac minh" -> khong tu ket luan
    if ($f.Category -eq 'ActiveConfig')  { return $true }
    if ($f.Category -eq 'LicenseAnomaly' -and $f.Confidence -in @('D1','D2')) { return $true }
    return $false
}

# Trang thai cap phep hien tai cua mot doi tuong (Windows/Office)
function Get-TargetLicenseState {
    param([ValidateSet('Windows','Office')] [string]$Target)
    $prods = if ($Target -eq 'Windows') { $Script:WinProds } else { $Script:OffProds + $Script:Off14 }
    $active = $prods | Where-Object { $_.LicenseStatus -eq 1 } | Select-Object -First 1
    if (-not $active) { $active = $prods | Select-Object -First 1 }

    # Office kieu vNext (Microsoft 365 Apps tu version 1910): khong dang ky qua SPP/OSPP nen
    # $active se rong -> neu bao "Chua kich hoat" o day la SAI trong khi buoc 3 da phat hien
    # co giay phep vNext. Trong truong hop nay, coi la da kich hoat qua tai khoan Microsoft/M365.
    if ($Target -eq 'Office' -and -not $active -and @($Script:OffVNext).Count -gt 0) {
        return [PSCustomObject]@{
            Target=$Target; Product=$null; Channel='Subscription (Microsoft 365 - vNext)'; Description='LicensingNext / Licenses'
            Status=1; Grace=$null; Permanent=$true; IsVolumeGvlk=$false
            TechLegit=$true; Note='Kích hoạt kiểu vNext qua tài khoản Microsoft/M365 (không dùng KMS/MAK/product key) - đối chiếu với thuê bao M365 hợp lệ của đơn vị'
            PartialKey=$null
        }
    }

    # Khong doc duoc SPP/OSPP co dien (active rong) VA cung khong doc duoc giay phep vNext
    # (LicensingNext/Licenses rong hoac khong truy cap duoc). Neu may co cai Office kieu
    # Click-to-Run (C2R), day rat co the la Microsoft 365 Apps tu ban 1910 tro len dung co
    # che vNext ma cong cu nay KHONG doc duoc - KHONG duoc khang dinh la "Chua cap phep",
    # phai noi ro day la gioi han cua cong cu, khong phai ket luan ve tinh trang cap phep.
    if ($Target -eq 'Office' -and -not $active) {
        $c2r = Get-OfficeInventory | Where-Object { $_.Type -eq 'C2R' } | Select-Object -First 1
        if ($c2r) {
            $pidNote = if ($c2r.ProductIds) { " Gói cài đặt (ProductIds): $($c2r.ProductIds)." } else { '' }
            return [PSCustomObject]@{
                Target=$Target; Product=$null; Channel=$null; Description="Click-to-Run $($c2r.Version)"
                Status=$null; Grace=$null; Permanent=$false; IsVolumeGvlk=$false
                TechLegit=$false
                Note="Có thể đang dùng Microsoft 365/Office (và Visio/Project nếu có trong gói) bản Click-to-Run, có thể từ version 1910 trở lên dùng cơ chế cấp phép vNext - công cụ này KHÔNG đọc được trạng thái cấp phép kiểu vNext.$pidNote"
                PartialKey=$null; VNextUnknown=$true
            }
        }
    }

    $channel = if ($active) { "$($active.ProductKeyChannel)" } else { '' }
    $desc    = if ($active) { "$($active.Description)" } else { '' }
    $status  = if ($active) { [int]$active.LicenseStatus } else { 0 }
    $grace   = if ($active) { $active.GracePeriodRemaining } else { $null }
    $permanent = ($status -eq 1) -and ($grace -eq 0 -or $grace -eq $null)
    $isVolGvlk = ($desc -match 'VOLUME_KMSCLIENT') -or ($channel -match 'Volume')

    # Co che hien tai co hop le (ve ky thuat) khong - tuc khong phai crack dang hoat dong
    $techLegit = $false; $note = ''
    if ($status -ne 1) { $note = 'Chưa kích hoạt' }
    elseif ($channel -match '(?i)OEM') { $techLegit=$true; $note='Kênh OEM (có thể là key BIOS/MSDM)' }
    elseif ($channel -match '(?i)Retail' -and $permanent) { $techLegit=$true; $note='Kênh Retail vĩnh viễn (giấy phép số hoặc key retail - cần giấy tờ chứng minh)' }
    elseif ($channel -match '(?i)MAK') { $techLegit=$true; $note='Kênh MAK (cần giấy tờ chứng minh Volume License)' }
    elseif ($isVolGvlk -and -not $permanent -and $grace -gt 0) { $note='KMS (cần xác minh máy chủ)' }
    elseif ($isVolGvlk -and $permanent) { $note='Volume + vĩnh viễn (BẤT THƯỜNG)' }
    else { $note = $channel }

    # Key day du giai ma tu registry cho san pham "dai dien" (active). Voi Office/
    # Visio/Project, doi chieu 5 ky tu cuoi voi cache $Script:OfficeRegKeys (da quet
    # 1 lan duy nhat trong Invoke-FullScan - KHONG duoc goi lai Get-OfficeRegistryProductKeys()
    # o day, se gay quet registry lap lai moi lan xem bao cao). Neu la MAK, ham
    # Get-*RegistryProductKey/khop se tra ve $null (xem Test-MakPlaceholderKey).
    $regKey = if ($Target -eq 'Windows') {
        Get-WindowsRegistryProductKey
    } elseif ($active -and $active.PartialProductKey) {
        (@($Script:OfficeRegKeys) | Where-Object { $_.Key -and ($_.Key -replace '-','').Substring(20,5) -eq $active.PartialProductKey } | Select-Object -First 1).Key
    } else { $null }

    [PSCustomObject]@{
        Target=$Target; Product=$active; Channel=$channel; Description=$desc
        Status=$status; Grace=$grace; Permanent=$permanent; IsVolumeGvlk=$isVolGvlk
        TechLegit=$techLegit; Note=$note
        PartialKey= if ($active) { $active.PartialProductKey } else { $null }
        RegistryKey=$regKey
    }
}

# Liet ke DAY DU tat ca san pham Windows/Office/Visio/Project doc duoc (khong chi
# 1 "dai dien" nhu Get-TargetLicenseState) - phuc vu yeu cau in ra het khi may co
# nhieu key (nhieu ban Office, Visio, Project cung cai). Voi moi san pham, co gang
# gan key day du tu registry (doi chieu 5 ky tu cuoi); neu la kenh MAK thi khong
# bao gio hien key (that dat bi Microsoft xoa sau kich hoat - xem Test-MakPlaceholderKey).
function Get-AllTargetProductRows {
    param([ValidateSet('Windows','Office')] [string]$Target)

    $prods = if ($Target -eq 'Windows') { @($Script:WinProds) } else { @($Script:OffProds) + @($Script:Off14) }
    $regEntries = if ($Target -eq 'Office') { @($Script:OfficeRegKeys) } else { @() }

    $rows = @()
    foreach ($p in $prods) {
        $isMakChannel = "$($p.ProductKeyChannel)" -match '(?i)MAK'
        $fullKey = $null
        if (-not $isMakChannel -and $p.PartialProductKey) {
            if ($Target -eq 'Windows') {
                $fullKey = Get-WindowsRegistryProductKey
            } else {
                $fullKey = ($regEntries | Where-Object { $_.Key -and ($_.Key -replace '-','').Substring(20,5) -eq $p.PartialProductKey } | Select-Object -First 1).Key
            }
        }
        $note = if ($isMakChannel) { 'Kênh MAK: Microsoft xoá key thật khỏi registry sau khi kích hoạt (thiết kế bảo mật, không phải giới hạn công cụ) - chỉ còn 5 ký tự cuối' }
                elseif ($fullKey) { $null }
                else { 'Không giải mã được key đầy đủ (dữ liệu registry trống/không hợp lệ) - chỉ còn 5 ký tự cuối qua WMI' }

        $rows += [PSCustomObject]@{
            Name=$p.Name; Description="$($p.Description)"; Channel="$($p.ProductKeyChannel)"
            Status=[int]$p.LicenseStatus; PartialKey=$p.PartialProductKey; FullKey=$fullKey; Note=$note
        }
    }
    return $rows
}

# Ket luan tong hop cho mot doi tuong
function Get-TargetVerdict {
    param([ValidateSet('Windows','Office')] [string]$Target)
    $fs = $Script:Findings | Where-Object { $_.Target -eq $Target }
    $state = Get-TargetLicenseState -Target $Target
    $needVerify    = @($fs | Where-Object { $_.Verify })
    $activeIllegit = @($fs | Where-Object { Test-ActiveIllegit $_ })
    # residual = phat hien khong phai active-illegit VA khong phai nhom can-xac-minh
    $residualReal  = @($fs | Where-Object { (-not (Test-ActiveIllegit $_)) -and (-not $_.Verify) })

    # Phan tach theo muc do de ap dung quy tac ket luan than trong (giam duong tinh gia)
    $d1Active = @($activeIllegit | Where-Object { $_.Confidence -eq 'D1' })
    $d2Active = @($activeIllegit | Where-Object { $_.Confidence -eq 'D2' })
    $d3Active = @($activeIllegit | Where-Object { $_.Confidence -eq 'D3' })

    $verdict = 'CLEAN'; $label = 'KHÔNG PHÁT HIỆN CAN THIỆP KỸ THUẬT'
    if ($d1Active.Count -ge 1 -or $d2Active.Count -ge 2) {
        # Chac chan: >=1 dau hieu D1, hoac >=2 dau hieu D2 doc lap
        $verdict = 'VIOLATION'; $label = 'CÓ CAN THIỆP KỸ THUẬT (đang hoạt động)'
    } elseif ($d2Active.Count -eq 1 -or $d3Active.Count -ge 1) {
        # 1 dau hieu D2, hoac co cau hinh D3 dang tac dong (vd sua hosts) -> chua du chac chan -> NGHI VAN
        $verdict = 'SUSPECT'; $label = 'NGHI VẤN - CÓ BẤT THƯỜNG, CẦN ĐỐI CHIẾU CHỨNG TỪ'
    } elseif ($residualReal.Count -gt 0 -and $state.Status -eq 1 -and $state.TechLegit) {
        $verdict = 'RESIDUAL_LEGIT'; $label = 'ĐÃ KÍCH HOẠT - CÒN TỒN DƯ DẤU VẾT CRACK'
    } elseif ($residualReal.Count -gt 0) {
        $verdict = 'RESIDUAL'; $label = 'CÓ DẤU VẾT CRACK (không còn cơ chế hoạt động rõ ràng)'
    } elseif ($needVerify.Count -gt 0) {
        # Chi co cac dau hieu "can xac minh" (vd KMS doanh nghiep) -> NGHI VAN nhe
        $verdict = 'SUSPECT'; $label = 'CẦN XÁC MINH (KMS/cấu hình đặc thù - đối chiếu với CNTT)'
    }
    [PSCustomObject]@{
        Target=$Target; Verdict=$verdict; Label=$label; State=$state
        ActiveIllegit=$activeIllegit; Residual=$residualReal
        AllFindings=$fs; NeedVerify=$needVerify
    }
}

# Nhom phat hien theo phuong thuc (de bao cao "theo tung loai cong cu")
function Get-MethodGroups {
    param($Findings)
    $groups = @{}
    foreach ($f in $Findings) {
        if (-not $groups.ContainsKey($f.Method)) { $groups[$f.Method] = @() }
        $groups[$f.Method] += $f
    }
    $result = @()
    foreach ($m in $groups.Keys) {
        $items = $groups[$m]
        $confs = $items | ForEach-Object { $_.Confidence }
        $top = if ($confs -contains 'D1') {'D1'} elseif ($confs -contains 'D2') {'D2'} elseif ($confs -contains 'D3') {'D3'} else {'D4'}
        $active = @($items | Where-Object { Test-ActiveIllegit $_ }).Count -gt 0
        $result += [PSCustomObject]@{ Method=$m; Top=$top; Count=$items.Count; Items=$items; Active=$active }
    }
    return ($result | Sort-Object @{E={ @('D1','D2','D3','D4').IndexOf($_.Top) }}, Method)
}

# =============================================================================
#  RENDER BAO CAO
# =============================================================================
function Show-TargetReport {
    param([ValidateSet('Windows','Office')] [string]$Target)
    $v = Get-TargetVerdict -Target $Target
    $st = $v.State

    Write-Sub "KẾT QUẢ: $Target"
    $allRows = @(Get-AllTargetProductRows -Target $Target)

    if ($Target -eq 'Windows') {
        Write-KeyVal 'Hệ điều hành' "$($Script:WinInfo.ProductName) [$($Script:WinInfo.DisplayVer)] build $($Script:WinInfo.Build)" 'White'
        Write-KeyVal 'Key OEM trong BIOS' (Mask-Key $Script:Bios.Key) 'Magenta'
        $anyRegKey = $false
        foreach ($row in $allRows) {
            $label = if (@($allRows).Count -gt 1) { "Key: $($row.Name)" } else { 'Key trên máy' }
            if ($row.FullKey) {
                $last5Reg = ($row.FullKey -replace '-', '').Substring(20, 5)
                if ($row.PartialKey -and $last5Reg -ne $row.PartialKey) {
                    Write-KeyVal "$label (registry - CHƯA khớp WMI, cần xác minh lại)" $row.FullKey 'Yellow'
                } else {
                    Write-KeyVal "$label (giải mã đầy đủ từ registry)" $row.FullKey 'Magenta'
                    $anyRegKey = $true
                }
            } else {
                Write-KeyVal "$label ($($row.Note))" (Mask-Key $row.PartialKey) 'Magenta'
            }
        }
        if ($anyRegKey) {
            Write-Plain 'Lưu ý: nếu máy dùng "giấy phép số" (kích hoạt qua tài khoản Microsoft/phần cứng) hoặc KMS, key giải mã ở trên có thể chỉ là key chung (GVLK) của bộ cài đặt - KHÔNG phải key thật đã mua. Đối chiếu với kênh cấp phép bên dưới trước khi dùng key này để cài lại máy.'
        }
    } else {
        $inv = Get-OfficeInventory
        $desc = ($inv | ForEach-Object { "$($_.Type) $($_.Version)" }) -join ', '
        Write-KeyVal 'Office/Visio/Project phát hiện' $(if($desc){$desc}else{'Không tìm thấy'}) 'White'

        if (@($allRows).Count -eq 0) {
            Write-KeyVal 'Key' '(không đọc được sản phẩm nào qua SPP/OSPP - xem ghi chú vNext/C2R bên dưới nếu có)' 'Yellow'
        } else {
            $anyRegKey = $false
            foreach ($row in $allRows) {
                $label = "$($row.Name)"
                if ($row.FullKey) {
                    Write-KeyVal "$label - kênh $($row.Channel)" $row.FullKey 'Magenta'
                    $anyRegKey = $true
                } else {
                    Write-KeyVal "$label - kênh $($row.Channel) ($($row.Note))" (Mask-Key $row.PartialKey) 'Magenta'
                }
            }
            if ($anyRegKey) {
                Write-Plain 'Lưu ý: nếu sản phẩm dùng "giấy phép số"/tài khoản Microsoft hoặc KMS, key giải mã ở trên có thể chỉ là key chung (GVLK) của bộ cài, KHÔNG phải key thật đã mua.'
            }
        }
    }
    if ($st.VNextUnknown) {
        # KHONG duoc in "khong xac dinh" + "Chua duoc cap phep (Unlicensed)" o day - se khien
        # nguoi dung MS365 hop le hieu lam la Office chua cap phep. Phai noi ro day la GIOI HAN
        # cua cong cu (khong doc duoc vNext), khong phai ket luan ve tinh trang cap phep thuc te.
        Write-KeyVal 'Kênh cấp phép' 'Không đọc được (có thể dùng cơ chế vNext)' 'Yellow'
        Write-KeyVal 'Trạng thái kích hoạt' 'Không xác định được - xem lưu ý bên dưới' 'Yellow'
        Write-Host ''
        Write-Warn $st.Note
        Write-Plain 'Đây là giới hạn của công cụ, KHÔNG phải kết luận Office/Visio/Project chưa được cấp phép. Hãy kiểm tra trực tiếp trong Word/Excel/Visio/Project > File > Account để xem trạng thái đăng nhập và cấp phép thực tế.'
    } else {
        Write-KeyVal 'Kênh cấp phép' $(if($st.Channel){$st.Channel}else{'(không xác định)'}) 'White'
        Write-KeyVal 'Trạng thái kích hoạt' (Convert-LicenseStatus $st.Status) $(if($st.Status -eq 1){'Green'}else{'Yellow'})
    }

    # Bang ket luan mau
    Write-Host ''
    switch ($v.Verdict) {
        'VIOLATION'      { Write-Host "  >>> $($v.Label)" -ForegroundColor Red }
        'SUSPECT'        { Write-Host "  >>> $($v.Label)" -ForegroundColor Yellow }
        'RESIDUAL_LEGIT' { Write-Host "  >>> $($v.Label)" -ForegroundColor Yellow }
        'RESIDUAL'       { Write-Host "  >>> $($v.Label)" -ForegroundColor Yellow }
        'CLEAN'          { Write-Host "  >>> $($v.Label)" -ForegroundColor Green }
    }

    # Chi tiet theo tung phuong thuc
    $groups = Get-MethodGroups -Findings $v.AllFindings
    if ($groups.Count -gt 0) {
        Write-Host ''
        Write-Host '  --- Chi tiết theo từng phương thức ---' -ForegroundColor DarkGray
        foreach ($g in $groups) {
            $color = switch ($g.Top) { 'D1'{'Red'} 'D2'{'Yellow'} 'D3'{'Yellow'} default{'Gray'} }
            $tag = switch ($g.Top) { 'D1'{'[D1 - Xác định]'} 'D2'{'[D2 - Cao]'} 'D3'{'[D3 - Trung bình]'} default{'[D4 - Thấp]'} }
            Write-Host ''
            Write-Host "  * $($g.Method)  $tag  ($($g.Count) dấu hiệu)" -ForegroundColor $color
            foreach ($it in $g.Items) {
                Write-Host "      - Dấu hiệu : $($it.Signal)" -ForegroundColor $color
                Write-Host "        Vị trí   : $($it.Location)" -ForegroundColor DarkGray
                Write-Host "        Ý nghĩa  : $($it.Meaning)" -ForegroundColor Gray
                if ($it.Evidence) { Write-Host "        Chứng cứ : $($it.Evidence)" -ForegroundColor DarkGray }
            }
        }
    }

    # Ket luan dien giai
    Write-Host ''
    Write-Host '  --- Diễn giải kết luận ---' -ForegroundColor DarkGray
    switch ($v.Verdict) {
        'VIOLATION' {
            Write-Bad "Phát hiện can thiệp kỹ thuật đang hoạt động trên $Target."
            Write-Plain 'Các phương thức bị phát hiện được liệt kê ở trên. Bạn có thể chọn gỡ bỏ ở menu.'
        }
        'SUSPECT' {
            Write-Warn "$Target có dấu hiệu BẤT THƯỜNG nhưng chưa đủ căn cứ kỹ thuật để kết luận chắc chắn."
            Write-Plain 'Cần đối chiếu giấy tờ (hợp đồng/hóa đơn) hoặc xác minh với bộ phận CNTT.'
            Write-Plain 'Với máy cá nhân, nếu là KMS/MAK/kích hoạt qua điện thoại mà không có giấy tờ chứng minh thì có thể bị coi là vi phạm bản quyền.'
        }
        'RESIDUAL_LEGIT' {
            Write-Warn "$Target hiện kích hoạt bằng cơ chế HỢP LỆ ($($st.Note)), nhưng còn tồn dư dấu vết công cụ crack cũ."
            Write-Plain 'Nên dọn sạch dấu vết. Kiểm tra lại trạng thái kích hoạt sau khi dọn.'
        }
        'RESIDUAL' {
            Write-Warn "$Target còn dấu vết công cụ crack nhưng không thấy cơ chế kích hoạt lậu đang hoạt động."
            Write-Plain 'Nên dọn sạch dấu vết. Kiểm tra lại trạng thái kích hoạt sau khi dọn.'
        }
        'CLEAN' {
            Write-Good "Không phát hiện dấu hiệu can thiệp kỹ thuật trên $Target."
            Write-Host ''
            Write-Host '  LƯU Ý QUAN TRỌNG:' -ForegroundColor Yellow
            Write-Plain 'Không phát hiện can thiệp kỹ thuật KHÔNG đồng nghĩa bản quyền là hợp pháp.'
            Write-Plain 'Công cụ chỉ chứng minh được "có/không có can thiệp kỹ thuật", KHÔNG chứng minh được tính pháp lý.'
            Write-Plain 'Người dùng phải tự chứng minh bằng hợp đồng, hóa đơn, chứng từ mua bán.'
            if ($st.Channel -match '(?i)Volume|MAK' -or $st.Description -match '(?i)phone') {
                Write-Host ''
                Write-Warn "Đặc biệt: kênh hiện tại là [$($st.Channel)]. Với máy cá nhân, nếu là KMS/MAK/kích hoạt qua điện thoại mà không có giấy tờ chứng minh thì có thể bị coi là vi phạm bản quyền."
            }
        }
    }

    # Cac muc can xac minh (KMS noi bo / Azure)
    if ($v.NeedVerify.Count -gt 0) {
        Write-Host ''
        Write-Host '  --- Cần xác minh với bộ phận CNTT (không kết luận tự động) ---' -ForegroundColor Cyan
        foreach ($nv in $v.NeedVerify) {
            Write-Info "$($nv.Signal) | $($nv.Location)"
            Write-Dim $nv.Meaning
        }
    }
    return $v
}

# =============================================================================
#  SAO LUU
# =============================================================================
function Get-BackupRoot {
    # Luon sao luu vao Desktop cua NGUOI DUNG HIEN TAI (khong dung ProgramData) de
    # nguoi dung de thay, de tu mo lai kiem tra, khong lan voi du lieu he thong dung chung.
    $desktop = $null
    try { $desktop = [Environment]::GetFolderPath('Desktop') } catch {}
    if ([string]::IsNullOrWhiteSpace($desktop)) { $desktop = Join-Path $env:USERPROFILE 'Desktop' }
    if ([string]::IsNullOrWhiteSpace($desktop) -or -not (Test-Path -LiteralPath $desktop)) {
        Write-Warn 'Không xác định được thư mục Desktop của người dùng hiện tại, dùng thư mục tạm thay thế.'
        $desktop = $env:TEMP
    }
    $root = Join-Path $desktop 'WinLicCheck-Backup'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    return $root
}

function Backup-LicenseState {
    $dir = Join-Path (Get-BackupRoot) ('Backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    Start-Checklist -Title 'SAO LƯU TRẠNG THÁI CẤP PHÉP (trước khi thay đổi)' -Steps @(
        'Tạo thư mục sao lưu trên Desktop',
        'Xuất báo cáo giấy phép chi tiết (slmgr /dlv, /dli)',
        'Lưu key & thông tin sản phẩm Windows/Office/BIOS',
        'Xuất các nhánh registry cấp phép (SPP, OSPP, ClickToRun)',
        'Sao lưu tệp hosts',
        'Ghi tệp README hướng dẫn khôi phục'
    )

    [void](Start-Step -Note "Đích: $dir")
    if (Test-Path -LiteralPath $dir) {
        Add-StepDetail "Thư mục sao lưu: $dir" 'Green'
        Complete-Step -Status DAT
    } else { Complete-Step -Status LOI -Note 'Không tạo được thư mục sao lưu'; return $dir }

    [void](Start-Step -Note 'Chạy cscript slmgr.vbs để lưu lại toàn bộ thông tin cấp phép dạng văn bản')
    try {
        cscript //nologo "$env:windir\System32\slmgr.vbs" /dlv 2>&1 | Out-File "$dir\slmgr-dlv.txt" -Encoding UTF8
        cscript //nologo "$env:windir\System32\slmgr.vbs" /dli 2>&1 | Out-File "$dir\slmgr-dli.txt" -Encoding UTF8
        Add-StepDetail 'slmgr-dlv.txt, slmgr-dli.txt'
        Complete-Step -Status DAT
    } catch { Complete-Step -Status LUUY -Note 'Không xuất được báo cáo slmgr (vẫn tiếp tục)' }

    [void](Start-Step -Note 'Xuất đối tượng WMI ra XML để có thể đối chiếu/khôi phục thông tin key sau này')
    $okProd = 0
    try { $Script:WinProds | Export-Clixml "$dir\windows-products.xml"; $okProd++ } catch {}
    try { $Script:OffProds | Export-Clixml "$dir\office-products.xml";  $okProd++ } catch {}
    try { $Script:Bios     | Export-Clixml "$dir\bios-key.xml";         $okProd++ } catch {}
    if ($Script:Bios -and $Script:Bios.Key) {
        Add-StepDetail ("Đã lưu key OEM từ BIOS: {0}" -f (Mask-Key $Script:Bios.Key)) 'Magenta'
    }
    $winRegKey = Get-WindowsRegistryProductKey
    if ($winRegKey) {
        Add-StepDetail ("Key Windows giải mã từ registry: {0}" -f $winRegKey) 'Magenta'
    }
    $officeRegKeys = @($Script:OfficeRegKeys)
    try { $officeRegKeys | Export-Clixml "$dir\office-registry-keys.xml" } catch {}
    foreach ($p in @($Script:WinProds) + @($Script:OffProds) + @($Script:Off14)) {
        if (-not $p.PartialProductKey) { continue }
        $full = ($officeRegKeys | Where-Object { $_.Key -and ($_.Key -replace '-','').Substring(20,5) -eq $p.PartialProductKey } | Select-Object -First 1).Key
        if ($full) { Add-StepDetail ("{0}: key đầy đủ (registry) = {1} (kênh {2})" -f $p.Name, $full, $p.ProductKeyChannel) }
        else { Add-StepDetail ("{0}: 5 ký tự cuối key = {1} (kênh {2})" -f $p.Name, $p.PartialProductKey, $p.ProductKeyChannel) }
    }
    if ($okProd -ge 2) { Complete-Step -Status DAT -Note "$okProd tệp dữ liệu sản phẩm" }
    else { Complete-Step -Status LUUY -Note 'Lưu được một phần dữ liệu sản phẩm' }

    [void](Start-Step -Note 'reg export các nhánh liên quan cấp phép để có thể nhập lại (reg import) nếu cần hoàn tác')
    $okReg = 0
    foreach ($rk in @(
        @{K='HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform'; F='spp.reg'},
        @{K='HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform'; F='spp-policy.reg'},
        @{K='HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform'; F='ospp.reg'},
        @{K='HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'; F='c2r.reg'} )) {
        try {
            reg export $rk.K (Join-Path $dir $rk.F) /y 2>$null | Out-Null
            if (Test-Path (Join-Path $dir $rk.F)) { $okReg++; Add-StepDetail "$($rk.F)  <-  $($rk.K)" }
        } catch {}
    }
    if ($okReg -gt 0) { Complete-Step -Status DAT -Note "$okReg nhánh registry" }
    else { Complete-Step -Status LUUY -Note 'Không xuất được nhánh registry nào (có thể máy không có các nhánh này)' }

    [void](Start-Step)
    try {
        Copy-Item "$env:windir\System32\drivers\etc\hosts" "$dir\hosts.bak" -Force -ErrorAction Stop
        Add-StepDetail 'hosts.bak'
        Complete-Step -Status DAT
    } catch { Complete-Step -Status LUUY -Note 'Không sao chép được tệp hosts' }

    [void](Start-Step -Note 'Ghi chú cách dùng bản sao lưu này để hoàn tác thủ công')
    try {
        $readme = @"
BẢN SAO LƯU TRẠNG THÁI CẤP PHÉP - WinLicCheck v$($Script:VERSION)
Thời điểm: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
Máy: $env:COMPUTERNAME   |   Người dùng: $env:USERNAME

NỘI DUNG:
  slmgr-dlv.txt / slmgr-dli.txt : báo cáo giấy phép trước khi thay đổi
  windows-products.xml          : danh sách sản phẩm Windows (kênh, 5 ký tự cuối key, trạng thái)
  office-products.xml           : danh sách sản phẩm Office/Visio/Project (SPP)
  office-registry-keys.xml      : key đầy đủ giải mã từ registry cho Office/Visio/Project (nếu có)
  bios-key.xml                  : key OEM đọc từ bảng MSDM trong BIOS (nếu có)
  *.reg                         : các nhánh registry cấp phép
  hosts.bak                     : tệp hosts trước khi dọn

CÁCH HOÀN TÁC THỦ CÔNG:
  1. Registry : chuột phải tệp .reg -> Merge (cần quyền Administrator)
  2. hosts    : chép hosts.bak đè lên %WINDIR%\System32\drivers\etc\hosts
  3. Key      : mở windows-products.xml / bios-key.xml để lấy lại thông tin key,
                sau đó dùng: slmgr /ipk <key>  rồi  slmgr /ato

LƯU Ý: Công cụ KHÔNG tạo điểm khôi phục hệ thống (System Restore Point).
       Bản sao lưu này là phương án hoàn tác duy nhất - vui lòng giữ lại.
"@
        $readme | Out-File "$dir\DOC-HUONG-DAN-KHOI-PHUC.txt" -Encoding UTF8
        Add-StepDetail 'DOC-HUONG-DAN-KHOI-PHUC.txt'
        Complete-Step -Status DAT
    } catch { Complete-Step -Status LUUY -Note 'Không ghi được tệp hướng dẫn' }

    # Luu y: KHONG tao Diem khoi phuc he thong (System Restore Point) - theo yeu cau.
    Write-Host ''
    Write-Good "Sao lưu hoàn tất: $dir"
    Write-Plain 'Hãy giữ lại thư mục này cho đến khi chắc chắn máy hoạt động bình thường.'
    return $dir
}

# =============================================================================
#  DON LICH SU POWERSHELL (chi xoa dong goi crack, giu phan con lai)
# =============================================================================
function Clear-CrackHistoryLines {
    $hits = Get-CrackHistoryHits
    if ($hits.Count -eq 0) {
        Add-StepDetail 'Không còn dòng lệnh crack nào trong lịch sử PowerShell' 'Green'
        return $true
    }
    $allOk = $true
    foreach ($h in $hits) {
        Add-StepDetail "Tệp lịch sử: $($h.File)"
        Add-StepDetail "Tổng số dòng: $($h.Total) | Số dòng khớp mẫu lệnh crack: $($h.Matches.Count)"
        foreach ($m in $h.Matches) {
            $preview = $m.Line.Trim()
            if ($preview.Length -gt 78) { $preview = $preview.Substring(0, 78) + '...' }
            Add-StepDetail ("Sẽ xóa dòng {0}: {1}" -f ($m.Index + 1), $preview) 'Yellow'
        }
        try {
            $all = Get-Content -LiteralPath $h.File -Force -ErrorAction SilentlyContinue
            $rmIdx = @($h.Matches | ForEach-Object { $_.Index })
            $bak = "$($h.File).craclean-$(Get-Date -Format 'yyyyMMddHHmmss').bak"
            Copy-Item -LiteralPath $h.File -Destination $bak -Force
            Add-StepDetail "Đã sao lưu nguyên trạng: $bak" 'Green'
            $kept = for ($i=0; $i -lt $all.Count; $i++) { if ($rmIdx -notcontains $i) { $all[$i] } }
            Set-Content -LiteralPath $h.File -Value $kept -Encoding UTF8
            Add-StepDetail "Đã xóa $($rmIdx.Count) dòng lệnh crack, GIỮ NGUYÊN $(@($kept).Count) dòng lệnh khác" 'Green'
        } catch {
            Add-StepDetail "Không xử lý được tệp này: $_" 'Red'
            $allOk = $false
        }
    }
    return $allOk
}

# =============================================================================
#  DON TEP HOSTS (chi xoa dong chan Microsoft, giu phan con lai)
# =============================================================================
function Clear-HostsActivationLines {
    param([string[]]$BadLines)
    $hostsPath = "$env:windir\System32\drivers\etc\hosts"
    if (-not (Test-Path -LiteralPath $hostsPath)) {
        Add-StepDetail 'Không tìm thấy tệp hosts' 'Yellow'; return $false
    }
    try {
        # Bo thuoc tinh chi doc/an neu co (crack thuong dat ReadOnly+Hidden de chong sua)
        $attr = (Get-Item -LiteralPath $hostsPath -Force).Attributes
        if ("$attr" -ne 'Normal' -and "$attr" -ne 'Archive') { Add-StepDetail "Thuộc tính hiện tại của hosts: $attr (sẽ đặt lại Normal để ghi được)" }
        (Get-Item -LiteralPath $hostsPath -Force).Attributes = 'Normal'
    } catch {}
    try {
        $bak = "$hostsPath.craclean-$(Get-Date -Format 'yyyyMMddHHmmss').bak"
        Copy-Item -LiteralPath $hostsPath -Destination $bak -Force
        Add-StepDetail "Đã sao lưu nguyên trạng: $bak" 'Green'
        $lines = Get-Content -LiteralPath $hostsPath -Force
        $actDomains = '(?i)(sls\.microsoft\.com|activation\.sls|licensing\.mp\.microsoft|displaycatalog\.mp\.microsoft|purchase\.mp\.microsoft|licensing\.microsoft\.com|validation\.sls)'
        $removed = 0
        $kept = foreach ($ln in $lines) {
            $t = $ln.Trim()
            if (-not $t.StartsWith('#') -and $t -match $actDomains -and $t -match '^\s*(0\.0\.0\.0|127\.|::1)') {
                Add-StepDetail "Sẽ xóa dòng chặn: $t" 'Yellow'
                $removed++
                continue
            }
            $ln
        }
        Set-Content -LiteralPath $hostsPath -Value $kept -Encoding ASCII
        Add-StepDetail "Đã xóa $removed dòng chặn máy chủ kích hoạt, GIỮ NGUYÊN $(@($kept).Count) dòng khác" 'Green'
        return $true
    } catch { Add-StepDetail "Không sửa được tệp hosts: $_" 'Red'; return $false }
}

# =============================================================================
#  GO BO HIEN VAT (thuc thi theo danh sach phat hien)
# =============================================================================
function Invoke-RemoveFindings {
    param([object[]]$Findings, [switch]$IncludeActiveConfig)

    $Script:ScanFresh = $false   # he thong sap thay doi -> ket qua quet cu khong con dung

    # Thu tu an toan: tac vu -> service -> tien trinh -> ohook -> tep/thu muc -> registry
    #                 -> Defender -> hosts -> lich su lenh
    # Ly do thu tu nay: phai dung co che tu-tai-tao (tac vu/service/tien trinh) TRUOC khi
    # xoa tep, neu khong cong cu crack se ghi lai tep ngay sau khi bi xoa.
    Start-Checklist -Title 'GỠ BỎ CƠ CHẾ & DẤU VẾT' -Steps @(
        'Xóa tác vụ theo lịch của công cụ crack',
        'Dừng và xóa dịch vụ (service) giả lập',
        'Kết thúc tiến trình đang chạy',
        'Khôi phục tệp gốc bị Ohook thay thế (Office)',
        'Xóa tệp/thư mục hiện vật còn lại',
        'Xóa giá trị registry do crack ghi',
        'Gỡ ngoại lệ Microsoft Defender do crack thêm',
        'Dọn tệp hosts (chỉ dòng chặn kích hoạt)',
        'Dọn lịch sử lệnh PowerShell (chỉ dòng gọi crack)'
    )

    # --- 1. Tac vu dinh ky ---------------------------------------------------
    $tasks = @($Findings | Where-Object { $_.Data.TaskName })
    [void](Start-Step -Note 'Tác vụ tự chạy lại việc kích hoạt (vd Activation-Renewal của MAS)')
    if ($tasks.Count -eq 0) { Complete-Step -Status BOQUA -Note 'Không có tác vụ nào cần xóa' }
    else {
        $ok = 0; $fail = 0
        foreach ($f in $tasks) {
            $full = "$($f.Data.TaskPath)$($f.Data.TaskName)"
            try {
                Unregister-ScheduledTask -TaskName $f.Data.TaskName -TaskPath $f.Data.TaskPath -Confirm:$false -ErrorAction Stop
                Add-StepDetail "Đã xóa tác vụ: $full" 'Green'; $ok++
            } catch { Add-StepDetail "KHÔNG xóa được tác vụ: $full ($_)" 'Red'; $fail++ }
        }
        if ($fail -eq 0) { Complete-Step -Status DAT -Note "Đã xóa $ok tác vụ" }
        else { Complete-Step -Status LOI -Note "Xóa được $ok, thất bại $fail" }
    }

    # --- 2. Service ----------------------------------------------------------
    $svcs = @($Findings | Where-Object { $_.Data.Service })
    [void](Start-Step -Note 'Dịch vụ nền của KMS emulator (vlmcsd, KMSELDI...)')
    if ($svcs.Count -eq 0) { Complete-Step -Status BOQUA -Note 'Không có dịch vụ nào cần xóa' }
    else {
        $ok = 0; $fail = 0
        foreach ($f in $svcs) {
            $n = $f.Data.Service
            try {
                Add-StepDetail "Dừng dịch vụ: $n"
                Stop-Service -Name $n -Force -ErrorAction SilentlyContinue
                & sc.exe delete $n | Out-Null
                if (Get-Service -Name $n -ErrorAction SilentlyContinue) {
                    Add-StepDetail "Dịch vụ vẫn còn sau khi xóa: $n (cần khởi động lại máy)" 'Yellow'; $fail++
                } else { Add-StepDetail "Đã xóa dịch vụ: $n" 'Green'; $ok++ }
            } catch { Add-StepDetail "KHÔNG xóa được dịch vụ: $n" 'Red'; $fail++ }
        }
        if ($fail -eq 0) { Complete-Step -Status DAT -Note "Đã xóa $ok dịch vụ" }
        else { Complete-Step -Status LUUY -Note "Xóa được $ok, còn $fail cần khởi động lại máy" }
    }

    # --- 3. Tien trinh -------------------------------------------------------
    $procs = @($Findings | Where-Object { $_.Data.ProcId })
    [void](Start-Step -Note 'Tiến trình đang lắng nghe cổng 1688 hoặc tiến trình công cụ crack')
    if ($procs.Count -eq 0) { Complete-Step -Status BOQUA -Note 'Không có tiến trình nào cần kết thúc' }
    else {
        $ok = 0
        foreach ($f in $procs) {
            try {
                Stop-Process -Id $f.Data.ProcId -Force -ErrorAction Stop
                Add-StepDetail "Đã kết thúc tiến trình PID $($f.Data.ProcId)" 'Green'; $ok++
            } catch { Add-StepDetail "Không kết thúc được PID $($f.Data.ProcId)" 'Yellow' }
        }
        Complete-Step -Status $(if ($ok -eq $procs.Count) {'DAT'} else {'LUUY'}) -Note "Kết thúc $ok/$($procs.Count) tiến trình"
    }

    # --- 4. Ohook MSI (Microsoft Shared) -------------------------------------
    # Uu tien KHOI PHUC ban goc tu sppcs.dll, sau do moi xu ly OSPPC.DLL hook con lai.
    $ohShared = @($Findings | Where-Object { $_.Data.Kind -eq 'OhookShared' })
    $ohHook   = @($Findings | Where-Object { $_.Data.Kind -eq 'OhookSharedHook' })
    [void](Start-Step -Note 'Đổi sppcs.dll (bản gốc đã bị đổi tên) trở lại thành OSPPC.DLL')
    if ($ohShared.Count -eq 0 -and $ohHook.Count -eq 0) { Complete-Step -Status BOQUA -Note 'Không phát hiện Ohook kiểu MSI' }
    else {
        $dirsRestored = @{}
        $restored = 0; $deleted = 0; $noOrigin = 0
        foreach ($f in $ohShared) {
            $sppcs = $f.Data.Path
            $dir   = Split-Path $sppcs
            $osppc = Join-Path $dir 'OSPPC.DLL'
            try {
                Add-StepDetail "Thư mục: $dir"
                Remove-Item -LiteralPath $osppc -Force -ErrorAction SilentlyContinue      # xoa DLL hook nho
                Move-Item -LiteralPath $sppcs -Destination $osppc -Force -ErrorAction Stop # tra lai ban goc
                $dirsRestored[$dir.ToLower()] = $true
                Add-StepDetail "Đã khôi phục OSPPC.DLL gốc từ sppcs.dll" 'Green'; $restored++
            } catch { Add-StepDetail "KHÔNG khôi phục được OSPPC.DLL: $_" 'Red' }
        }
        foreach ($f in $ohHook) {
            $osppc = $f.Data.Path
            $dir   = (Split-Path $osppc).ToLower()
            if ($dirsRestored[$dir]) { continue }   # da khoi phuc ban goc o tren -> khong xoa nham
            try {
                Remove-Item -LiteralPath $osppc -Force -ErrorAction Stop
                Add-StepDetail "Đã xóa OSPPC.DLL bị móc nối: $osppc" 'Green'; $deleted++
                Add-StepDetail 'Không có bản gốc để khôi phục - hãy chạy "Sửa chữa" (Repair) Office để phục hồi tệp gốc.' 'Yellow'
                $noOrigin++
            } catch { Add-StepDetail "KHÔNG xóa được: $osppc" 'Red' }
        }
        if ($noOrigin -gt 0) { Complete-Step -Status LUUY -Note "Khôi phục $restored, xóa $deleted (cần Repair Office)" }
        else { Complete-Step -Status DAT -Note "Khôi phục $restored, xóa $deleted" }
    }

    # --- 5. Tep/thu muc con lai ----------------------------------------------
    $files = @($Findings | Where-Object { $_.Data.Path -and $_.Data.Kind -notin @('OhookShared','OhookSharedHook') })
    [void](Start-Step -Note 'Gồm sppc.dll trong VFS của Office và thư mục công cụ crack; xử lý an toàn với symlink/junction')
    if ($files.Count -eq 0) { Complete-Step -Status BOQUA -Note 'Không có tệp/thư mục nào cần xóa' }
    else {
        $ok = 0; $locked = 0; $absent = 0
        foreach ($f in $files) {
            $p = $f.Data.Path
            if (-not (Test-Path -LiteralPath $p)) { Add-StepDetail "Đã không còn tồn tại: $p"; $absent++; continue }
            try {
                $item = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
                $isReparse = $item -and (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
                if ($isReparse) {
                    Add-StepDetail "Là liên kết (symlink/junction) - xóa liên kết, không đụng vào đích: $p"
                    cmd /c rmdir "$p" 2>$null
                    if (Test-Path -LiteralPath $p) { cmd /c del /f /q "$p" 2>$null }
                } else {
                    Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
                }
                if (Test-Path -LiteralPath $p) {
                    Add-StepDetail "CHƯA xóa được (tệp đang bị khóa): $p" 'Yellow'; $locked++
                } else { Add-StepDetail "Đã xóa: $p" 'Green'; $ok++ }
            } catch { Add-StepDetail "Lỗi khi xóa $p : $_" 'Red'; $locked++ }
        }
        if ($locked -eq 0) { Complete-Step -Status DAT -Note "Đã xóa $ok (bỏ qua $absent mục không còn tồn tại)" }
        else { Complete-Step -Status LUUY -Note "Đã xóa $ok, còn $locked mục bị khóa - hãy khởi động lại máy rồi quét lại" }
    }

    # --- 6. Registry ---------------------------------------------------------
    $regs = @($Findings | Where-Object { $_.Data.RegKey -and $_.Data.RegVal })
    [void](Start-Step -Note 'Chỉ xóa đúng các giá trị do crack ghi, không xóa nguyên khóa của hệ thống')
    if ($regs.Count -eq 0) { Complete-Step -Status BOQUA -Note 'Không có giá trị registry nào cần xóa' }
    else {
        $ok = 0; $fail = 0
        foreach ($f in $regs) {
            try {
                Remove-ItemProperty -Path $f.Data.RegKey -Name $f.Data.RegVal -Force -ErrorAction Stop
                Add-StepDetail "Đã xóa: $($f.Data.RegVal) @ $($f.Data.RegKey)" 'Green'; $ok++
            } catch { Add-StepDetail "KHÔNG xóa được: $($f.Data.RegVal) @ $($f.Data.RegKey)" 'Red'; $fail++ }
        }
        if ($fail -eq 0) { Complete-Step -Status DAT -Note "Đã xóa $ok giá trị" }
        else { Complete-Step -Status LOI -Note "Xóa được $ok, thất bại $fail" }
    }

    # --- 7. Ngoai le Defender ------------------------------------------------
    $exPath = @($Findings | Where-Object { $_.Data.ExclusionPath })
    $exProc = @($Findings | Where-Object { $_.Data.ExclusionProcess })
    [void](Start-Step -Note 'Công cụ crack thường tự thêm ngoại lệ để không bị Defender xóa')
    if ($exPath.Count -eq 0 -and $exProc.Count -eq 0) { Complete-Step -Status BOQUA -Note 'Không có ngoại lệ nào cần gỡ' }
    else {
        $ok = 0
        foreach ($f in $exPath) {
            try { Remove-MpPreference -ExclusionPath $f.Data.ExclusionPath -ErrorAction Stop
                  Add-StepDetail "Đã gỡ ngoại lệ đường dẫn: $($f.Data.ExclusionPath)" 'Green'; $ok++ }
            catch { Add-StepDetail "Không gỡ được ngoại lệ: $($f.Data.ExclusionPath)" 'Yellow' }
        }
        foreach ($f in $exProc) {
            try { Remove-MpPreference -ExclusionProcess $f.Data.ExclusionProcess -ErrorAction Stop
                  Add-StepDetail "Đã gỡ ngoại lệ tiến trình: $($f.Data.ExclusionProcess)" 'Green'; $ok++ }
            catch { Add-StepDetail "Không gỡ được ngoại lệ tiến trình: $($f.Data.ExclusionProcess)" 'Yellow' }
        }
        $tot = $exPath.Count + $exProc.Count
        Complete-Step -Status $(if ($ok -eq $tot) {'DAT'} else {'LUUY'}) -Note "Gỡ $ok/$tot ngoại lệ"
    }

    # --- 8. Hosts ------------------------------------------------------------
    $hostsF = @($Findings | Where-Object { $_.Data.BadLines })
    [void](Start-Step -Note 'Chỉ xóa dòng trỏ tên miền kích hoạt Microsoft về loopback, giữ nguyên các dòng khác')
    if ($hostsF.Count -eq 0) { Complete-Step -Status BOQUA -Note 'Tệp hosts không có dòng chặn kích hoạt' }
    else {
        $allOk = $true
        foreach ($f in $hostsF) { if (-not (Clear-HostsActivationLines -BadLines $f.Data.BadLines)) { $allOk = $false } }
        Complete-Step -Status $(if ($allOk) {'DAT'} else {'LOI'}) -Note $(if ($allOk) {'Đã dọn tệp hosts'} else {'Không dọn được tệp hosts'})
    }

    # --- 9. Lich su lenh -----------------------------------------------------
    $histF = @($Findings | Where-Object { $_.Data.File })
    [void](Start-Step -Note 'Chỉ xóa đúng dòng lệnh gọi crack; giữ toàn bộ lệnh khác; có sao lưu nguyên trạng')
    if ($histF.Count -eq 0) { Complete-Step -Status BOQUA -Note 'Lịch sử PowerShell không có lệnh gọi crack' }
    else {
        $ok = Clear-CrackHistoryLines
        Complete-Step -Status $(if ($ok) {'DAT'} else {'LUUY'}) -Note $(if ($ok) {'Đã dọn lịch sử'} else {'Dọn được một phần'})
    }
}

# Xoa cau hinh KMS con lai bang slmgr (dung khi go co che dang hoat dong)
# Ham nay duoc goi BEN TRONG mot buoc checklist -> dung Add-StepDetail de in chi tiet.
function Clear-KmsConfiguration {
    $Script:ScanFresh = $false
    Add-StepDetail 'Chạy slmgr /ckms (xóa tên máy chủ KMS đã đặt)'
    cscript //nologo "$env:windir\System32\slmgr.vbs" /ckms 2>&1 | Out-Null
    Add-StepDetail 'Chạy slmgr /ckhc (tắt bộ nhớ đệm máy chủ KMS)'
    cscript //nologo "$env:windir\System32\slmgr.vbs" /ckhc 2>&1 | Out-Null

    # Xoa gia tri KMS o ca hai nhanh + subkey (bao gom 127.0.0.2 cua TSforge)
    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform',
        'HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\OfficeSoftwareProtectionPlatform'
    )
    $removed = 0
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        Add-StepDetail "Duyệt nhánh: $root"
        $keys = @($root)
        try { $keys += (Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.PSPath }) } catch {}
        foreach ($k in $keys) {
            foreach ($val in 'KeyManagementServiceName','KeyManagementServicePort','KeyManagementServiceLookupDomain','DisableDnsPublishing','DisableKeyManagementServiceHostCaching') {
                $cur = $null
                try { $cur = (Get-ItemProperty -Path $k -Name $val -ErrorAction SilentlyContinue).$val } catch {}
                if ($null -ne $cur) {
                    Remove-ItemProperty -Path $k -Name $val -ErrorAction SilentlyContinue
                    $short = $k -replace '^Microsoft\.PowerShell\.Core\\Registry::',''
                    Add-StepDetail "Đã xóa $val = $cur  @ $short" 'Green'
                    $removed++
                }
            }
        }
    }
    if ($removed -eq 0) { Add-StepDetail 'Không còn giá trị KMS nào trong registry' 'Green' }
    return $removed
}

# =============================================================================
#  TAI TAO KHO GIAY PHEP SPP (bat buoc voi TSforge/KMS38)
# =============================================================================
function Reset-SppStore {
    Write-Host ''
    Write-Warn 'THAO TÁC RỦI RO CAO: Tái tạo kho giấy phép SPP.'
    Write-Plain 'Cần thiết khi phát hiện TSforge/KMS38 (dữ liệu giả nằm trong kho, không phải tệp riêng lẻ).'
    Write-Plain 'Kho hiện tại sẽ được sao lưu (đổi tên .bak) trước khi dựng lại.'
    if (-not (Ask-Confirm 'Xác nhận tái tạo kho SPP? Giấy phép hợp lệ (nếu có) có thể phải kích hoạt lại.' 'TAITAO')) {
        Write-Info 'Đã hủy tái tạo kho SPP.'; return
    }

    $Script:ScanFresh = $false
    Start-Checklist -Title 'TÁI TẠO KHO GIẤY PHÉP SPP' -Steps @(
        'Xác định vị trí kho giấy phép & tạo thư mục sao lưu',
        'Dừng các dịch vụ đang giữ tệp kho (sppsvc, ClipSVC, osppsvc)',
        'Sao lưu và đổi tên các tệp kho (data.dat, tokens.dat, cache.dat)',
        'Khởi động lại dịch vụ với kiểu khởi động gốc',
        'Cài lại toàn bộ tệp giấy phép gốc của Windows (slmgr /rilc)',
        'Kiểm tra lại trạng thái kho sau khi tái tạo'
    )

    $store = "$env:windir\System32\spp\store\2.0"
    if (-not (Test-Path $store)) { $store = "$env:windir\System32\spp\store" }
    $backup = Join-Path (Get-BackupRoot) ("spp-store-" + (Get-Date -Format 'yyyyMMddHHmmss'))

    [void](Start-Step)
    try {
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        Add-StepDetail "Kho giấy phép: $store"
        Add-StepDetail "Thư mục sao lưu: $backup" 'Green'
        Complete-Step -Status DAT
    } catch { Complete-Step -Status LOI -Note 'Không tạo được thư mục sao lưu - dừng thao tác'; return }

    # Luu kieu khoi dong goc cua sppsvc de khoi phuc dung (mac dinh thuong la Manual/trigger)
    [void](Start-Step -Note 'Phải dừng dịch vụ thì mới đổi tên được tệp kho đang bị khóa')
    $sppOrigStart = (Get-Service -Name sppsvc -ErrorAction SilentlyContinue).StartType
    Add-StepDetail "Kiểu khởi động gốc của sppsvc: $sppOrigStart (sẽ khôi phục đúng như cũ ở bước 4)"
    foreach ($svc in 'sppsvc','ClipSVC','osppsvc') {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if (-not $s) { Add-StepDetail "$svc : không có trên máy này (bỏ qua)"; continue }
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s.Status -eq 'Stopped') { Add-StepDetail "$svc : đã dừng" 'Green' }
        else { Add-StepDetail "$svc : vẫn đang ở trạng thái $($s.Status)" 'Yellow' }
    }
    try { Set-Service -Name sppsvc -StartupType Manual -ErrorAction SilentlyContinue } catch {}
    Start-Sleep -Seconds 2
    Complete-Step -Status DAT

    [void](Start-Step -Note 'Đổi tên thành .bak để SPP tự dựng kho mới sạch ở lần khởi động tiếp theo')
    $done = 0; $failed = 0
    foreach ($rel in 'data.dat','tokens.dat','cache\cache.dat') {
        $p = Join-Path $store $rel
        if (-not (Test-Path -LiteralPath $p)) { Add-StepDetail "$rel : không tồn tại (bỏ qua)"; continue }
        try {
            $sz = [math]::Round((Get-Item -LiteralPath $p -Force).Length / 1KB, 1)
            Copy-Item -LiteralPath $p -Destination $backup -Force -ErrorAction SilentlyContinue
            Rename-Item -LiteralPath $p -NewName ((Split-Path $rel -Leaf) + '.bak') -Force -ErrorAction Stop
            Add-StepDetail "$rel ($sz KB) : đã sao lưu và đổi tên thành .bak" 'Green'; $done++
        } catch {
            Add-StepDetail "$rel : KHÔNG xử lý được - $_ (sppsvc có thể chưa dừng hẳn)" 'Red'; $failed++
        }
    }
    if ($failed -eq 0 -and $done -gt 0) { Complete-Step -Status DAT -Note "Đã xử lý $done tệp kho" }
    elseif ($done -gt 0) { Complete-Step -Status LUUY -Note "Xử lý được $done, thất bại $failed - hãy khởi động lại máy rồi làm lại" }
    else { Complete-Step -Status LOI -Note 'Không xử lý được tệp kho nào' }

    [void](Start-Step -Note 'Khôi phục đúng kiểu khởi động gốc, KHÔNG ép thành Automatic')
    if ($sppOrigStart) {
        try { Set-Service -Name sppsvc -StartupType $sppOrigStart -ErrorAction SilentlyContinue
              Add-StepDetail "Đã đặt lại sppsvc về kiểu khởi động: $sppOrigStart" 'Green' } catch {}
    }
    Start-Service -Name sppsvc -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $s = Get-Service -Name sppsvc -ErrorAction SilentlyContinue
    Add-StepDetail "Trạng thái sppsvc hiện tại: $($s.Status)"
    Complete-Step -Status $(if ($s.Status -eq 'Running') {'DAT'} else {'LUUY'}) -Note "sppsvc: $($s.Status)"

    [void](Start-Step -Note 'slmgr /rilc nạp lại toàn bộ tệp .xrm-ms giấy phép gốc từ %WINDIR%\System32\spp\tokens')
    try {
        cscript //nologo "$env:windir\System32\slmgr.vbs" /rilc 2>&1 | Out-Null
        Start-Service -Name ClipSVC -ErrorAction SilentlyContinue
        Add-StepDetail 'Đã nạp lại tệp giấy phép gốc' 'Green'
        Complete-Step -Status DAT
    } catch { Complete-Step -Status LUUY -Note 'Lệnh /rilc không hoàn tất - hãy chạy lại sau khi khởi động máy' }

    [void](Start-Step -Note 'Đọc lại kho để xác nhận đã có tệp mới được tạo')
    $newOk = 0
    foreach ($rel in 'data.dat','tokens.dat') {
        $p = Join-Path $store $rel
        if (Test-Path -LiteralPath $p) {
            $t = (Get-Item -LiteralPath $p -Force).LastWriteTime
            Add-StepDetail "$rel : đã được tạo lại lúc $($t.ToString('dd/MM/yyyy HH:mm:ss'))" 'Green'; $newOk++
        } else { Add-StepDetail "$rel : chưa được tạo lại (sẽ tạo sau khi khởi động máy)" 'Yellow' }
    }
    Complete-Step -Status $(if ($newOk -ge 1) {'DAT'} else {'LUUY'}) -Note "$newOk/2 tệp kho đã được tạo lại"

    Write-Host ''
    Write-Good "Đã tái tạo kho SPP. Bản sao lưu: $backup"
    Write-Warn 'Hãy KHỞI ĐỘNG LẠI MÁY, sau đó kích hoạt lại bằng key hợp pháp.'
}

# =============================================================================
#  KICH HOAT LAI
# =============================================================================
# Key generic (Retail/OEM) cho doi phien ban Windows 10/11 - dung khi doi/ha phien ban
$Script:WIN_GENERIC = @{
    'Core'                 = @{ Name='Home';        Key='YTMG3-N6DKC-DKB77-7M9GH-8HVX7' }
    'CoreSingleLanguage'   = @{ Name='Home SL';     Key='BT79Q-G7N6G-PGBYW-4YWX6-6F4BT' }
    'Professional'         = @{ Name='Pro';         Key='VK7JG-NPHTM-C97JM-9MPGT-3V66T' }
    'ProfessionalEducation'= @{ Name='Pro Edu';     Key='8PTT6-RNW4C-6V7J2-C2D3X-MHBPB' }
    'ProfessionalWorkstation'=@{ Name='Pro WKS';    Key='DXG7C-N36C4-C4HTG-X4T3X-2YV77' }
    'Education'            = @{ Name='Education';    Key='YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY' }
    'Enterprise'          = @{ Name='Enterprise';   Key='XGVPP-NMH47-7TTHJ-W3FW7-8HV2C' }
}

function Install-ProductKeySafe {
    param([string]$Key)
    # Cai key MOI truoc (khong go key cu truoc) - neu key moi bi tu choi, key cu van nguyen ven
    $out = cscript //nologo "$env:windir\System32\slmgr.vbs" /ipk $Key 2>&1
    $txt = ($out | Out-String)
    return $txt
}

function Show-ActivationError {
    param([string]$Text)
    $map = @{
        '0xC004F069'='Sai SKU - key thuoc phien ban Windows khac (can doi/ha phien ban)'
        '0xC004F050'='Key khong hop le hoac nhap sai'
        '0xC004C003'='Key da bi Microsoft thu hoi (key thi truong xam)'
        '0xC004C001'='May chu Microsoft tu choi key'
        '0xC004C020'='Vuot gioi han kich hoat MAK'
        '0xC004C021'='Vuot gioi han kich hoat MAK'
        '0xC004B100'='May chu khong the kich hoat key nay'
        '0xC004F009'='Het thoi gian an han'
        '0x8007232B'='Khong tim thay may chu KMS (binh thuong neu khong dung KMS)'
        '0xC004F074'='Khong lien he duoc KMS host'
        '0x8004FE21'='Windows khong chinh hang - tep he thong co the bi sua doi'
        '0x80070490'='Key khong hoat dong voi phien ban nay'
    }
    foreach ($code in $map.Keys) {
        if ($Text -match [regex]::Escape($code)) {
            Write-Bad "Ma loi $code : $($map[$code])"
            return $code
        }
    }
    return $null
}

function Invoke-ActivateWithKey {
    # Quy trinh kich hoat CHUNG cho ca key BIOS lan key nguoi dung nhap, chay duoi
    # dang checklist de nguoi dung theo doi duoc tung buoc va biet buoc nao that bai.
    param(
        [string]$Key,
        [string]$KeyDesc  = '',      # mo ta phien ban cua key (neu doc duoc tu BIOS)
        [string]$Origin   = 'key'    # 'BIOS' hoac 'nguoi dung nhap'
    )
    $Script:ScanFresh = $false
    Start-Checklist -Title "KÍCH HOẠT WINDOWS BẰNG KEY ($Origin)" -Steps @(
        'Kiểm tra định dạng key & đối chiếu phiên bản Windows',
        'Kiểm tra kết nối tới máy chủ kích hoạt của Microsoft',
        'Cài đặt key vào hệ thống (slmgr /ipk)',
        'Gửi yêu cầu kích hoạt trực tuyến (slmgr /ato)',
        'Xác minh trạng thái kích hoạt sau khi thực hiện'
    )

    # --- 1 ---
    [void](Start-Step -Note 'Key phải đúng 25 ký tự và phải thuộc đúng phiên bản Windows đang cài')
    if ($Key -notmatch '^[A-Za-z0-9]{5}(-[A-Za-z0-9]{5}){4}$') {
        Add-StepDetail 'Key không đúng định dạng XXXXX-XXXXX-XXXXX-XXXXX-XXXXX' 'Red'
        Complete-Step -Status LOI -Note 'Định dạng key không hợp lệ'
        return $false
    }
    Add-StepDetail ("Key sẽ dùng: {0}" -f (Mask-Key $Key)) 'Magenta'
    $curEd = $Script:WinInfo.EditionID
    Add-StepDetail "Phiên bản Windows đang chạy: $curEd ($($Script:WinInfo.ProductName))"
    $mismatch = $false
    if ($KeyDesc) {
        Add-StepDetail "Phiên bản gắn với key: $KeyDesc"
        if ($curEd -and ($KeyDesc -notmatch [regex]::Escape($curEd))) { $mismatch = $true }
    }
    if ($mismatch) {
        Add-StepDetail 'Key có thể KHÔNG khớp phiên bản đang cài - dự kiến lỗi 0xC004F069' 'Yellow'
        Complete-Step -Status LUUY -Note 'Nghi ngờ lệch phiên bản'
        if (-not (Ask-YesNo 'Vẫn thử cài key này?' -DefaultNo)) { return $false }
    } else { Complete-Step -Status DAT }

    # --- 2 ---
    [void](Start-Step -Note 'Kích hoạt trực tuyến cần kết nối Internet; nếu không có, key vẫn cài được nhưng chưa kích hoạt')
    $net = Test-Internet
    if ($net) { Add-StepDetail 'Có kết nối Internet' 'Green'; Complete-Step -Status DAT }
    else { Add-StepDetail 'KHÔNG có kết nối Internet' 'Yellow'; Complete-Step -Status LUUY -Note 'Không có mạng - sẽ chỉ cài key, chưa kích hoạt được' }

    # --- 3 ---
    [void](Start-Step -Note 'Cài key MỚI trước; nếu bị từ chối thì key cũ vẫn còn nguyên (không gỡ trước)')
    $r = Install-ProductKeySafe -Key $Key
    $err = Show-ActivationError $r
    if ($err) {
        Add-StepDetail "Hệ thống từ chối key. Mã lỗi: $err" 'Red'
        Complete-Step -Status LOI -Note "Cài key thất bại ($err)"
        if ($err -eq '0xC004F069') { Invoke-EditionMismatch-Windows -Key $Key -Desc $KeyDesc }
        return $false
    }
    Add-StepDetail 'Đã cài key vào hệ thống' 'Green'
    Complete-Step -Status DAT

    # --- 4 ---
    [void](Start-Step -Note 'Gửi yêu cầu tới máy chủ kích hoạt của Microsoft')
    if (-not $net) {
        Add-StepDetail 'Bỏ qua vì không có kết nối Internet. Hãy kết nối mạng rồi chạy: slmgr /ato' 'Yellow'
        Complete-Step -Status BOQUA -Note 'Không có mạng'
    } else {
        $ato = cscript //nologo "$env:windir\System32\slmgr.vbs" /ato 2>&1 | Out-String
        $errA = Show-ActivationError $ato
        if ($errA) { Add-StepDetail "Máy chủ trả về lỗi: $errA" 'Red'; Complete-Step -Status LOI -Note "Kích hoạt thất bại ($errA)" }
        else { Add-StepDetail 'Máy chủ chấp nhận yêu cầu kích hoạt' 'Green'; Complete-Step -Status DAT }
    }

    # --- 5 ---
    [void](Start-Step -Note 'Đọc lại WMI để xác nhận trạng thái thực tế, không tin vào thông báo trung gian')
    Start-Sleep -Seconds 2
    $prods = Get-LicenseProducts $Script:WINDOWS_APPID
    $act   = $prods | Where-Object { $_.LicenseStatus -eq 1 } | Select-Object -First 1
    $ok = $false
    if ($act) {
        Add-StepDetail ("Đã kích hoạt: {0}" -f $act.Name) 'Green'
        Add-StepDetail ("Kênh cấp phép: {0} | 5 ký tự cuối key: {1}" -f $act.ProductKeyChannel, $act.PartialProductKey) 'Green'
        $ok = $true
        Complete-Step -Status DAT -Note "Windows đã kích hoạt (kênh $($act.ProductKeyChannel))"
    } else {
        $cur = $prods | Select-Object -First 1
        if ($cur) { Add-StepDetail ("Trạng thái hiện tại: {0}" -f (Convert-LicenseStatus $cur.LicenseStatus)) 'Yellow' }
        else { Add-StepDetail 'Không đọc được sản phẩm Windows nào sau khi cài key' 'Yellow' }
        Complete-Step -Status LUUY -Note 'Chưa ở trạng thái đã kích hoạt'
    }
    $Script:WinProds = $prods
    Write-Host ''
    cscript //nologo "$env:windir\System32\slmgr.vbs" /xpr
    return $ok
}

function Invoke-Reactivate-Windows {
    Write-Sub 'KÍCH HOẠT LẠI WINDOWS'
    $bios = Get-BiosOemKey
    Write-Host '  Chọn cách kích hoạt:' -ForegroundColor White
    if ($bios.Key) {
        Write-Host "   [1] Dùng key OEM trong BIOS/MSDM  ($($bios.Description))" -ForegroundColor Green
    } else {
        Write-Host '   [1] Dùng key OEM trong BIOS/MSDM  (KHÔNG tìm thấy trên máy này)' -ForegroundColor DarkGray
    }
    Write-Host '   [2] Nhập key Retail/Volume hợp pháp của bạn' -ForegroundColor White
    Write-Host '   [3] Để ở trạng thái CHƯA kích hoạt (đăng nhập tài khoản Microsoft để lấy Digital License)' -ForegroundColor White
    Write-Host '   [0] Quay lại' -ForegroundColor Gray
    $c = Read-Host '  Chọn'
    # Sau khi chon, mo TRANG MOI cho ket qua cua lua chon (thay vi noi tiep ben duoi menu cu).
    Show-Banner
    switch ($c) {
        '1' {
            if (-not $bios.Key) { Write-Warn 'Máy không có key OEM trong BIOS.'; return }
            [void](Invoke-ActivateWithKey -Key $bios.Key -KeyDesc $bios.Description -Origin 'đọc từ BIOS/MSDM')
        }
        '2' {
            $key = Read-Host '  Nhập key 25 ký tự (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)'
            [void](Invoke-ActivateWithKey -Key $key -KeyDesc '' -Origin 'người dùng nhập')
        }
        '3' {
            Start-Checklist -Title 'ĐỂ MÁY Ở TRẠNG THÁI CHƯA KÍCH HOẠT' -Steps @(
                'Xác nhận không còn key bất hợp pháp trên máy'
            )
            [void](Start-Step -Note 'Kiểm tra lại sản phẩm Windows hiện có trên hệ thống')
            $prods = Get-LicenseProducts $Script:WINDOWS_APPID
            if (@($prods).Count -eq 0) {
                Add-StepDetail 'Không còn key nào được cài trên hệ thống' 'Green'
                Complete-Step -Status DAT
            } else {
                foreach ($p in $prods) { Add-StepDetail ("{0} | kênh {1} | {2}" -f $p.Name, $p.ProductKeyChannel, (Convert-LicenseStatus $p.LicenseStatus)) }
                Complete-Step -Status LUUY -Note 'Vẫn còn key trên hệ thống - hãy kiểm tra kênh cấp phép ở trên'
            }
            # Huong dan hien thi TRUC TIEP tren man hinh (khong qua Add-StepDetail, vi Add-StepDetail
            # chi luu noi bo cho Show-TargetReport - o day nguoi dung can THAY duoc huong dan ngay).
            Write-Host ''
            Write-Host '  --- HƯỚNG DẪN LẤY LẠI DIGITAL LICENSE QUA TÀI KHOẢN MICROSOFT ---' -ForegroundColor Cyan
            Write-Plain '   1. Vào Settings > System > Activation > Troubleshoot (Khắc phục sự cố)'
            Write-Plain '   2. Đăng nhập tài khoản Microsoft đã từng gắn Digital License với thiết bị này'
            Write-Plain '   3. Nếu máy từng có Digital License hợp lệ, Windows sẽ tự kích hoạt khi có kết nối Internet'
            Pause-Return
            # Bao cho tang goi (Invoke-Handle-Target / Show-ConclusionMenu) biet can quet lai
            # NGAY tu dau nhu vua mo script - xem co che $Script:ForceRescanNow o Show-ConclusionMenu.
            $Script:ForceRescanNow = $true
        }
        default { return }
    }
}

function Invoke-EditionMismatch-Windows {
    param([string]$Key, [string]$Desc)
    Write-Host ''
    Write-Warn 'Key không khớp phiên bản Windows đang cài (lỗi SKU 0xC004F069).'
    $curEd = $Script:WinInfo.EditionID
    Write-KeyVal 'Phiên bản đang chạy' $curEd 'White'
    if ($Desc) { Write-KeyVal 'Phiên bản của key' $Desc 'White' }
    Write-Host ''
    Write-Plain 'Để dùng được key này, phiên bản Windows phải khớp. Các lựa chọn:'
    Write-Host '   [1] Đổi phiên bản Windows cho khớp key (dùng changepk.exe)' -ForegroundColor White
    Write-Host '   [2] Hủy - chọn key khác' -ForegroundColor Gray
    $c = Read-Host '  Chọn'
    Show-Banner
    if ($c -ne '1') { return }
    Write-Warn 'LƯU Ý: Nâng phiên bản (vd Home->Pro) thường được hỗ trợ tại chỗ.'
    Write-Warn 'Hạ phiên bản (vd Pro->Home) thường không được hỗ trợ tại chỗ và có thể phải cài lại Windows.'
    if (-not (Ask-Confirm 'Xác nhận thử đổi phiên bản bằng changepk.exe?' 'DOIPB')) { return }

    Start-Checklist -Title 'ĐỔI PHIÊN BẢN WINDOWS CHO KHỚP KEY' -Steps @(
        'Ghi nhận phiên bản hiện tại (để đối chiếu sau)',
        'Gọi changepk.exe với key đích',
        'Kiểm tra phiên bản sau khi đổi'
    )

    [void](Start-Step)
    Add-StepDetail "EditionID trước khi đổi: $curEd"
    Add-StepDetail "Tên phiên bản: $($Script:WinInfo.ProductName) (build $($Script:WinInfo.Build))"
    Complete-Step -Status DAT

    [void](Start-Step -Note 'changepk.exe là công cụ chính thức của Windows để đổi phiên bản bằng key')
    $called = $false
    try {
        Add-StepDetail "Lệnh: changepk.exe /ProductKey $(Mask-Key $Key)"
        Start-Process -FilePath 'changepk.exe' -ArgumentList "/ProductKey $Key" -Wait -ErrorAction Stop
        Add-StepDetail 'changepk.exe đã chạy xong' 'Green'
        $called = $true
        Complete-Step -Status DAT
    } catch {
        Add-StepDetail "Không gọi được changepk.exe: $_" 'Red'
        Complete-Step -Status LOI -Note 'Không chạy được changepk.exe'
    }

    [void](Start-Step -Note 'Đọc lại registry để xác nhận phiên bản đã đổi hay chưa')
    $after = Get-WindowsInfo
    Add-StepDetail "EditionID sau khi đổi: $($after.EditionID)"
    if ($called -and $after.EditionID -ne $curEd) {
        Add-StepDetail "Đã đổi phiên bản: $curEd -> $($after.EditionID)" 'Green'
        $Script:WinInfo = $after
        Complete-Step -Status DAT -Note "Đổi thành công sang $($after.EditionID)"
    } else {
        Add-StepDetail 'Phiên bản chưa thay đổi.' 'Yellow'
        Add-StepDetail 'Thường gặp khi HẠ phiên bản (vd Pro -> Home): Windows không hỗ trợ hạ tại chỗ.' 'Yellow'
        Add-StepDetail 'Cách xử lý: cài lại Windows đúng phiên bản của key, sau đó chạy lại công cụ này.' 'Yellow'
        Complete-Step -Status LUUY -Note 'Chưa đổi được phiên bản - có thể cần cài lại Windows'
    }
}

function Invoke-Reactivate-Office {
    Write-Sub 'KÍCH HOẠT LẠI OFFICE'
    Write-Plain 'Sau khi gỡ Ohook/KMS, Office sẽ ở trạng thái chưa kích hoạt nếu không có giấy phép hợp lệ.'
    Write-Host '   [1] Nhập key Office hợp pháp (Retail/MAK)' -ForegroundColor White
    Write-Host '   [2] Đăng nhập tài khoản Microsoft/M365 (thực hiện thủ công trong ứng dụng Office)' -ForegroundColor White
    Write-Host '   [3] Để ở trạng thái chưa kích hoạt' -ForegroundColor White
    Write-Host '   [0] Quay lại' -ForegroundColor Gray
    $c = Read-Host '  Chọn'
    # Sau khi chon, mo TRANG MOI cho ket qua cua lua chon (thay vi noi tiep ben duoi menu cu).
    Show-Banner
    switch ($c) {
        '1' {
            $key = Read-Host '  Nhập key Office 25 ký tự'
            $Script:ScanFresh = $false
            Start-Checklist -Title 'KÍCH HOẠT OFFICE BẰNG KEY' -Steps @(
                'Kiểm tra định dạng key & sản phẩm Office đang cài',
                'Kiểm tra kết nối tới máy chủ kích hoạt',
                'Cài key vào hệ thống',
                'Gửi yêu cầu kích hoạt trực tuyến',
                'Xác minh trạng thái Office sau khi thực hiện'
            )

            [void](Start-Step)
            if ($key -notmatch '^[A-Za-z0-9]{5}(-[A-Za-z0-9]{5}){4}$') {
                Add-StepDetail 'Key không đúng định dạng XXXXX-XXXXX-XXXXX-XXXXX-XXXXX' 'Red'
                Complete-Step -Status LOI -Note 'Định dạng key không hợp lệ'
                return
            }
            Add-StepDetail ("Key sẽ dùng: {0}" -f (Mask-Key $key)) 'Magenta'
            foreach ($p in @($Script:OffProds) + @($Script:Off14)) { Add-StepDetail ("Đang cài: {0} (kênh {1})" -f $p.Name, $p.ProductKeyChannel) }
            Complete-Step -Status DAT

            [void](Start-Step)
            $net = Test-Internet
            if ($net) { Add-StepDetail 'Có kết nối Internet' 'Green'; Complete-Step -Status DAT }
            else { Add-StepDetail 'KHÔNG có kết nối Internet' 'Yellow'; Complete-Step -Status LUUY -Note 'Không có mạng' }

            # Office 2013+ dung slmgr; Office 2010 dung ospp.vbs
            [void](Start-Step -Note 'Office 2013 trở lên dùng chung nền tảng SPP với Windows (slmgr)')
            $r = Install-ProductKeySafe -Key $key
            $err = Show-ActivationError $r
            if ($err) {
                Add-StepDetail "Hệ thống từ chối key. Mã lỗi: $err" 'Red'
                Complete-Step -Status LOI -Note "Cài key thất bại ($err)"
                if ($err -eq '0xC004F069') {
                    Write-Host ''
                    Write-Warn 'Key không khớp sản phẩm/phiên bản Office đang cài.'
                    Write-Plain 'Cần cài lại Office đúng phiên bản (dùng Office Deployment Tool), rồi nhập lại key.'
                    Write-Plain 'Ví dụ: dùng ODT setup.exe /configure <tệp cấu hình>.xml để cài đúng phiên bản.'
                }
                return
            }
            Add-StepDetail 'Đã cài key vào hệ thống' 'Green'
            Complete-Step -Status DAT

            [void](Start-Step)
            if (-not $net) { Add-StepDetail 'Bỏ qua vì không có Internet' 'Yellow'; Complete-Step -Status BOQUA -Note 'Không có mạng' }
            else {
                $ato = cscript //nologo "$env:windir\System32\slmgr.vbs" /ato 2>&1 | Out-String
                $errA = Show-ActivationError $ato
                if ($errA) { Add-StepDetail "Máy chủ trả về lỗi: $errA" 'Red'; Complete-Step -Status LOI -Note "Kích hoạt thất bại ($errA)" }
                else { Add-StepDetail 'Máy chủ chấp nhận yêu cầu kích hoạt' 'Green'; Complete-Step -Status DAT }
            }

            [void](Start-Step -Note 'Đọc lại WMI để xác nhận trạng thái thực tế')
            Start-Sleep -Seconds 2
            $Script:OffProds = Get-LicenseProducts $Script:OFFICE_APPID
            $Script:Off14    = Get-Office14Products
            try { $Script:OfficeRegKeys = @(Get-OfficeRegistryProductKeys) } catch { $Script:OfficeRegKeys = @() }
            $actO = @($Script:OffProds) + @($Script:Off14) | Where-Object { $_.LicenseStatus -eq 1 } | Select-Object -First 1
            if ($actO) {
                Add-StepDetail ("Đã kích hoạt: {0} (kênh {1})" -f $actO.Name, $actO.ProductKeyChannel) 'Green'
                Complete-Step -Status DAT -Note 'Office đã kích hoạt'
            } else {
                Add-StepDetail 'Office chưa ở trạng thái đã kích hoạt' 'Yellow'
                Complete-Step -Status LUUY -Note 'Chưa kích hoạt'
            }
        }
        '2' {
            Start-Checklist -Title 'KÍCH HOẠT OFFICE BẰNG TÀI KHOẢN MICROSOFT/M365' -Steps @(
                'Kiểm tra Office đã cài trên máy'
            )
            [void](Start-Step)
            $inv = @($Script:OffProds) + @($Script:Off14)
            if (@($inv).Count -eq 0) { Add-StepDetail 'Không đọc được sản phẩm Office nào' 'Yellow'; Complete-Step -Status LUUY }
            else { foreach ($p in $inv) { Add-StepDetail $p.Name }; Complete-Step -Status DAT -Note "$(@($inv).Count) sản phẩm" }

            # Huong dan hien thi TRUC TIEP tren man hinh (khong qua Add-StepDetail - xem giai
            # thich tuong tu o nhanh Digital License cua Invoke-Reactivate-Windows).
            Write-Host ''
            Write-Host '  --- HƯỚNG DẪN ĐĂNG NHẬP TÀI KHOẢN MICROSOFT/M365 ---' -ForegroundColor Cyan
            Write-Plain '   1. Mở Word hoặc Excel'
            Write-Plain '   2. Vào File > Account (Tài khoản)'
            Write-Plain '   3. Bấm Sign in (Đăng nhập), dùng tài khoản có gán giấy phép Microsoft 365/Office'
            Write-Plain '   4. Sau khi đăng nhập, Office sẽ tự lấy giấy phép nếu tài khoản có quyền'
            Pause-Return
            # Bao cho tang goi (Invoke-Handle-Target / Show-ConclusionMenu) biet can quet lai
            # NGAY tu dau nhu vua mo script - xem co che $Script:ForceRescanNow o Show-ConclusionMenu.
            $Script:ForceRescanNow = $true
        }
        '3' {
            Write-Info 'Để Office ở trạng thái chưa kích hoạt.'
            Write-Plain 'Office vẫn mở được tệp ở chế độ chỉ xem, cho tới khi bạn cung cấp giấy phép hợp lệ.'
        }
        default { return }
    }
}

# =============================================================================
#  DIEU PHOI GO BO THEO DOI TUONG
# =============================================================================
function Invoke-Handle-Target {
    param([ValidateSet('Windows','Office')] [string]$Target)

    $v = Show-TargetReport -Target $Target
    Write-Host ''
    Write-Host '  --- HÀNH ĐỘNG ---' -ForegroundColor Cyan

    if ($v.Verdict -eq 'VIOLATION' -or $v.Verdict -eq 'SUSPECT') {
        if ($v.Verdict -eq 'SUSPECT') {
            Write-Plain 'Trạng thái nghi vấn: hãy đối chiếu với giấy tờ (hợp đồng/hóa đơn) trước. Nếu xác định là crack, chọn gỡ bỏ.'
        }
        Write-Host '   [1] Gỡ bỏ can thiệp + xóa dấu vết + kích hoạt lại (đầy đủ)' -ForegroundColor White
        Write-Host '   [2] Chỉ xóa dấu vết tồn dư' -ForegroundColor White
        Write-Host '   [0] Quay lại (chưa xử lý)' -ForegroundColor Gray
        $c = Read-Host '  Chọn'
        Show-Banner
        if ($c -eq '1') { Invoke-Remove-Full -Verdict $v -Target $Target }
        elseif ($c -eq '2') { Invoke-Remove-CleanOnly -Verdict $v -Target $Target }
        else { return $false }
        return $true
    }
    elseif ($v.Verdict -in @('RESIDUAL_LEGIT','RESIDUAL')) {
        Write-Host '   [1] Xóa dấu vết tồn dư' -ForegroundColor White
        Write-Host '   [0] Quay lại (chưa xử lý)' -ForegroundColor Gray
        $c = Read-Host '  Chọn'
        Show-Banner
        if ($c -eq '1') { Invoke-Remove-CleanOnly -Verdict $v -Target $Target; return $true }
        return $false
    }
    else {
        Write-Good "$Target sạch về kỹ thuật. Không có gì để gỡ."
        # Chi moi "chua kich hoat" khi thuc su BIET chac trang thai (khong phai truong hop
        # khong doc duoc giay phep vNext cua Office - VNextUnknown - vi luc do KHONG the
        # khang dinh la chua kich hoat, hoi lai se gay hieu lam nhu bao cao ban dau.
        if ($v.State.Status -ne 1 -and -not $v.State.VNextUnknown) {
            if (Ask-YesNo "$Target chưa kích hoạt. Bạn có muốn kích hoạt lại bây giờ?" -DefaultNo) {
                if ($Target -eq 'Windows') { Invoke-Reactivate-Windows } else { Invoke-Reactivate-Office }
                # Neu nhanh Digital License vua yeu cau quet lai ngay (ForceRescanNow), KHONG
                # Nhan Enter o day nua - de tang goi Show-ConclusionMenu quet lai luon, tranh
                # mot buoc dung thua truoc khi trang moi hien ra.
                if (-not $Script:ForceRescanNow) { Pause-Return }
                return $true
            }
        }
        Pause-Return
        return $false
    }
}

function Invoke-Remove-Full {
    param($Verdict, [string]$Target)
    Write-Host ''
    Write-Warn "Bạn sắp gỡ bỏ can thiệp trên $Target và có thể kích hoạt lại."
    Write-Plain 'Trình tự sẽ thực hiện (mỗi giai đoạn có danh sách công việc riêng, báo tiến độ và kết quả từng bước):'
    Write-Host '     Giai đoạn 1: Sao lưu trạng thái cấp phép ra Desktop' -ForegroundColor White
    Write-Host '     Giai đoạn 2: Gỡ cơ chế & xóa dấu vết' -ForegroundColor White
    Write-Host '     Giai đoạn 3: Dọn cấu hình cấp phép còn lại (KMS, key bất hợp pháp)' -ForegroundColor White
    Write-Host '     Giai đoạn 4: Kích hoạt lại (tùy chọn)' -ForegroundColor White
    Write-Host '     Giai đoạn 5: Quét lại để kiểm chứng kết quả' -ForegroundColor White
    Write-Plain 'Nếu key hiện tại thật ra là hợp lệ, bạn vẫn có bản sao lưu để khôi phục.'
    if (-not (Ask-Confirm "Xác nhận gỡ bỏ đầy đủ trên $Target?" 'GOBO')) { Write-Info 'Đã hủy.'; return }

    # --- Giai doan 1: sao luu ------------------------------------------------
    Write-Title "GIAI ĐOẠN 1/5 - SAO LƯU TRƯỚC KHI THAY ĐỔI ($Target)"
    $backupDir = Backup-LicenseState

    # --- Giai doan 2: go co che & dau vet ------------------------------------
    Write-Title "GIAI ĐOẠN 2/5 - GỠ CƠ CHẾ & XÓA DẤU VẾT ($Target)"
    # Go tat ca phat hien (active + artifact) cua doi tuong, TRU nhom can-xac-minh
    $toRemove = $Verdict.AllFindings | Where-Object { -not $_.Verify }
    Write-Plain "Số phát hiện sẽ xử lý: $(@($toRemove).Count) (đã loại trừ $(@($Verdict.NeedVerify).Count) mục thuộc nhóm cần xác minh)"
    Invoke-RemoveFindings -Findings $toRemove -IncludeActiveConfig

    # --- Giai doan 3: don cau hinh cap phep ----------------------------------
    Write-Title "GIAI ĐOẠN 3/5 - DỌN CẤU HÌNH CẤP PHÉP CÒN LẠI ($Target)"
    if ($Target -eq 'Windows') {
        $hasTs = @($Verdict.AllFindings | Where-Object { $_.Method -match '(?i)TSforge|KMS4k|KMS38' }).Count -gt 0
        $st = $Verdict.State
        Start-Checklist -Title 'DỌN CẤU HÌNH CẤP PHÉP WINDOWS' -Steps @(
            'Xóa cấu hình máy chủ KMS (slmgr /ckms, /ckhc + registry)',
            'Gỡ key Volume/GVLK bất hợp pháp khỏi hệ thống',
            'Xử lý dữ liệu giả trong kho giấy phép (TSforge/KMS38)'
        )

        [void](Start-Step -Note 'Bao gồm cả giá trị 127.0.0.2 do TSforge ghi vào khóa con của từng sản phẩm')
        $nRem = Clear-KmsConfiguration
        Complete-Step -Status DAT -Note "Đã xóa $nRem giá trị KMS trong registry"

        [void](Start-Step -Note 'Chỉ gỡ khi key hiện tại là Volume/GVLK - KHÔNG đụng vào key OEM/Retail')
        if ($st.IsVolumeGvlk -and $st.Status -eq 1) {
            Add-StepDetail "Key hiện tại thuộc kênh: $($st.Channel) (Volume/GVLK) - sẽ gỡ"
            cscript //nologo "$env:windir\System32\slmgr.vbs" /upk 2>&1 | Out-Null
            cscript //nologo "$env:windir\System32\slmgr.vbs" /cpky 2>&1 | Out-Null
            Add-StepDetail 'Đã gỡ key khỏi hệ thống và xóa key khỏi registry (slmgr /upk, /cpky)' 'Green'
            Complete-Step -Status DAT -Note 'Đã gỡ key Volume/GVLK'
        } else {
            Add-StepDetail "Key hiện tại thuộc kênh: $($st.Channel) - KHÔNG phải Volume/GVLK nên giữ nguyên" 'Green'
            Complete-Step -Status BOQUA -Note 'Không có key Volume/GVLK cần gỡ'
        }

        [void](Start-Step -Note 'TSforge ghi dữ liệu giả vào data.dat/tokens.dat - xóa tệp riêng lẻ không đủ')
        if (-not $hasTs) {
            Add-StepDetail 'Không phát hiện TSforge/KMS4k/KMS38 trên máy này' 'Green'
            Complete-Step -Status BOQUA -Note 'Không cần tái tạo kho SPP'
        } else {
            Add-StepDetail 'ĐÃ phát hiện TSforge/KMS38 - cần tái tạo kho giấy phép SPP để xóa triệt để' 'Red'
            Complete-Step -Status LUUY -Note 'Cần xác nhận của bạn để tái tạo kho SPP'
            Write-Host ''
            Write-Warn 'Phát hiện TSforge/KMS38 - dữ liệu giả nằm trong kho giấy phép, không thể chỉ xóa tệp.'
            if (Ask-YesNo 'Tái tạo kho giấy phép SPP để xóa triệt để?') { Reset-SppStore }
            else { Write-Warn 'Bạn đã chọn KHÔNG tái tạo kho SPP. Dữ liệu giả của TSforge vẫn còn trong kho.' }
        }
    } else {
        Start-Checklist -Title 'DỌN CẤU HÌNH CẤP PHÉP OFFICE' -Steps @(
            'Xóa cấu hình máy chủ KMS của Office',
            'Gỡ key Volume của các sản phẩm Office'
        )
        [void](Start-Step)
        $nRem = Clear-KmsConfiguration
        Complete-Step -Status DAT -Note "Đã xóa $nRem giá trị KMS trong registry"

        [void](Start-Step -Note 'Chỉ gỡ sản phẩm Office đang kích hoạt bằng key Volume')
        $volProds = @($Script:OffProds | Where-Object { $_.ProductKeyChannel -match '(?i)Volume' -and $_.LicenseStatus -eq 1 })
        if ($volProds.Count -eq 0) { Add-StepDetail 'Không có sản phẩm Office nào dùng key Volume' 'Green'; Complete-Step -Status BOQUA }
        else {
            foreach ($p in $volProds) {
                cscript //nologo "$env:windir\System32\slmgr.vbs" /upk $p.ID 2>&1 | Out-Null
                Add-StepDetail "Đã gỡ key Volume của: $($p.Name)" 'Green'
            }
            Complete-Step -Status DAT -Note "Đã gỡ $($volProds.Count) key Volume"
        }
    }

    Write-Host ''
    Write-Good "Đã hoàn tất gỡ bỏ trên $Target. Bản sao lưu: $backupDir"

    # --- Giai doan 4: kich hoat lai ------------------------------------------
    Write-Title "GIAI ĐOẠN 4/5 - KÍCH HOẠT LẠI ($Target)"
    if (Ask-YesNo "Kích hoạt lại $Target bây giờ?") {
        if ($Target -eq 'Windows') { Invoke-Reactivate-Windows } else { Invoke-Reactivate-Office }
    } else {
        Write-Info "Bỏ qua bước kích hoạt lại. Bạn có thể quay lại menu để làm sau."
    }

    # --- Giai doan 5: kiem chung --------------------------------------------
    Write-Title "GIAI ĐOẠN 5/5 - QUÉT LẠI ĐỂ KIỂM CHỨNG KẾT QUẢ"
    Write-Plain 'Quét lại toàn hệ thống để xác nhận các dấu hiệu đã được xử lý.'
    Invoke-FullScan
    # Giai doan nay da tu quet lai roi - neu nhanh dang nhap Digital License o Giai doan 4 vua
    # bao can quet lai (ForceRescanNow), bo qua de tang goi khong quet THEM mot lan nua thua.
    $Script:ForceRescanNow = $false
    $vAfter = Get-TargetVerdict -Target $Target
    Write-Host ''
    Write-Host "   Kết luận $Target sau khi xử lý: " -NoNewline -ForegroundColor White
    Write-Host $vAfter.Label -ForegroundColor (Get-VerdictColor $vAfter.Verdict)
    if ($vAfter.Verdict -ne 'CLEAN') {
        Write-Warn 'Vẫn còn dấu hiệu. Một số tệp/dịch vụ chỉ xóa được sau khi khởi động lại máy - hãy khởi động lại rồi chạy lại công cụ.'
    }
    Write-Host ''
    Write-Warn 'Nên KHỞI ĐỘNG LẠI máy để áp dụng đầy đủ thay đổi.'
    Pause-Return
}

function Invoke-Remove-CleanOnly {
    param($Verdict, [string]$Target)
    Write-Host ''
    Write-Info "Chế độ chỉ dọn dấu vết: GIỮ NGUYÊN key và kho giấy phép hiện tại."
    Write-Plain 'Chỉ xóa: thư mục/tệp công cụ, tác vụ, dịch vụ, ngoại lệ Defender, dòng hosts/lịch sử liên quan crack.'
    Write-Plain 'Trình tự: (1) Sao lưu -> (2) Dọn dấu vết -> (3) Quét lại kiểm chứng.'
    # Canh bao ohook: neu Office dang kich hoat NHO ohook, xoa se mat kich hoat
    if ($Target -eq 'Office' -and ($Verdict.AllFindings | Where-Object { $_.Method -eq 'Ohook' })) {
        Write-Warn 'Phát hiện Ohook. Nếu Office đang kích hoạt chỉ nhờ Ohook (không có giấy phép thật bên dưới),'
        Write-Warn 'việc xóa sẽ làm Office trở lại chưa kích hoạt. Hãy chắc chắn bạn đã có giấy phép Office hợp lệ.'
        if (-not (Ask-YesNo 'Vẫn tiếp tục xóa ohook?' -DefaultNo)) { return }
    }
    if (-not (Ask-Confirm "Xác nhận chỉ dọn dấu vết tồn dư trên $Target?" 'DON')) { Write-Info 'Đã hủy.'; return }

    Write-Title "GIAI ĐOẠN 1/3 - SAO LƯU TRƯỚC KHI THAY ĐỔI ($Target)"
    $backupDir = Backup-LicenseState

    Write-Title "GIAI ĐOẠN 2/3 - DỌN DẤU VẾT TỒN DƯ ($Target)"
    # Chi go phat hien KHONG phai co che dang hoat dong (tru khi la ohook da xac nhan o tren),
    # va khong dung vao nhom can-xac-minh (KMS doanh nghiep...).
    $residual = $Verdict.AllFindings | Where-Object {
        (-not $_.Verify) -and
        ((-not (Test-ActiveIllegit $_)) -or ($_.Method -eq 'Ohook'))
    }
    Write-Plain "Số dấu vết sẽ dọn: $(@($residual).Count). Không đụng đến cấu hình cấp phép đang có hiệu lực."
    Invoke-RemoveFindings -Findings $residual

    Write-Title "GIAI ĐOẠN 3/3 - QUÉT LẠI ĐỂ KIỂM CHỨNG"
    Invoke-FullScan
    $vAfter = Get-TargetVerdict -Target $Target
    Write-Host ''
    Write-Host "   Kết luận $Target sau khi dọn: " -NoNewline -ForegroundColor White
    Write-Host $vAfter.Label -ForegroundColor (Get-VerdictColor $vAfter.Verdict)
    Write-Host ''
    Write-Good "Đã dọn dấu vết tồn dư trên $Target. Bản sao lưu: $backupDir"
    Pause-Return
}

# =============================================================================
#  GIAO DIEN CHINH
# =============================================================================
function Show-Banner {
    Clear-Host
    Write-Host ''
    Write-Host '  ================================================================' -ForegroundColor Cyan
    Write-Host '   CÔNG CỤ RÀ QUÉT & KHÔI PHỤC BẢN QUYỀN WINDOWS / OFFICE' -ForegroundColor Cyan
    Write-Host "   Phiên bản $($Script:VERSION) ($($Script:BUILDDATE))" -ForegroundColor Cyan
    Write-Host "   Tác giả: tiennn.ict   -   GitHub: github.com/tiennnict/license.info.vn" -ForegroundColor DarkCyan
    Write-Host '  ================================================================' -ForegroundColor Cyan
    Write-Host '   Script chỉ xác định có hay không có việc can thiệp kỹ thuật.' -ForegroundColor Gray
    Write-Host '   Bản quyền hợp pháp phụ thuộc vào các giấy tờ chứng minh nguồn gốc key kích hoạt' -ForegroundColor Gray
    Write-Host '  ================================================================' -ForegroundColor Cyan
}

function Get-VerdictColor { param($V) switch ($V) { 'VIOLATION'{'Red'} 'SUSPECT'{'Yellow'} 'RESIDUAL_LEGIT'{'Yellow'} 'RESIDUAL'{'Yellow'} default{'Green'} } }

function Start-FreshScanPage {
    # Mo MOT TRANG MOI (Clear-Host) roi chay Invoke-FullScan tren trang do - giong het luc
    # khoi dong chuong trinh. Dung cho MOI lan bat dau mot luot quet lai tu dau (chon "Quet
    # lai toan bo", hoac tu dong quet lai sau khi da xu ly xong ca Windows+Office), de danh
    # sach quet MOI khong bi noi vao duoi noi dung cu (checklist/ket luan cua lan truoc).
    param([string]$Message = 'Bắt đầu rà quét Windows và Office...')
    Show-Banner
    Write-Host ''
    Write-Info $Message
    Invoke-FullScan
}

function Show-ConclusionMenu {
    # -SkipBanner: khong Clear-Host/ve lai banner o LAN DAU vao vong lap - dung ngay sau
    # khi mot lan quet (Invoke-FullScan, qua Start-FreshScanPage) vua chay xong TREN TRANG
    # VUA MO, de checklist + ket luan + menu noi tiep nhau tren CUNG MOT trang (khong can
    # Nhan Enter giua chung). Cac lan lap sau cua vong lap (sau khi da Nhan Enter o mot
    # buoc nao do) van Clear-Host binh thuong vi do la mot lan quay-lai-dashboard hop le.
    param([switch]$SkipBanner)
    $handledWin = $false; $handledOff = $false
    $skipBanner = [bool]$SkipBanner
    while ($true) {
        $vw = Get-TargetVerdict -Target 'Windows'
        $vo = Get-TargetVerdict -Target 'Office'
        if ($skipBanner) { $skipBanner = $false } else { Show-Banner }
        Write-Host ''
        Write-Host '   KẾT LUẬN' -ForegroundColor White
        Write-Host '  ----------------------------------------------------------------' -ForegroundColor DarkGray
        Write-Host '   Windows : ' -NoNewline -ForegroundColor White
        Write-Host $vw.Label -ForegroundColor (Get-VerdictColor $vw.Verdict)
        Write-Host '   Office  : ' -NoNewline -ForegroundColor White
        Write-Host $vo.Label -ForegroundColor (Get-VerdictColor $vo.Verdict)
        Write-Host '  ----------------------------------------------------------------' -ForegroundColor DarkGray
        Write-Host ''
        Write-Host "   [1] Xem chi tiết & xử lý Windows $(if($handledWin){'(đã xử lý)'})" -ForegroundColor $(if($handledWin){'DarkGray'}else{'White'})
        Write-Host "   [2] Xem chi tiết & xử lý Office  $(if($handledOff){'(đã xử lý)'})" -ForegroundColor $(if($handledOff){'DarkGray'}else{'White'})
        Write-Host '   [3] Quét lại toàn bộ' -ForegroundColor White
        Write-Host '   [Q] Thoát' -ForegroundColor White
        Write-Host ''
        $c = Read-Host '  Chọn'
        # Sau khi chon, mo TRANG MOI cho ket qua cua lua chon (thay vi noi tiep ben duoi menu cu).
        # Voi lua chon 3 (quet lai) thi Start-FreshScanPage tu no cung Show-Banner - goi them o
        # day khong sai, chi ve lai banner 2 lan lien nhau, khong mat noi dung.
        Show-Banner
        switch ($c) {
            '1' { if (Invoke-Handle-Target -Target 'Windows') { $handledWin = $true } }
            '2' { if (Invoke-Handle-Target -Target 'Office')  { $handledOff = $true } }
            '3' {
                # "Quét lại toàn bộ" = mở TRANG MỚI (như lúc khởi động), không nối vào cuối
                # trang đang có sẵn. Trên trang mới đó, checklist + kết luận + menu vẫn nối
                # liền nhau (không Nhấn Enter giữa chừng) nhờ $skipBanner.
                Start-FreshScanPage -Message 'Đang quét lại toàn bộ...'
                $handledWin = $false; $handledOff = $false
                $skipBanner = $true
            }
            'Q' { return }
            default { }
        }
        # Nhanh dang nhap lay Digital License (trong Invoke-Reactivate-Windows/Office) da bao
        # can quet lai NGAY tu dau - uu tien xu ly truoc, bo qua kiem tra "da xu ly ca hai" ben
        # duoi de tranh quet lai 2 lan lien tiep.
        if ($Script:ForceRescanNow) {
            $Script:ForceRescanNow = $false
            Start-FreshScanPage -Message 'Đang quét lại toàn bộ sau khi đăng nhập lấy Digital License...'
            $handledWin = $false; $handledOff = $false
            $skipBanner = $true
        }
        # Neu da xu ly ca hai -> tu dong quet lai (bo qua neu vua quet lai xong o buoc xu ly)
        elseif ($handledWin -and $handledOff) {
            Write-Host ''
            if ($Script:ScanFresh) {
                Write-Info 'Đã xử lý cả Windows và Office. Kết quả bên dưới là dữ liệu vừa quét lại sau khi xử lý.'
                Pause-Return
                Show-Banner
                $skipBanner = $true
            } else {
                Write-Info 'Đã xử lý cả Windows và Office. Tự động quét lại để kiểm tra kết quả...'
                Pause-Return
                Start-FreshScanPage -Message 'Đang quét lại toàn bộ...'
                $skipBanner = $true
            }
            $handledWin = $false; $handledOff = $false
        }
    }
}

# =============================================================================
#  DIEM VAO
# =============================================================================
Start-FreshScanPage
# Giao dien ra quet chi co 1 trang: khong "Nhan Enter" o day - noi tiep thang ket luan+menu
Show-ConclusionMenu -SkipBanner

Write-Host ''
Write-Good 'Kết thúc. Cảm ơn bạn đã sử dụng công cụ.'
Write-Plain 'Nhắc lại: nếu cần chứng minh bản quyền hợp pháp, hãy chuẩn bị hợp đồng/hóa đơn mua sắm.'
Write-Dim   'Góp ý / báo lỗi: https://github.com/tiennnict/license.info.vn/issues'
Write-Host ''


#!/bin/bash
# THDN-PrintServer 打印机自动检测和配置脚本
# 自动检测 USB 打印机并配置 CUPS

LOG_FILE="/var/log/cups/detect-printer.log"
PRINTER_CONFIG="/etc/cups/printers.conf"
CUPS_RESTARTED=0

# 日志函数
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"
}

# 检查 CUPS 服务
check_cups() {
    if ! /etc/init.d/cups status > /dev/null 2>&1; then
        log_info "CUPS 服务未运行，正在启动..."
        /etc/init.d/cups start
        sleep 3
    fi
}

# 检测 USB 打印机
detect_usb_printer() {
    log_info "开始检测 USB 打印机..."
    
    # 使用 lsusb 检测 USB 设备
    local usb_devices=$(lsusb 2>/dev/null | grep -i "printer\|hp\|canon\|epson\|brother" || true)
    
    if [ -n "$usb_devices" ]; then
        log_info "检测到 USB 设备:"
        echo "$usb_devices" | while read -r line; do
            log_info "  $line"
        done
        return 0
    else
        log_info "未检测到 USB 打印机设备"
        return 1
    fi
}

# 检测并配置 HP LaserJet 1020/1020plus
detect_hp_laserjet() {
    log_info "检测 HP LaserJet 1020/1020plus 打印机..."
    
    # 检查 USB 设备 ID
    local hp_1020_ids=("03f0:2b17" "03f0:1717")
    local detected=0
    
    for device_id in "${hp_1020_ids[@]}"; do
        if lsusb | grep -q "$device_id"; then
            log_info "检测到 HP LaserJet 1020/1020plus (ID: $device_id)"
            configure_hp_laserjet_1020
            detected=1
            break
        fi
    done
    
    if [ $detected -eq 0 ]; then
        log_info "未检测到 HP LaserJet 1020/1020plus"
        return 1
    fi
    
    return 0
}

# 配置 HP LaserJet 1020
configure_hp_laserjet_1020() {
    local printer_name="HP_LaserJet_1020"
    local printer_uri="usb://HP/LaserJet%201020"
    local printer_ppd="/usr/share/cups/model/HP_LaserJet_1020.ppd"
    
    log_info "配置 HP LaserJet 1020 打印机..."
    
    # 检查打印机是否已存在
    if lpstat -p "$printer_name" > /dev/null 2>&1; then
        log_info "HP LaserJet 1020 打印机已存在，跳过配置"
        return 0
    fi
    
    # 添加打印机
    if [ -f "$printer_ppd" ]; then
        lpadmin -p "$printer_name" -E -v "$printer_uri" -P "$printer_ppd" \
                -o printer-is-shared=true \
                -o job-sheets-default=none,none
        
        if [ $? -eq 0 ]; then
            log_info "HP LaserJet 1020 打印机配置成功"
            # 设置为默认打印机
            lpadmin -d "$printer_name"
            CUPS_RESTARTED=1
        else
            log_error "HP LaserJet 1020 打印机配置失败"
            return 1
        fi
    else
        log_error "PPD 文件不存在: $printer_ppd"
        return 1
    fi
    
    return 0
}

# 配置 HP LaserJet 1020plus
configure_hp_laserjet_1020plus() {
    local printer_name="HP_LaserJet_1020plus"
    local printer_uri="usb://HP/LaserJet%201020%20Plus"
    local printer_ppd="/usr/share/cups/model/HP_LaserJet_1020plus.ppd"
    
    log_info "配置 HP LaserJet 1020plus 打印机..."
    
    # 检查打印机是否已存在
    if lpstat -p "$printer_name" > /dev/null 2>&1; then
        log_info "HP LaserJet 1020plus 打印机已存在，跳过配置"
        return 0
    fi
    
    # 添加打印机
    if [ -f "$printer_ppd" ]; then
        lpadmin -p "$printer_name" -E -v "$printer_uri" -P "$printer_ppd" \
                -o printer-is-shared=true \
                -o job-sheets-default=none,none
        
        if [ $? -eq 0 ]; then
            log_info "HP LaserJet 1020plus 打印机配置成功"
            CUPS_RESTARTED=1
        else
            log_error "HP LaserJet 1020plus 打印机配置失败"
            return 1
        fi
    else
        log_error "PPD 文件不存在: $printer_ppd"
        return 1
    fi
    
    return 0
}

# 检测通用 USB 打印机
detect_generic_printer() {
    log_info "检测通用 USB 打印机..."
    
    # 检查 /dev/usb/lp* 设备
    local usb_devices=$(ls /dev/usb/lp* 2>/dev/null || true)
    
    if [ -n "$usb_devices" ]; then
        log_info "检测到 USB 打印设备:"
        for device in $usb_devices; do
            log_info "  $device"
            configure_generic_printer "$device"
        done
        return 0
    else
        log_info "未检测到通用 USB 打印设备"
        return 1
    fi
}

# 配置通用 USB 打印机
configure_generic_printer() {
    local device_path="$1"
    local printer_name="USB_Printer_$(basename "$device_path")"
    local printer_uri="usb://$(basename "$device_path")"
    
    log_info "配置通用 USB 打印机: $printer_name"
    
    # 检查打印机是否已存在
    if lpstat -p "$printer_name" > /dev/null 2>&1; then
        log_info "通用 USB 打印机 $printer_name 已存在，跳过配置"
        return 0
    fi
    
    # 使用通用 PPD 文件
    local generic_ppd="/usr/share/cups/model/generic.ppd"
    if [ ! -f "$generic_ppd" ]; then
        # 创建通用 PPD
        cat > "$generic_ppd" << 'EOF'
*PPD-Adobe: "4.3"
*FormatVersion: "4.3"
*FileVersion: "1.0"
*LanguageVersion: English
*LanguageEncoding: ISOLatin1
*PCFileName: "GENERIC.PPD"
*Product: "(Generic PostScript Printer)"
*Manufacturer: "Generic"
*ModelName: "Generic PostScript Printer"
*ShortNickName: "Generic PostScript"
*NickName: "Generic PostScript Printer"
*PSVersion: "(3010.000) 0"
*LanguageLevel: "3"
*ColorDevice: False
*DefaultColorSpace: Gray
*FileSystem: False
*Throughput: "1"
*LandscapeOrientation: Plus90
*VariablePaperSize: True
*TTRasterizer: Type42
*1284DeviceID: "MFG:Generic;MDL:PostScript Printer;CMD:POSTSCRIPT;"

*OpenUI *PageSize/Media Size: PickOne
*OrderDependency: 10 AnySetup *PageSize
*DefaultPageSize: A4
*PageSize A4/A4: "<</PageSize[595 842]/ImagingBBox null>>setpagedevice"
*PageSize Letter/US Letter: "<</PageSize[612 792]/ImagingBBox null>>setpagedevice"
*PageSize Legal/US Legal: "<</PageSize[612 1008]/ImagingBBox null>>setpagedevice"
*CloseUI: *PageSize

*OpenUI *PageRegion: PickOne
*OrderDependency: 10 AnySetup *PageRegion
*DefaultPageRegion: A4
*PageRegion A4/A4: "<</PageSize[595 842]/ImagingBBox null>>setpagedevice"
*PageRegion Letter/US Letter: "<</PageSize[612 792]/ImagingBBox null>>setpagedevice"
*PageRegion Legal/US Legal: "<</PageSize[612 1008]/ImagingBBox null>>setpagedevice"
*CloseUI: *PageRegion

*DefaultImageableArea: A4
*ImageableArea A4/A4: "0 0 595 842"
*ImageableArea Letter/US Letter: "0 0 612 792"
*ImageableArea Legal/US Legal: "0 0 612 1008"

*DefaultPaperDimension: A4
*PaperDimension A4/A4: "595 842"
*PaperDimension Letter/US Letter: "612 792"
*PaperDimension Legal/US Legal: "612 1008"

*OpenUI *InputSlot: PickOne
*OrderDependency: 15 AnySetup *InputSlot
*DefaultInputSlot: Auto
*InputSlot Auto/Auto: ""
*InputSlot Manual/Manual Feed: ""
*CloseUI: *InputSlot

*OpenUI *Duplex/Double-Sided Printing: PickOne
*OrderDependency: 25 AnySetup *Duplex
*DefaultDuplex: None
*Duplex None/Off: ""
*Duplex DuplexNoTumble/Long-Edge Binding: "<</Duplex true/Tumble false>>setpagedevice"
*Duplex DuplexTumble/Short-Edge Binding: "<</Duplex true/Tumble true>>setpagedevice"
*CloseUI: *Duplex

*DefaultOutputOrder: Reverse
*OutputOrder Normal/Normal: "(1) 0"
*OutputOrder Reverse/Reverse: "(1) 1"

*DefaultOutputBin: OnlyOne
*OutputBin OnlyOne/Only One: ""

*OpenUI *Staple: PickOne
*OrderDependency: 65 AnySetup *Staple
*DefaultStaple: None
*Staple None/Off: ""
*CloseUI: *Staple

*OpenUI *OutputMode: PickOne
*OrderDependency: 30 AnySetup *OutputMode
*DefaultOutputMode: Normal
*OutputMode Normal/Normal: ""
*CloseUI: *OutputMode

*% End of PPD file
EOF
    fi
    
    # 添加打印机
    lpadmin -p "$printer_name" -E -v "$printer_uri" -P "$generic_ppd" \
            -o printer-is-shared=true \
            -o job-sheets-default=none,none
    
    if [ $? -eq 0 ]; then
        log_info "通用 USB 打印机 $printer_name 配置成功"
        CUPS_RESTARTED=1
    else
        log_error "通用 USB 打印机 $printer_name 配置失败"
        return 1
    fi
    
    return 0
}

# 重启 CUPS 服务
restart_cups() {
    if [ $CUPS_RESTARTED -eq 1 ]; then
        log_info "重启 CUPS 服务..."
        /etc/init.d/cups restart
        sleep 2
        log_info "CUPS 服务重启完成"
    fi
}

# 显示打印机状态
show_printer_status() {
    log_info "当前打印机状态:"
    lpstat -p -d 2>/dev/null | while read -r line; do
        log_info "  $line"
    done
    
    # 显示默认打印机
    local default_printer=$(lpstat -d 2>/dev/null | grep "system default destination" | cut -d':' -f2 | xargs)
    if [ -n "$default_printer" ]; then
        log_info "默认打印机: $default_printer"
    fi
}

# 主函数
main() {
    log_info "开始打印机自动检测和配置..."
    
    # 创建日志目录
    mkdir -p /var/log/cups
    
    check_cups
    
    # 检测特定打印机
    detect_hp_laserjet
    
    # 检测通用打印机
    detect_generic_printer
    
    # 重启 CUPS 如果需要
    restart_cups
    
    # 显示状态
    show_printer_status
    
    log_info "打印机检测和配置完成"
}

# 如果直接运行此脚本
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi

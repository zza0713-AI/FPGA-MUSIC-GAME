# FPGA-MUSIC-GAME
vlsi数字系统设计大作业
# FPGA 音乐游戏 (FPGA Music Game)

基于 **Altera EP4CE115F23C7** FPGA 芯片的实时音乐游戏实现。

## 🎮 项目概述

这是一个完整的FPGA音乐游戏系统，支持：
- ✅ 实时4列音符下落显示（16×16 LED点阵屏）
- ✅ 自定义音乐谱面转换（从MP3/WAV到游戏格式）
- ✅ 实时得分显示（8位数码管）
- ✅ 可调节游戏难度（拨码开关）
- ✅ 暂停/继续和重置功能
- ✅ 多难度谱面支持

## 🛠️ 硬件配置

| 组件 | 规格 | 用途 |
|------|------|------|
| FPGA芯片 | EP4CE115F23C7 | 主控制器 |
| 按键 | F1~F10 | 游戏交互 |
| 拨码开关 | SW1~SW16 | 难度选择 |
| LED点阵 | 16×16 | 游戏显示 |
| 数码管 | 8位 | 得分显示 |

### 按键功能

- **F1~F4** - 击打四列音符
- **F5** - 暂停/继续
- **F6** - 重置游戏
- **F7~F10** - 预留功能

### 拨码开关

- **SW[3:0]** - 难度等级 (0=最低, 15=最高)
- **SW[4~15]** - 预留功能

## 📋 快速开始

### 前置要求

- Quartus II 或 Quartus Prime (支持EP4CE115)
- Python 3.7+
- 依赖库: `mido`, `numpy`

### 第一步：安装转换工具

```bash
cd tools
pip install -r requirements.txt
```

### 第二步：转换你的音乐

```bash
# 方案A: 使用Basic Pitch转换MP3为MIDI
pip install basic-pitch
basic-pitch output_dir/ your_song.mp3

# 方案B: 或者直接使用已有的MIDI文件
python midi_to_chart.py song.mid normal
```

### 第三步：集成到FPGA项目

1. 在Quartus中打开 `hardware/qsf/FPGA-Music-Game.qsf`
2. 将生成的谱面文件复制到 `hardware/charts/`
3. 编译项目
4. 烧录到开发板

### 第四步：运行游戏

1. 上电启动
2. 使用拨码开关选择难度
3. 按F5开始游戏
4. 用F1~F4击打音符
5. 按F6重置

## 📂 项目文件说明

### Verilog模块

- **music_game_top. v** - 顶层集成模块
- **clock_divider.v** - 多频率时钟分频器
- **game_controller.v** - 游戏状态管理
- **block_manager.v** - 音符生成和判定(随机模式)
- **block_manager_rom.v** - 音符加载(谱面模式)
- **led_matrix_driver.v** - 16×16点阵驱动
- **segment_display.v** - 8位数码管驱动

### Python工具

- **midi_to_chart.py** - 核心转换工具
  - 支持MIDI解析
  - 自动BPM检测
  - 多难度生成
  - 导出JSON/Verilog/HEX格式

## 🎵 音乐转换指南

详见 [MUSIC_CONVERSION.md](docs/MUSIC_CONVERSION. md)

### 快速流程

```
MP3/WAV音乐 
  ↓ (Basic Pitch)
MIDI文件(. mid)
  ↓ (midi_to_chart.py)
Verilog谱面文件(. v)
  ↓ (Quartus编译)
FPGA烧录
```

## 🎮 游戏机制

### 谱面数据格式

4列×16行的音符矩阵：
- 列0-3 对应LED点阵第2&3、6&7、10&11、14&15列
- 每个时间步(50ms)更新一次
- 音符从上往下下落
- 到底部时需按对应按键得分

### 得分规则

| 事件 | 得分 |
|------|------|
| 准时击打 | +1 |
| Miss(未击打) | +0 |
| 总分 | 显示在8位数码管 |

### 难度等级 (SW[3:0])

| 难度 | 下落速度 | 说明 |
|------|---------|------|
| 0-3 | 慢 | 易 |
| 4-7 | 中 | 中等 |
| 8-11 | 快 | 难 |
| 12-15 | 最快 | 极难 |

## 📊 系统架构

```
┌─────────────────────────────────────────┐
│         FPGA (EP4CE115F23C7)            │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   Clock Divider                  │  │
│  │   (多频率时钟分频)               │  │
│  └──────────────────────────────────┘  │
│           ↓                             │
│  ┌──────────────────────────────────┐  │
│  │   Game Controller                │  │
│  │   (状态管理)                     │  │
│  └──────────────────────────────────┘  │
│           ↓                             │
│  ┌──────────────────────────────────┐  │
│  │   Block Manager (ROM)            │  │
│  │   (音符生成和判定)               │  │
│  └──────────────────────────────────┘  │
│           ↓                             │
│  ┌──────────────────────────────────┐  │
│  │   LED Driver & Seg Driver        │  │
│  │   (输出驱动)                     │  │
│  └──────────────────────────────────┘  │
│                                         │
│  输入: F1~F10, SW1~SW16                 │
│  输出: 16×16 LED, 8位数码管            │
└─────────────────────────────────────────┘
```

## 📈 性能指标

| 指标 | 值 |
|------|-----|
| 系统时钟 | 50 MHz |
| LED刷新频率 | 1 kHz |
| 数码管扫描频率 | 500 Hz |
| 音符下落速度 | 1-4 Hz (可配) |
| 支持最大谱面长度 | ~65k步 (~55分钟) |
| 逻辑单元使用 | ~15% LE |

## 🐛 故障排除

### LED点阵不显示
- 检查引脚分配
- 验证LED驱动模块
- 查看时钟分频输出

### 数码管显示异常
- 检查段选信号
- 验证BCD码转换
- 确认位选扫描

### 音符不响应
- 检查按键去抖动设置
- 验证边沿检测逻辑
- 调整防抖延迟时间

## 📚 文档

- [设计文档](docs/DESIGN. md) - 详细的系统设计
- [使用指南](docs/USAGE.md) - 完整的使用说明
- [引脚分配](docs/PIN_ASSIGNMENT.md) - 硬件连接
- [音乐转换](docs/MUSIC_CONVERSION.md) - 音乐转换教程

## 🔧 开发工具

- **FPGA开发** - Quartus II / Quartus Prime
- **代码编辑** - VS Code + Verilog插件
- **仿真** - ModelSim / QuestaSim
- **音乐转换** - Python 3.7+

## 📝 许可证

MIT License

## 👨‍💻 作者

Zhang Zhiang (张志昂)
- GitHub: [@zza0713-AI](https://github.com/zza0713-AI)
- Email: zhang123456@buaa.edu.cn
- School: Beijing University of Aeronautics and Astronautics (BUAA)

## 🙏 致谢

- Altera/Intel 提供的FPGA平台
- Spotify 的 Basic Pitch 音频转换工具
- MIDI标准和开源社区

## 📞 支持

如有问题或建议，请：
1. 查看 [文档](docs/)
2. 检查 [FAQ](docs/USAGE.md#FAQ)
3. 提交 Issue

---

**最后更新**: 2025年11月30日

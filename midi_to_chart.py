#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MIDI to Music Game Chart Converter
将MIDI文件转换为FPGA音游谱面数据格式
Author: Zhang Zhiang
Date: 2025-11-30
"""

import mido
import json
import sys
import os
from typing import List, Tuple, Dict, Optional
from pathlib import Path

class MidiToChart:
    """MIDI转谱面的转换类"""
    
    def __init__(self, midi_file: str, bpm: float = 120, grid_size: int = 16):
        """
        初始化转换器
        :param midi_file: MIDI文件路径
        :param bpm: 每分钟拍数（用于时间转换）
        :param grid_size: 游戏网格大小（行数）
        """
        self.midi_file = midi_file
        self.bpm = bpm
        self.grid_size = grid_size
        self. ticks_per_beat = 480  # 标准MIDI分辨率
        self.mid = None
        self.chart = []  # 存储谱面事件
        
    def load_midi(self) -> bool:
        """加载MIDI文件"""
        try:
            self.mid = mido. MidiFile(self.midi_file)
            print(f"✓ 成功加载MIDI文件: {self.midi_file}")
            print(f"  格式: {self.mid.type}")
            print(f"  音轨数: {len(self. mid.tracks)}")
            return True
        except Exception as e:
            print(f"✗ 加载MIDI失败: {e}")
            return False
    
    def get_tempo(self) -> float:
        """从MIDI文件提取BPM"""
        for track in self.mid.tracks:
            for msg in track:
                if msg. type == 'set_tempo':
                    # tempo = 微秒/拍
                    bpm = 60_000_000 / msg.tempo
                    print(f"✓ 检测到BPM: {bpm:.2f}")
                    self.bpm = bpm
                    return bpm
        print(f"⚠ 未检测到BPM，使用默认值: {self.bpm}")
        return self.bpm
    
    def note_to_column(self, note_number: int) -> int:
        """
        将MIDI音符号转换为游戏列号(0-3)
        
        音符映射策略：
        - 按音符高度分配到4列
        - 可根据需要调整映射关系
        """
        # 方案1：按音符高度分配（推荐用于单旋律）
        if note_number < 64:     # 低于E4
            return 0
        elif note_number < 67:   # E4-G4
            return 1
        elif note_number < 70:   # G#4-B4
            return 2
        else:                    # C5及以上
            return 3
    
    def extract_notes(self) -> List[Dict]:
        """
        从MIDI提取所有音符事件
        返回格式: [{"time": 时间(s), "note": 音符号, "duration": 持续时间, "column": 列号}, ...]
        """
        notes = []
        
        for track_idx, track in enumerate(self. mid.tracks):
            current_time = 0
            
            for msg in track:
                current_time += msg.time
                
                if msg.type == 'note_on' and msg.velocity > 0:
                    # 计算时间（秒）
                    time_seconds = current_time / (self.ticks_per_beat * self.bpm / 60)
                    
                    # 记录音符
                    notes.append({
                        "time": time_seconds,
                        "note": msg. note,
                        "velocity": msg.velocity,
                        "column": self.note_to_column(msg.note),
                        "track": track_idx
                    })
        
        # 按时间排序
        notes.sort(key=lambda x: x["time"])
        
        print(f"✓ 提取了 {len(notes)} 个音符")
        if notes:
            print(f"  时间范围: {notes[0]['time']:.2f}s ~ {notes[-1]['time']:. 2f}s")
            print(f"  音符范围: C{min([n['note'] for n in notes])//12} ~ C{max([n['note'] for n in notes])//12}")
        
        return notes
    
    def generate_chart(self, notes: List[Dict], difficulty: str = "normal") -> List[List[int]]:
        """
        生成游戏谱面数据
        
        :param notes: 音符列表
        :param difficulty: 难度 ("easy", "normal", "hard")
        :return: 时间序列谱面数据
        """
        # 难度参数（影响显示速度和反应时间）
        difficulty_params = {
            "easy": {"spacing": 3, "description": "低难度-宽松节奏"},
            "normal": {"spacing": 2, "description": "中等难度-标准节奏"},
            "hard": {"spacing": 1, "description": "高难度-紧凑节奏"}
        }
        
        params = difficulty_params.get(difficulty, difficulty_params["normal"])
        spacing = params["spacing"]
        
        if not notes:
            print("✗ 没有音符，无法生成谱面")
            return []
        
        # 计算最大时间
        max_time = notes[-1]["time"]
        max_time += 5  # 留出额外时间
        
        # 创建二维数组：[时间步][列]
        # 每个时间步代表50ms (20 Hz 刷新率)
        time_step = 0.05
        steps = int(max_time / time_step)
        
        chart = [[0 for _ in range(4)] for _ in range(steps)]
        
        # 填充音符
        notes_placed = 0
        for note in notes:
            step_idx = int(note["time"] / time_step)
            column = note["column"]
            
            if 0 <= step_idx < steps and 0 <= column < 4:
                # 检查是否与前面的音符冲突（间距检查）
                conflict = False
                for prev_step in range(max(0, step_idx - spacing), step_idx):
                    if chart[prev_step][column] == 1:
                        conflict = True
                        break
                
                if not conflict:
                    chart[step_idx][column] = 1  # 1 表示该位置有音符
                    notes_placed += 1
        
        print(f"✓ 生成谱面: {steps} 个时间步，难度: {difficulty} ({params['description']})")
        print(f"  放置音符: {notes_placed}/{len(notes)}")
        print(f"  总时长: {steps * time_step:.2f}s")
        
        return chart
    
    def export_json(self, chart: List[List[int]], output_file: str = "chart. json") -> str:
        """导出为JSON格式（易于调试）"""
        data = {
            "metadata": {
                "bpm": self.bpm,
                "filename": self.midi_file,
                "grid_size": self. grid_size,
                "total_steps": len(chart),
                "duration_seconds": len(chart) * 0.05
            },
            "chart": chart
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json. dump(data, f, indent=2)
        
        print(f"✓ 导出JSON: {output_file}")
        return output_file
    
    def export_verilog_memory(self, chart: List[List[int]], 
                              output_file: str = "chart_memory.v") -> str:
        """
        导出为Verilog内存初始化格式
        生成可直接用于FPGA的内存数据
        """
        verilog_code = f"""// Verilog Memory Initialization File
// Auto-generated from {os.path.basename(self.midi_file)}
// BPM: {self.bpm:. 2f}
// Total steps: {len(chart)}
// Duration: {len(chart) * 0.05:.2f}s

module chart_rom (
    input [15:0] addr,
    output reg [3:0] data
);

    reg [3:0] rom [0:{len(chart)-1}];

    initial begin
"""
        
        # 生成内存初始化数据
        for idx, step in enumerate(chart):
            # 将4列打包成4位数据
            data = (step[3] << 3) | (step[2] << 2) | (step[1] << 1) | step[0]
            if idx % 8 == 0:  # 每8行注释一次
                verilog_code += f"\n        // 地址 {idx:04d} - {idx+7:04d}\n"
            verilog_code += f"        rom[{idx}] = 4'b{data:04b};\n"
        
        verilog_code += """    end

    always @(*) begin
        data = rom[addr];
    end

endmodule
"""
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f. write(verilog_code)
        
        print(f"✓ 导出Verilog ROM: {output_file}")
        return output_file
    
    def export_verilog_parameter(self, chart: List[List[int]], 
                                 output_file: str = "chart_params.v") -> str:
        """
        导出为Verilog参数形式（用于直接硬编码）
        """
        verilog_code = f"""// Verilog Parameter File
// Auto-generated from {os.path.basename(self.midi_file)}
// BPM: {self.bpm:.2f}
// Total steps: {len(chart)}

module chart_data #(
    parameter CHART_LENGTH = {len(chart)}
)(
    input [15:0] addr,
    output reg [3:0] data
);

    always @(*) begin
        case(addr)
"""
        
        # 生成case语句
        for idx, step in enumerate(chart):
            data = (step[3] << 3) | (step[2] << 2) | (step[1] << 1) | step[0]
            if data != 0:  # 只记录非零项（节省空间）
                verilog_code += f"            16'd{idx}: data = 4'b{data:04b};\n"
        
        verilog_code += """            default: data = 4'b0000;
        endcase
    end

endmodule
"""
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f. write(verilog_code)
        
        print(f"✓ 导出Verilog参数: {output_file}")
        return output_file
    
    def export_hex(self, chart: List[List[int]], output_file: str = "chart. hex") -> str:
        """
        导出为HEX格式（可用于Quartus II的IP核初始化）
        """
        with open(output_file, 'w') as f:
            for idx, step in enumerate(chart):
                # 将4列打包成4位数据
                data = (step[3] << 3) | (step[2] << 2) | (step[1] << 1) | step[0]
                f.write(f"{data:X}\n")
        
        print(f"✓ 导出HEX文件: {output_file}")
        return output_file
    
    def export_mif(self, chart: List[List[int]], output_file: str = "chart.mif") -> str:
        """
        导出为MIF格式（Quartus内存初始化文件）
        """
        mif_content = f"""WIDTH=4;
DEPTH={len(chart)};

ADDRESS_RADIX=HEX;
DATA_RADIX=HEX;

CONTENT BEGIN
"""
        
        for idx, step in enumerate(chart):
            data = (step[3] << 3) | (step[2] << 2) | (step[1] << 1) | step[0]
            mif_content += f"    {idx:04X}  :  {data:X};\n"
        
        mif_content += "END;\n"
        
        with open(output_file, 'w') as f:
            f.write(mif_content)
        
        print(f"✓ 导出MIF文件: {output_file}")
        return output_file
    
    def generate_statistics(self, chart: List[List[int]]) -> Dict:
        """生成谱面统计信息"""
        stats = {
            "total_steps": len(chart),
            "duration_seconds": len(chart) * 0.05,
            "notes_by_column": [0, 0, 0, 0],
            "max_concurrent": 0,
            "note_density": 0.0
        }
        
        total_notes = 0
        for step in chart:
            concurrent = sum(step)
            stats["max_concurrent"] = max(stats["max_concurrent"], concurrent)
            total_notes += concurrent
            for col in range(4):
                if step[col]:
                    stats["notes_by_column"][col] += 1
        
        stats["total_notes"] = total_notes
        stats["note_density"] = (total_notes / (len(chart) * 4) * 100) if chart else 0
        
        return stats
    
    def print_statistics(self, stats: Dict):
        """打印统计信息"""
        print("\n" + "="*60)
        print("谱面统计信息")
        print("="*60)
        print(f"总步数: {stats['total_steps']}")
        print(f"总时长: {stats['duration_seconds']:.2f}s")
        print(f"总音符数: {stats['total_notes']}")
        print(f"各列音符数: 列0={stats['notes_by_column'][0]}, "
              f"列1={stats['notes_by_column'][1]}, "
              f"列2={stats['notes_by_column'][2]}, "
              f"列3={stats['notes_by_column'][3]}")
        print(f"最大同时音符数: {stats['max_concurrent']}")
        print(f"音符密度: {stats['note_density']:.2f}%")
        print("="*60 + "\n")
    
    def convert(self, difficulty: str = "normal", output_dir: str = ". "):
        """完整的转换流程"""
        print("\n" + "="*60)
        print("MIDI 转 FPGA 音游谱面转换器 v1.0")
        print("="*60 + "\n")
        
        # 加载MIDI
        if not self.load_midi():
            return False
        
        # 提取BPM
        self.get_tempo()
        
        # 提取音符
        notes = self.extract_notes()
        if not notes:
            print("✗ 没有检测到音符！")
            return False
        
        # 生成谱面
        chart = self.generate_chart(notes, difficulty)
        if not chart:
            return False
        
        # 生成统计
        stats = self.generate_statistics(chart)
        self.print_statistics(stats)
        
        # 确保输出目录存在
        Path(output_dir).mkdir(parents=True, exist_ok=True)
        
        # 导出多种格式
        base_name = Path(self.midi_file).stem
        
        self.export_json(chart, f"{output_dir}/chart_{difficulty}. json")
        self.export_verilog_memory(chart, f"{output_dir}/chart_rom_{difficulty}.v")
        self.export_verilog_parameter(chart, f"{output_dir}/chart_data_{difficulty}.v")
        self.export_hex(chart, f"{output_dir}/chart_{difficulty}.hex")
        self. export_mif(chart, f"{output_dir}/chart_{difficulty}.mif")
        
        # 保存统计信息
        stats_file = f"{output_dir}/chart_{difficulty}_stats.json"
        with open(stats_file, 'w', encoding='utf-8') as f:
            json.dump(stats, f, indent=2)
        print(f"✓ 保存统计信息: {stats_file}")
        
        print("\n✓ 转换完成！\n")
        return True


def main():
    if len(sys.argv) < 2:
        print("用法: python midi_to_chart.py <MIDI文件> [难度] [输出目录]")
        print("\n难度选项: easy, normal, hard (默认: normal)")
        print("\n示例:")
        print("  python midi_to_chart.py song.mid")
        print("  python midi_to_chart.py song.mid hard")
        print("  python midi_to_chart.py song. mid normal ./output")
        sys.exit(1)
    
    midi_file = sys.argv[1]
    difficulty = sys.argv[2] if len(sys. argv) > 2 else "normal"
    output_dir = sys.argv[3] if len(sys.argv) > 3 else "."
    
    # 验证MIDI文件存在
    if not os.path.exists(midi_file):
        print(f"✗ MIDI文件不存在: {midi_file}")
        sys.exit(1)
    
    converter = MidiToChart(midi_file)
    success = converter.convert(difficulty, output_dir)
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

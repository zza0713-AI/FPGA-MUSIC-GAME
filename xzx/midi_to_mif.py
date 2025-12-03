#!/usr/bin/env python3
"""
MIDI转游戏资源转换器 - 交互式版本
避免Windows路径转义问题
"""

import mido
import numpy as np
import math
import sys
import os


class MIDIToGameAssets:
    def __init__(self, midi_file, bpm=None, audio_sample_rate=44100, game_step_ms=100):
        self.midi_file = midi_file
        try:
            self.midi = mido.MidiFile(midi_file)
        except Exception as e:
            raise Exception(f"无法读取MIDI文件: {e}")

        self.sample_rate = audio_sample_rate
        self.game_step_ms = game_step_ms

        if bpm is None:
            self.bpm = self.detect_bpm()
        else:
            self.bpm = bpm

        print(f"=== MIDI转换配置 ===")
        print(f"文件: {os.path.basename(midi_file)}")
        print(f"BPM: {self.bpm:.2f}")
        print(f"采样率: {self.sample_rate} Hz")
        print(f"游戏时间步: {game_step_ms} ms")

    def detect_bpm(self):
        for track in self.midi.tracks:
            for msg in track:
                if msg.type == 'set_tempo':
                    tempo = msg.tempo
                    return mido.tempo2bpm(tempo)
        return 120.0

    def analyze_midi_structure(self):
        print(f"\n=== 分析MIDI结构 ===")

        max_ticks = 0
        for track in self.midi.tracks:
            total_ticks = 0
            for msg in track:
                total_ticks += msg.time
            max_ticks = max(max_ticks, total_ticks)

        ticks_per_second = self.midi.ticks_per_beat * (self.bpm / 60.0)
        total_seconds = max_ticks / ticks_per_second

        ticks_per_step = ticks_per_second * (self.game_step_ms / 1000.0)
        total_steps = int(max_ticks / ticks_per_step) + 1

        print(f"总时长: {total_seconds:.2f} 秒")
        print(f"游戏时间步数: {total_steps}")
        print(f"音频采样点数: {int(total_seconds * self.sample_rate)}")

        return {
            'total_ticks': max_ticks,
            'total_seconds': total_seconds,
            'total_steps': total_steps,
            'ticks_per_step': ticks_per_step,
            'ticks_per_second': ticks_per_second
        }

    def generate_beat_data(self):
        print(f"\n=== 生成节拍数据 ===")

        info = self.analyze_midi_structure()
        total_steps = info['total_steps']
        ticks_per_step = info['ticks_per_step']

        beat_data = [0] * total_steps

        for track_idx, track in enumerate(self.midi.tracks):
            current_ticks = 0
            current_step = 0

            for msg in track:
                current_ticks += msg.time
                current_step = int(current_ticks / ticks_per_step)

                if current_step >= total_steps:
                    continue

                if msg.type == 'note_on' and msg.velocity > 0:
                    note = msg.note
                    game_track = self.map_note_to_track(note, track_idx)

                    if game_track is not None and game_track < 4:
                        beat_data[current_step] |= (1 << game_track)

        notes_per_track = [0, 0, 0, 0]
        total_notes = 0

        for step in beat_data:
            for track in range(4):
                if (step >> track) & 1:
                    notes_per_track[track] += 1
                    total_notes += 1

        print(f"轨道1 (F1): {notes_per_track[0]:5d} 音符")
        print(f"轨道2 (F2): {notes_per_track[1]:5d} 音符")
        print(f"轨道3 (F3): {notes_per_track[2]:5d} 音符")
        print(f"轨道4 (F4): {notes_per_track[3]:5d} 音符")
        print(f"总音符数: {total_notes}")
        print(f"音符密度: {total_notes / total_steps:.2%}")

        return beat_data

    def map_note_to_track(self, note, track_idx):
        """简化映射：按音高范围分配"""
        if 60 <= note <= 63:  # C4到D#4
            return 0
        elif 64 <= note <= 67:  # E4到G4
            return 1
        elif 68 <= note <= 71:  # G#4到B4
            return 2
        elif 72 <= note <= 76:  # C5到E5
            return 3
        else:
            if note < 60:
                return 0
            else:
                return 3

    def generate_audio_data(self):
        print(f"\n=== 生成音频数据 ===")

        info = self.analyze_midi_structure()
        total_samples = int(info['total_seconds'] * self.sample_rate)

        # 生成简单的音调
        audio_data = self.simple_tone(total_samples)

        print(f"音频采样点数: {len(audio_data)}")
        print(f"音频时长: {len(audio_data) / self.sample_rate:.2f} 秒")

        return audio_data

    def simple_tone(self, total_samples):
        """生成简单的测试音调"""
        t = np.arange(total_samples) / self.sample_rate

        # 生成A4音 (440Hz)
        frequency = 440.0
        amplitude = 0.7

        # 简单的正弦波
        tone = amplitude * np.sin(2 * np.pi * frequency * t)

        # 添加包络避免爆音
        envelope = np.ones_like(t)
        attack_samples = int(0.01 * self.sample_rate)
        decay_samples = int(0.1 * self.sample_rate)
        release_samples = int(0.2 * self.sample_rate)

        if len(envelope) > attack_samples:
            envelope[:attack_samples] = np.linspace(0, 1, attack_samples)

        if len(envelope) > attack_samples + decay_samples:
            envelope[attack_samples:attack_samples + decay_samples] = np.linspace(1, 0.8, decay_samples)

        if len(envelope) > release_samples:
            envelope[-release_samples:] = np.linspace(envelope[-release_samples - 1], 0, release_samples)

        tone = tone * envelope

        # 转换为16位整数
        tone_int16 = np.int16(tone * 32767)

        return tone_int16

    def save_beat_mif(self, beat_data, filename):
        print(f"\n=== 生成节拍MIF文件: {filename} ===")

        total_steps = len(beat_data)

        with open(filename, 'w', encoding='utf-8') as f:
            f.write("-- 节奏游戏节拍数据 MIF文件\n")
            f.write(f"-- 源文件: {os.path.basename(self.midi_file)}\n")
            f.write(f"-- BPM: {self.bpm:.2f}\n")
            f.write(f"-- 时间步: {self.game_step_ms} ms\n")
            f.write(f"-- 总时间步数: {total_steps}\n")
            f.write(f"-- 游戏时长: {total_steps * self.game_step_ms / 1000:.1f} 秒\n")
            f.write("-- 数据格式: 位[3:0] = 轨道[4:1] (F4 F3 F2 F1)\n")
            f.write("-- 1 = 有音符, 0 = 无音符\n\n")

            f.write(f"WIDTH=4;\n")
            f.write(f"DEPTH={total_steps};\n\n")
            f.write("ADDRESS_RADIX=DEC;\n")
            f.write("DATA_RADIX=BIN;\n\n")
            f.write("CONTENT BEGIN\n")

            for i in range(0, total_steps, 16):
                line_data = beat_data[i:min(i + 16, total_steps)]
                bin_str = ' '.join(f"{x:04b}" for x in line_data)
                f.write(f"    {i:6d} : {bin_str};\n")

            f.write("END;\n")

        print(f"已生成 {filename} ({total_steps} 个时间步)")

    def save_audio_mif(self, audio_data, filename):
        print(f"\n=== 生成音频MIF文件: {filename} ===")

        total_samples = len(audio_data)

        with open(filename, 'w', encoding='utf-8') as f:
            f.write("-- 节奏游戏音频数据 MIF文件\n")
            f.write(f"-- 源文件: {os.path.basename(self.midi_file)}\n")
            f.write(f"-- 采样率: {self.sample_rate} Hz\n")
            f.write(f"-- 位深度: 16-bit 有符号\n")
            f.write(f"-- 总采样点: {total_samples}\n")
            f.write(f"-- 音频时长: {total_samples / self.sample_rate:.2f} 秒\n")
            f.write("-- 数据格式: 16-bit PCM 有符号整数\n\n")

            f.write(f"WIDTH=16;\n")
            f.write(f"DEPTH={total_samples};\n\n")
            f.write("ADDRESS_RADIX=DEC;\n")
            f.write("DATA_RADIX=DEC;\n\n")
            f.write("CONTENT BEGIN\n")

            save_samples = min(1000, total_samples)

            for i in range(0, save_samples, 8):
                line_values = []
                for j in range(i, min(i + 8, save_samples)):
                    sample = audio_data[j]
                    if sample < 0:
                        value = 65536 + sample
                    else:
                        value = sample
                    line_values.append(str(value))

                f.write(f"    {i:6d} : {' '.join(line_values)};\n")

            if total_samples > save_samples:
                f.write(f"    [{save_samples:6d}..{total_samples - 1:6d}] : 0;\n")

            f.write("END;\n")

        print(f"已生成 {filename} ({total_samples} 个采样点)")
        print(f"注意: 只保存了前{min(1000, total_samples)}个采样点用于测试")

    def save_sync_info(self, beat_data, audio_data, filename):
        print(f"\n=== 生成同步信息文件: {filename} ===")

        total_steps = len(beat_data)
        total_samples = len(audio_data)
        samples_per_step = int(self.sample_rate * (self.game_step_ms / 1000.0))

        with open(filename, 'w', encoding='utf-8') as f:
            f.write("=== 节奏游戏同步信息 ===\n\n")
            f.write(f"MIDI文件: {os.path.basename(self.midi_file)}\n")
            f.write(f"BPM: {self.bpm:.2f}\n")
            f.write(f"采样率: {self.sample_rate} Hz\n")
            f.write(f"游戏时间步: {self.game_step_ms} ms\n\n")

            f.write(f"节拍数据:\n")
            f.write(f"  文件: beat_data.mif\n")
            f.write(f"  位宽: 4 bits\n")
            f.write(f"  深度: {total_steps}\n")
            f.write(f"  时长: {total_steps * self.game_step_ms / 1000:.1f} s\n\n")

            f.write(f"音频数据:\n")
            f.write(f"  文件: audio_data.mif\n")
            f.write(f"  位宽: 16 bits\n")
            f.write(f"  深度: {total_samples}\n")
            f.write(f"  时长: {total_samples / self.sample_rate:.2f} s\n\n")

            f.write(f"同步关系:\n")
            f.write(f"  每时间步采样点数: {samples_per_step}\n")
            f.write(f"  音频地址 = 时间步 × {samples_per_step}\n")
            f.write(f"  节拍地址 = 音频地址 / {samples_per_step}\n\n")

            f.write(f"游戏配置建议:\n")
            f.write(f"  音频时钟分频: 50MHz / 1134 ≈ 44.1kHz\n")
            f.write(f"  节拍时钟分频: 50MHz / 5,000,000 = 100ms\n")

            if total_steps * samples_per_step <= total_samples:
                f.write(f"  状态: 同步数据有效 ✓\n")
            else:
                f.write(f"  状态: 数据不匹配 ✗\n")

        print(f"已生成 {filename}")

    def convert_all(self, output_prefix="song"):
        print(f"\n{'=' * 50}")
        print(f"开始转换: {os.path.basename(self.midi_file)}")
        print(f"{'=' * 50}")

        try:
            beat_data = self.generate_beat_data()
            self.save_beat_mif(beat_data, f"{output_prefix}_beats.mif")

            audio_data = self.generate_audio_data()
            self.save_audio_mif(audio_data, f"{output_prefix}_audio.mif")

            self.save_sync_info(beat_data, audio_data, f"{output_prefix}_sync.txt")

            print(f"\n{'=' * 50}")
            print(f"转换完成！")
            print(f"生成的文件:")
            print(f"  - {output_prefix}_beats.mif  (节拍数据)")
            print(f"  - {output_prefix}_audio.mif  (音频数据)")
            print(f"  - {output_prefix}_sync.txt   (同步信息)")
            print(f"{'=' * 50}")

            return True

        except Exception as e:
            print(f"转换失败: {e}")
            import traceback
            traceback.print_exc()
            return False


def get_file_path_interactive():
    """交互式获取文件路径"""
    print("MIDI转游戏资源转换器")
    print("=" * 50)

    # 方法1：检查默认位置
    default_path = os.path.join(os.path.expanduser("~"), "Desktop", "vlsi", "1.mid")
    print(f"默认路径: {default_path}")

    if os.path.exists(default_path):
        print(f"✓ 在默认位置找到文件")
        use_default = input("使用默认文件？(Y/n): ").strip().lower()
        if use_default in ['', 'y', 'yes']:
            return default_path

    # 方法2：手动输入
    print("\n请选择MIDI文件:")
    print("1. 输入文件路径")
    print("2. 将MIDI文件拖拽到窗口中")

    while True:
        choice = input("\n选择 (1/2): ").strip()

        if choice == '1':
            file_path = input("输入MIDI文件完整路径: ").strip()

            # 处理拖拽可能带来的引号
            if file_path.startswith('"') and file_path.endswith('"'):
                file_path = file_path[1:-1]

            # 尝试修复Windows路径
            file_path = file_path.replace('\\', '\\\\')

            if os.path.exists(file_path):
                return file_path
            else:
                print(f"错误: 文件不存在 - {file_path}")

        elif choice == '2':
            print("请将MIDI文件拖拽到这个窗口中，然后按Enter")
            file_path = input("拖拽文件到这里: ").strip()

            # 处理拖拽可能带来的引号
            if file_path.startswith('"') and file_path.endswith('"'):
                file_path = file_path[1:-1]

            if os.path.exists(file_path):
                return file_path
            else:
                print(f"错误: 文件不存在 - {file_path}")
        else:
            print("无效选择，请重试")


def main():
    """主函数"""

    # 交互式获取文件路径
    midi_file = get_file_path_interactive()

    print(f"\n使用文件: {midi_file}")
    print(f"文件大小: {os.path.getsize(midi_file)} 字节")

    # 确认转换
    confirm = input("\n开始转换？(Y/n): ").strip().lower()
    if confirm not in ['', 'y', 'yes']:
        print("转换取消")
        return

    # 获取输出文件名前缀
    default_prefix = os.path.splitext(os.path.basename(midi_file))[0]
    output_prefix = input(f"输出文件名前缀 (默认: {default_prefix}): ").strip()
    if not output_prefix:
        output_prefix = default_prefix

    # 创建转换器
    try:
        converter = MIDIToGameAssets(midi_file)
    except Exception as e:
        print(f"创建转换器失败: {e}")
        return

    # 执行转换
    success = converter.convert_all(output_prefix=output_prefix)

    if success:
        print("\n✅ 转换成功！")
        print(f"\n生成的文件在当前目录:")
        print(f"  {output_prefix}_beats.mif  - 节拍数据 (用于Verilog ROM)")
        print(f"  {output_prefix}_audio.mif  - 音频数据 (用于Verilog ROM)")
        print(f"  {output_prefix}_sync.txt   - 同步信息 (游戏配置参考)")

        current_dir = os.getcwd()
        print(f"\n当前目录: {current_dir}")
    else:
        print("\n❌ 转换失败")


if __name__ == "__main__":
    try:
        # 检查依赖
        try:
            import mido
            import numpy as np
        except ImportError as e:
            print(f"缺少依赖库: {e}")
            print("\n请安装依赖:")
            print("pip install mido numpy")
            input("\n按 Enter 键退出...")
            sys.exit(1)

        main()

        # 等待用户确认
        input("\n按 Enter 键退出...")

    except KeyboardInterrupt:
        print("\n用户中断")
    except Exception as e:
        print(f"程序错误: {e}")
        import traceback

        traceback.print_exc()
        input("\n按 Enter 键退出...")
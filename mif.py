import mido
from mido import MidiFile
import os

# MIDI 文件路径
song_files = {
    0: "C:\\Users\\ang32\\Desktop\\music_game\\mid_files\\chunriyin.mid",  # 第一首歌
    1: "C:\\Users\\ang32\\Desktop\\music_game\\mid_files\\see.mid",  # 第二首歌
    2: "C:\\Users\\ang32\\Desktop\\music_game\\mid_files\\lemon.mid",  # 第三首歌
    3: "C:\\Users\\ang32\\Desktop\\music_game\\mid_files\\qing.mid"  # 第四首歌
}

# MIDI 文件转 MIF 文件
def midi_to_mif(midi_file, mif_file):
    # 打开 MIDI 文件
    mid = MidiFile(midi_file)

    # 用来存储所有音符的时间戳
    notes = []

    # 读取所有轨道（tracks），并提取音符事件的时间
    for track in mid.tracks:
        time = 0
        for msg in track:
            time += msg.time  # 累加时间（MIDI 中的 delta time）
            if msg.type == 'note_on' and msg.velocity > 0:  # 如果是音符开启事件
                notes.append(time)

    # 将节拍信息转换为 MIF 格式
    mif_data = []
    for note_time in notes:
        # 将时间戳转换为二进制并保持四位
        time_bin = bin(int(note_time // 16))  # 以 1/16 音符为单位
        
        # 使其保持 4 位二进制数，超过 4 位的部分会被截断，不足 4 位的会用零填充
        time_bin = time_bin[2:].zfill(4)[-4:]  # 保证为 4 位

        mif_data.append(time_bin)  # 添加到 MIF 数据列表

    # 提取 MIDI 文件名并生成对应的 MIF 文件名
    midi_file_name = os.path.basename(midi_file)  # 获取文件名
    mif_file_name = os.path.splitext(midi_file_name)[0] + ".mif"  # 获取不带扩展名的文件名并添加 .mif 扩展名

    # 保存 MIF 文件路径
    mif_file_path = os.path.join("C:\\Users\\ang32\\Desktop\\music_game\\mid_files", mif_file_name)

    # 将转换后的节拍数据写入 MIF 文件
    with open(mif_file_path, 'w') as f:
        f.write("DEPTH = 1024;\n")
        f.write("WIDTH = 4;\n")
        f.write("ADDRESS_RADIX = DEC;\n")
        f.write("DATA_RADIX = BIN;\n")
        f.write("CONTENT\n")
        f.write("BEGIN\n")
        for i, time_bin in enumerate(mif_data):
            f.write(f"  {i} : {time_bin};\n")
        f.write("END;\n")

    print(f"生成 MIF 文件：{mif_file_path}")

# 生成每首歌对应的 MIF 文件
def generate_mif_files():
    for song_num, midi_file in song_files.items():
        midi_to_mif(midi_file, None)  # 生成对应的 MIF 文件名

if __name__ == "__main__":
    generate_mif_files()

import serial
import time
import winsound
import pygame

# 配置 UART 端口
SERIAL_PORT = 'COM3'  # 根据你的硬件配置调整
BAUD_RATE = 115200
ser = serial.Serial(SERIAL_PORT, baudrate=BAUD_RATE, timeout=1)

if ser.is_open:
    print(f"串口 {SERIAL_PORT} 已成功打开")

# 初始化 pygame 混音器
pygame.mixer.init()

# 音乐文件路径映射
song_files = {
    0: r"C:\Users\ang32\Desktop\music_game\mid_files\chunriyin.mid",  # 第一首歌
    1: r"C:\Users\ang32\Desktop\music_game\mid_files\see.mid",       # 第二首歌
    2: r"C:\Users\ang32\Desktop\music_game\mid_files\lemon.mid",     # 第三首歌
    3: r"C:\Users\ang32\Desktop\music_game\mid_files\qing.mid"       # 第四首歌
}

# 当前正在播放的歌曲
current_song = None
is_playing = False  # 标记当前是否正在播放

# ✅ death 状态缓存（必须初始化，否则 NameError）
death_temp = 0  # 0=未结束，1=游戏结束

# 播放Windows系统自带音效
def play_sound(song_num):
    if song_num == 0:
        winsound.PlaySound(r"C:\Windows\Media\Windows Ding.wav", winsound.SND_FILENAME)
    elif song_num == 1:
        winsound.PlaySound(r"C:\Users\ang32\Music\man.wav", winsound.SND_FILENAME)
    elif song_num == 2:
        winsound.PlaySound(r"C:\Users\ang32\Music\mambo.wav", winsound.SND_FILENAME)
    elif song_num == 3:
        winsound.PlaySound(r"C:\Users\ang32\Music\ji.wav", winsound.SND_FILENAME)

# 背景音乐播放控制
def play_audio(song_num):
    global current_song, is_playing

    print(f"Play Song {song_num}")
    song_path = song_files.get(song_num)

    if song_path:
        # 只要是新歌，或者当前没在播放，就加载并播放
        if song_path != current_song or not is_playing:
            pygame.mixer.music.load(song_path)
            pygame.mixer.music.play(-1, 0.0)  # 循环播放
            current_song = song_path
            is_playing = True
        else:
            print(f"Song {song_num} is already playing.")

def stop_audio():
    global is_playing
    print("Pause Audio")
    pygame.mixer.music.pause()
    is_playing = False

def resume_audio():
    global is_playing
    print("Resume Audio")
    pygame.mixer.music.unpause()
    is_playing = True

def reset_song():
    global is_playing
    print("Reset Song to Start")
    pygame.mixer.music.stop()
    pygame.mixer.music.play(-1, 0.0)  # ✅ 从头开始并继续循环
    is_playing = True

def handle_uart_data(data):
    global current_song, is_playing, death_temp

    # 解析数据
    death = (data >> 5) & 0x01         # 第 5 位 (游戏结束信号)
    start = (data >> 4) & 0x01         # 第 4 位 (start)
    song_num = (data >> 2) & 0x03      # 第 3 和第 2 位 (歌曲编号)
    reset = (data >> 1) & 0x01         # 第 1 位 (复位)
    hit = data & 0x01                  # 第 0 位 (音符击中)

    # ----------- death：边沿触发（防止重复触发）-----------
    # 0 -> 1：刚进入 Game Over
    if death == 1 and death_temp == 0:
        print("Game Over! Stopping Music.")
        pygame.mixer.music.stop()
        is_playing = False

    # 1 -> 0：从 Game Over 恢复
    elif death == 0 and death_temp == 1:
        print("Game Restart! Reset and Play.")
        is_playing = True
        reset_song()

    # death == 1：保持 Game Over 状态时，不再处理其他信号
    if death == 1:
        death_temp = death
        return
    # ------------------------------------------------------

    # 复位：从头开始播放当前音乐
    if reset == 0:
        reset_song()

    song_path = song_files.get(song_num)

    # start 控制播放/暂停
    if start == 0:
        # ✅ 切歌：播放态下只要 song_path 变了就立刻切
        if song_path and song_path != current_song:
            play_audio(song_num)
        else:
            # 没切歌时，再根据状态决定恢复/保持
            if not is_playing:
                resume_audio()
    else:
        stop_audio()

    # 击中音符：播放对应音效
    if hit == 0:
        print("Hit Note!")
        play_sound(song_num)

    # ✅ 每次处理完都更新 death_temp（避免状态卡住）
    death_temp = death

def read_uart(ser):
    while True:
        if ser.in_waiting > 0:
            b = ser.read(1)
            if not b:
                continue
            data = b[0]  # 比 ord 更稳
            print(f"Received data: {bin(data)}")
            handle_uart_data(data)
        time.sleep(0.1)

if __name__ == "__main__":
    try:
        read_uart(ser)
    except KeyboardInterrupt:
        print("程序中断，正在关闭串口...")
    finally:
        ser.close()
        print("串口已关闭")

import socket
import struct
import random

SERVER_ADDRESS = ('127.0.0.1', 12345)

RESULT_MAP = {
    0: '大吉',
    1: '中吉',
    2: '小吉',
    3: '凶'
}

def main():
    conn_id = random.random()
    print(f"Send Connection ID: {conn_id}")

    request = struct.pack("!B", 0) + struct.pack("!d", conn_id)

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.sendto(request, SERVER_ADDRESS)
        sock.settimeout(5.0)
        try:
            data, _ = sock.recvfrom(1024)
            if len(data) < 12:
                print("Error: Response packet is too short")
                return
            packet_type, = struct.unpack("!B", data[0:1])
            response_conn_id, = struct.unpack("!d", data[1:9])
            result_bytes = data[9:12]
            result_num = int.from_bytes(result_bytes, byteorder = 'big')
            if packet_type == 1 or response_conn_id == conn_id:
                result_text = RESULT_MAP.get(result_num, "不明な値")
                print(f"Received result: {result_text}")
            else:
                print("Error: Response packet is invalid")
                return
        except socket.timeout:
            print("Error: Timeout")
            return

if __name__ == "__main__":
    main()
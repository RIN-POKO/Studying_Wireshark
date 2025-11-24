import socket
import struct
import random

PORT = 12345
BUFFER_SIZE = 1024

def handle_request(data):
    if len(data) < 9:
        return None # Invalid packet
    packet_type, = struct.unpack("!B", data[0:1])
    if packet_type != 0:
        return None # Undemanded packet
    conn_id, = struct.unpack("!d", data[1:9])

    result_num = random.randint(0, 3)

    result_bytes = result_num.to_bytes(3, byteorder = 'big')

    response = struct.pack("!B", 1) + struct.pack("!d", conn_id) + result_bytes
    
    return response

def main():
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind(('0.0.0.0', PORT))
        print(f"Server is listening on port {PORT}")
        try:
            while True:
                data, addr = sock.recvfrom(BUFFER_SIZE)
                print(f"Received data {data.hex()} from {addr}")
                response = handle_request(data)
                if response:
                    sock.sendto(response, addr)
                print(f"If you want to exit, press Ctrl+C")
        except KeyboardInterrupt:
            print("Server is shutting down")
            sock.close()

if __name__ == "__main__":
    main()
import 'package:socket_io_client/socket_io_client.dart'
    as io;

class SocketService {
  static final io.Socket socket = io.io(
    'http://10.10.0.10:3000',
    <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    },
  );
}

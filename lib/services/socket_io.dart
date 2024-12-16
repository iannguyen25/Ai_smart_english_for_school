import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart';

class SocketMain {
  static SocketMain? socketMain;
  static Socket socket = io('ws://45.76.209.56:2346', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': true,
  });
  static SocketMain getInstance() {
    if (socketMain == null) {
      socketMain = new SocketMain();
      socket.connect();
    }
    return socketMain!;
  }

  SocketMain() {
    socket.open();

    // channel!.stream.listen((message) {
    //   channel!.sink.add('received!');
    // });
  }

  void close() {
    socket.close();
  }

  void open() {
    socket.open();
  }

  Map connectParam({required String nameClient, required String roomId}) {
    return {"type": "login", "client_name": nameClient, "room_id": roomId};
  }

  Map sendParam({
    required String nameClient,
    required String roomId,
    required String content,
  }) {
    return {
      "type": "say",
      "to_client_id": "all",
      "to_client_name": nameClient,
      "content": content,
      "room_id": roomId
    };
  }
}

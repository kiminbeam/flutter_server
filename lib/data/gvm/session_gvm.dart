import 'package:flutter/material.dart';
import 'package:flutter_blog/_core/utils/my_http.dart';
import 'package:flutter_blog/data/repository/user_repository.dart';
import 'package:flutter_blog/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionUser {
  int? id;
  String? username;
  String? accessToken;
  bool? isLogin;

  SessionUser({this.id, this.username, this.accessToken, this.isLogin = false});
}

class SessionGVM extends Notifier<SessionUser> {
  // TODO 2: 지금 최상단 컨텍스트
  final mContext = navigatorKey.currentContext!;
  UserRepository userRepo = const UserRepository();

  @override
  SessionUser build() {
    return SessionUser(
        id: null, username: null, accessToken: null, isLogin: false);
  }

  // async 일때는 무조건 Future<void>

  Future<void> login(String username, String password) async {
    // 파싱
    final body = {
      "username": username,
      "password": password,
    };
    // 유효성 검사

    // 통신
    final (responseBody, accessToken) =
        await userRepo.findByUsernameAndPassword(body);

    if (!responseBody["success"]) {
      ScaffoldMessenger.of(mContext!).showSnackBar(
        SnackBar(content: Text("로그인 실패 : ${responseBody["errorMessage"]}")),
      );
      return;
    }

    // 1. 토큰을 Storage 저장
    await secureStorage.write(
        key: "accessToken",
        value: accessToken); // I/O << 비동기가 디폴트라서 동기로 묶어줘야 한다.

    // 2. SessionUser 갱신
    Map<String, dynamic> data = responseBody["response"];
    state = SessionUser(
        id: data["id"],
        username: data["username"],
        accessToken: accessToken,
        isLogin: true);

    // 3. Dio 토큰 세팅 , Dio << 메모리에 저장
    dio.options.headers["Authorization"] = accessToken;

    //Logger().d(dio.options.headers);

    Navigator.popAndPushNamed(mContext, "/post/list");
  }

  Future<void> join(String username, String email, String password) async {
    // 파싱
    final body = {
      "username": username,
      "email": email,
      "password": password,
    };

    Map<String, dynamic> responseBody = await userRepo.save(body);
    if (!responseBody["success"]) {
      ScaffoldMessenger.of(mContext!).showSnackBar(
        SnackBar(content: Text("회원가입 실패 : ${responseBody["errorMessage"]}")),
      );
      return;
    }
    // 응답 정상일 경우
    Navigator.pushNamed(mContext, "/login");
  }

  Future<void> logout() async {
    // 1. 디바이스 토큰 삭제
    await secureStorage.delete(key: "accessToken");
    // 2. 상태 갱신
    state = SessionUser();
    // 3. dio 갱신
    dio.options.headers["Authorization"] = "";

    // 4. 화면 이동
    Navigator.popAndPushNamed(mContext, "/login");
  }

  // 1. 절대 SessionUser가 있을 수 없다.
  Future<void> autoLogin() async {
    // 1. 토큰 디바이스에서 가져오기
    String? accessToken = await secureStorage.read(key: "accessToken");

    if (accessToken == null) {
      Navigator.popAndPushNamed(mContext, "/login");
      return;
    }

    Map<String, dynamic> responseBody = await userRepo.autoLogin(accessToken);

    if (!responseBody["success"]) {
      Navigator.popAndPushNamed(mContext, "/login");
      return;
    }
    Map<String, dynamic> data = responseBody["response"];
    state = SessionUser(
        id: data["id"],
        username: data["username"],
        accessToken: accessToken,
        isLogin: true);

    dio.options.headers["Authorization"] = accessToken;

    Navigator.popAndPushNamed(mContext, "/post/list");
  }
}

final sessionProvider = NotifierProvider<SessionGVM, SessionUser>(() {
  return SessionGVM();
});

import 'package:flutter_blog/data/repository/user_repository.dart';

void main() async {
  UserRepository userRepo = const UserRepository();

  await userRepo
      .findByUsernameAndPassword({"username": "ssa", "password": "1234"});
}

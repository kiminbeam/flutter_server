import 'package:flutter/material.dart';
import 'package:flutter_blog/data/model/post.dart';
import 'package:flutter_blog/data/repository/post_repository.dart';
import 'package:flutter_blog/ui/pages/post/list_page/post_list_vm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../main.dart';

class PostDetailModel {
  Post post;

  PostDetailModel.fromMap(Map<String, dynamic> map) : post = Post.fromMap(map);
}

// 제너릭 세번째에 넣어주면 값을 넘겨받을 수 있다.
final postDetailProvider = NotifierProvider.family
    .autoDispose<PostDetailVM, PostDetailModel?, int>(() {
  return PostDetailVM();
});

// Notifier -> FamilyNotifier 변경
class PostDetailVM extends AutoDisposeFamilyNotifier<PostDetailModel?, int> {
  final mContext = navigatorKey.currentContext!;
  PostRepository postRepo = const PostRepository();

  @override
  PostDetailModel? build(id) {
    init(id);
    return null;
  }

  Future<void> init(int id) async {
    Map<String, dynamic> responseBody = await postRepo.findById(id);

    if (!responseBody["success"]) {
      ScaffoldMessenger.of(mContext!).showSnackBar(
        SnackBar(
            content: Text("게시글 상세보기 실패 : ${responseBody["errorMessage"]}")),
      );
      return;
    }

    PostDetailModel model = PostDetailModel.fromMap(responseBody["response"]);
    state = model;
  }

  Future<void> deleteById(int id) async {
    Map<String, dynamic> responseBody = await postRepo.delete(id);
    if (!responseBody["success"]) {
      ScaffoldMessenger.of(mContext!).showSnackBar(
        SnackBar(content: Text("게시글 삭제 실패 : ${responseBody["errorMessage"]}")),
      );
      return;
    }

    // PostListVM 상태 변경
    // ref.read(postListProvider.notifier).init(0); 통신을 다시 하는 것, 상태관리 XX
    ref.read(postListProvider.notifier).remove(id);

    // 화면 파괴 시 autoDispose 됨
    Navigator.pop(mContext);
  }
}

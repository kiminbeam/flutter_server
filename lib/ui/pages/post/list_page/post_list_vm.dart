import 'package:flutter/material.dart';
import 'package:flutter_blog/data/repository/post_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../data/model/post.dart';
import '../../../../main.dart';

class PostListModel {
  bool isFirst;
  bool isLast;
  int pageNumber;
  int size;
  int totalPage;
  List<Post> posts;

  PostListModel(
      {required this.isFirst,
      required this.isLast,
      required this.pageNumber,
      required this.size,
      required this.totalPage,
      required this.posts});

  PostListModel copyWith(
      {bool? isFirst,
      bool? isLast,
      int? pageNumber,
      int? size,
      int? totalPage,
      List<Post>? posts}) {
    return PostListModel(
        isFirst: isFirst ?? this.isFirst,
        isLast: isLast ?? this.isLast,
        pageNumber: pageNumber ?? this.pageNumber,
        size: size ?? this.size,
        totalPage: totalPage ?? this.totalPage,
        posts: posts ?? this.posts);
  }

  PostListModel.fromMap(Map<String, dynamic> map)
      : isFirst = map["isFirst"],
        isLast = map["isLast"],
        pageNumber = map["pageNumber"],
        size = map["size"],
        totalPage = map["totalPage"],
        posts = (map["posts"] as List<dynamic>)
            .map((e) => Post.fromMap(e))
            .toList();
// 묵시적 형변환 List<dynamic>으로 list타입이 된다. & map<String,dynamic>으로 받게된다. 이걸 Post.fromMap으로 하나씩 리스트에 넣는다.
}

class PostList_Post {}

class PostList_User {}

final postListProvider = NotifierProvider<PostListVM, PostListModel?>(() {
  return PostListVM();
});

class PostListVM extends Notifier<PostListModel?> {
  final refreshCtrl = RefreshController();
  final mContext = navigatorKey.currentContext!;
  PostRepository postRepo = const PostRepository();

  @override
  PostListModel? build() {
    init();
    return null;
  }

  // 1. 페이지 초기화
  Future<void> init() async {
    Map<String, dynamic> responseBody = await postRepo.findAll();

    if (!responseBody["success"]) {
      ScaffoldMessenger.of(mContext!).showSnackBar(
        SnackBar(
            content: Text("게시글 목록보기 실패 : ${responseBody["errorMessage"]}")),
      );
      return;
    }

    state = PostListModel.fromMap(responseBody["response"]);
    // init 메서드가 종료되면 UI 도는거 멈추게 해준다.
    refreshCtrl.refreshCompleted();
  }

  void remove(int id) {
    PostListModel model = state!;
    model.posts = model.posts.where((p) => p.id != id).toList();

    state = state!.copyWith(posts: model.posts);
  }

  void add(Post post) {
    PostListModel model = state!;
    model.posts = [post, ...model.posts];

    state = state!.copyWith(posts: model.posts);
  }

  // 페이징, 페이지 로드
  Future<void> nextList() async {
    PostListModel model = state!;

    if (model.isLast) {
      await Future.delayed(Duration(milliseconds: 500));
      refreshCtrl.loadComplete();
      return;
    }

    // 마지막 페이지가 아닐 시
    Map<String, dynamic> responseBody =
        await postRepo.findAll(page: state!.pageNumber + 1);

    if (!responseBody["success"]) {
      ScaffoldMessenger.of(mContext!).showSnackBar(
        SnackBar(content: Text("게시글 로드 실패 : ${responseBody["errorMessage"]}")),
      );
      return;
    }

    PostListModel nextModel = PostListModel.fromMap(responseBody["response"]);
    PostListModel prevModel = state!;

    // 이전 상태(prevModel) 다음에 nextModel을 추가한다.
    state = nextModel.copyWith(posts: [...prevModel.posts, ...nextModel.posts]);
    refreshCtrl.loadComplete();
  }
}

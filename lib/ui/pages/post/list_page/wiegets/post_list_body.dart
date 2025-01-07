import 'package:flutter/material.dart';
import 'package:flutter_blog/ui/pages/post/detail_page/post_detail_page.dart';
import 'package:flutter_blog/ui/pages/post/list_page/post_list_vm.dart';
import 'package:flutter_blog/ui/pages/post/list_page/wiegets/post_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class PostListBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PostListModel? model = ref.watch(postListProvider);
    PostListVM vm =
        ref.read(postListProvider.notifier); // << refreshCtrl 때문에 사용.

    if (model == null) {
      return Center(child: CircularProgressIndicator());
    } else {
      return SmartRefresher(
        controller: vm.refreshCtrl,
        // enablePullUp과 onRefresh 두개는 쌍을 이룬다.
        enablePullUp: true,
        onRefresh: () async => await vm.init(),
        // enablePullDown과 onLoading 두개가 쌍을 이룬다. 다음 페이지 가져오는 메서드
        enablePullDown: true,
        onLoading: () async => await vm.nextList(),
        child: ListView.separated(
          itemCount: model.posts.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PostDetailPage(model.posts[index].id!)));
              },
              child: PostListItem(model.posts[index]),
            );
          },
          separatorBuilder: (context, index) {
            return const Divider();
          },
        ),
      );
    }
  }
}

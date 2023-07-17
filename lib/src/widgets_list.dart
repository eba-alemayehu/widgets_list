import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

typedef ListBuilder<T> = Widget Function(BuildContext context, T index);
typedef Load<T> = List<T> Function(BuildContext context);
typedef LoadMore<T> = List<T> Function(BuildContext context);
typedef Refresh<T> = List<T> Function(BuildContext context);

enum ListType { HORIZONTAL_SCHROLL, WRAP, VERTICAL_SCHROLL }

class WidgetsList<T> extends StatefulWidget {
  final ListBuilder<T> builder;
  final ListType? type;
  final Load<T>? load;
  final LoadMore<T>? loadMore;
  final bool loaded;
  final bool loading;
  final String? error;
  List<T?> items;
  final Widget? noItemFound;
  final Refresh? refresh;
  final Widget? title;

  WidgetsList({Key? key,
    required this.builder,
    this.type = ListType.WRAP,
    this.load,
    required this.loaded,
    this.loadMore,
    this.loading = false,
    required this.items,
    this.error = null,
    this.refresh,
    this.noItemFound,
    this.title
  })
      : super(key: key);

  @override
  State<WidgetsList> createState() => _WidgetsListState<T>();
}

class _WidgetsListState<T> extends State<WidgetsList<T>> {
  final ScrollController _controller = ScrollController();
  RefreshController _refreshController =
  RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (widget.loaded) {
          widget.items = widget.items.where((e) => e != null).toList();
        } else if (widget.loading) {
          widget.items.addAll(List.generate(10, (index) => null));
        } else if (widget.error != null) {
          return Center(
            child: Text(widget.error ?? ''),
          );
        }
        // if (widget.items.isEmpty) {
        //   return widget.noItemFound ?? const Center(child:Text("No item is found"));
        // }
        return _buildProductList(widget.items);
      },
    );
  }

  Widget _buildProductList(items) {
    Widget listWidget = Wrap(
      alignment: WrapAlignment.spaceEvenly,
      children: _buildProducts(items),
    );
    var axis = Axis.vertical;
    switch (widget.type) {
      case ListType.HORIZONTAL_SCHROLL:
        axis = Axis.horizontal;
        listWidget = Row(
          children: _buildProducts(items),
        );
        break;
      case ListType.WRAP:
        listWidget = Wrap(
          alignment: WrapAlignment.center,
          children: _buildProducts(items),
        );
        break;
      default:
        axis = Axis.vertical;
        listWidget = SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          header: const WaterDropHeader(),
          controller: _refreshController,
          onRefresh: refresh,
          onLoading: loading,
          child: ListView(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            // alignment: WrapAlignment.center,
            controller: _controller,
            addAutomaticKeepAlives: false,
            children: _buildProducts(items),
          ),
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus? mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = Text("Pull up load");
              } else if (mode == LoadStatus.loading) {
                body = CupertinoActivityIndicator();
              } else if (mode == LoadStatus.failed) {
                body = Text("Load Failed!Click retry!");
              } else if (mode == LoadStatus.canLoading) {
                body = Text("release to load more");
              } else {
                body = Text("No more Data");
              }
              return Container(
                height: 55.0,
                child: Center(child: body),
              );
            },
          ),
        );
        return listWidget;
        break;
    }

    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: axis,
      child: listWidget,
    );
  }

  List<Widget> _buildProducts(List<T> items) {
    return [...[widget.title ?? Container()], ...[
      if (items.isNotEmpty) for (final item in items) widget.builder(
          context, item)
      else
        const Center(child: Text("No item is found"))
    ]];
  }

  onScroll() {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final maxScroll = _controller.position.maxScrollExtent;
    final currentScroll = _controller.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      widget.loadMore?.call(context);
    }
  }

  @override
  void initState() {
    _controller.addListener(onScroll);
    widget.load?.call(context);
  }

  void loading() {
    widget.loadMore?.call(context);
    _refreshController.loadComplete();
  }

  void refresh() {
    widget.load?.call(context);
    _refreshController.refreshCompleted();
  }
}

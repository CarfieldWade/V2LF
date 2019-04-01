// 特定节点话题列表页面

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/listview_node_topic.dart';
import 'package:flutter_app/i10n/localization_intl.dart';
import 'package:flutter_app/model/node.dart';
import 'package:flutter_app/model/web/item_node_topic.dart';
import 'package:flutter_app/model/web/node.dart';
import 'package:flutter_app/network/api_network.dart';
import 'package:flutter_app/network/dio_singleton.dart';
import 'package:flutter_app/resources/colors.dart';
import 'package:flutter_app/utils/strings.dart';
import 'package:flutter_html/flutter_html.dart';

class NodeTopics extends StatefulWidget {
  final NodeItem node;

  NodeTopics(this.node);

  @override
  _NodeTopicsState createState() => _NodeTopicsState();
}

class _NodeTopicsState extends State<NodeTopics> {
  Future<Node> _futureNode;

  Future<Node> getNodeInfo() async {
    return NetworkApi.getNodeInfo(widget.node.nodeId);
  }

  int p = 1;
  bool isUpLoading = false;
  List<NodeTopicItem> items = new List();

  ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // 获取数据
    _futureNode = getNodeInfo();
    getTopics();
    // 监听是否滑到了页面底部
    _scrollController.addListener(() {
      if (p != 1 && _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        print("加载更多...");
        getTopics();
      }
    });
  }

  Future getTopics() async {
    if (!isUpLoading) {
      setState(() {
        isUpLoading = true;
      });
    }
    List<NodeTopicItem> newEntries = await dioSingleton.getNodeTopicsByTabKey(widget.node.nodeId, p++);
    // 用来判断节点是否需要登录后查看
    if (newEntries.isEmpty) {
      Navigator.pop(context);
      return;
    }

    print(p);
    setState(() {
      items.addAll(newEntries);
      isUpLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: _buildFlexibleSpaceBar(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == items.length) {
                if (index != 0) {
                  // 滑到了最后一个item
                  return _buildLoadText();
                } else {
                  return new Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: new CircularProgressIndicator(),
                    ),
                  );
                }
              } else {
                return new TopicItemView(items[index]);
              }
            }, childCount: items.length + 1),
          ),
        ],
      ),
//      appBar: new AppBar(
//        title: new Text(widget.node.nodeName),
//      ),
//      body: new NodeTopicListView(widget.node.nodeId),
    );
  }

  Widget _buildFlexibleSpaceBar() {
    return FutureBuilder<Node>(
      future: _futureNode,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return new Center(
              child: new CircularProgressIndicator(),
            );
          case ConnectionState.done:
//          https://cdn.v2ex.com/navatar/fc49/0ca4/65_large.png?m=1524891806
//          👆获取到的节点图片还可以进一步放大-> 将 large 换成 xxlarge。但是有个'坑'，虽然绝大部分是可以这样手动改的，
//          但是还是存在不能手动放大的情况，所以只能加以判断处理
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            return FlexibleSpaceBar(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(snapshot.data.title),
                  Offstage(
                    offstage: snapshot.data.header.isEmpty,
                    child: Text(
                      snapshot.data.header,
                      style: TextStyle(fontSize: 10),
                    ),
//                    Html(
//                      data: snapshot.data.header,
//                      defaultTextStyle: TextStyle(color: Colors.white, fontSize: 10.0,),
//                      linkStyle: TextStyle(
//                          color: ColorT.appMainColor[400],
//                          decoration: TextDecoration.underline,
//                          decorationColor: ColorT.appMainColor[400]),
//                      onLinkTap: (url) {
//                        //_launchURL(url);
//                      },
//                      useRichText: true,
//                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.forum,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 2,
                      ),
                      Text(
                        snapshot.data.topics.toString(),
                        style: TextStyle(fontSize: 10),
                      ),
                      SizedBox(
                        width: 4,
                      ),
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 2,
                      ),
                      Text(
                        snapshot.data.stars.toString(),
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  )
                ],
              ),
              centerTitle: true,
              background: SafeArea(
                child: CachedNetworkImage(
                  imageUrl: (snapshot.data.avatarLarge == '/static/img/node_large.png')
                      ? Strings.nodeDefaultImag
                      : "https:" + snapshot.data.avatarLarge.replaceFirst('large', 'xxlarge'),
                  fit: BoxFit.contain,
                  placeholder: (context, url) => new CircularProgressIndicator(),
                  errorWidget: (context, url, error) => CachedNetworkImage(
                        imageUrl: "https:" + snapshot.data.avatarLarge,
                        fit: BoxFit.contain,
                      ),
                ),
              ),
//              Image.network(
//                "https:" + snapshot.data.avatarLarge, //.replaceFirst('large', 'xxlarge')
//                fit: BoxFit.contain,
//              ),
            );
        }
      },
    );
  }

  Widget _buildLoadText() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      child: Center(
        child: Text(MyLocalizations.of(context).loadingPage(p.toString())),
      ),
    );
  }
}

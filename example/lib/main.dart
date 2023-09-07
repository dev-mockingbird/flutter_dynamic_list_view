import 'package:flutter_dynamic_list_view/data_provider.dart';
import 'package:flutter_dynamic_list_view/dynamic_list_controller.dart';
import 'package:flutter_dynamic_list_view/dynamic_list_view.dart';
import 'package:flutter_dynamic_list_view/scroll_judge.dart';
import 'package:flutter_dynamic_list_view/scroll_to_index.dart';
import 'package:example/data_provider.dart';
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DynamicListController<ExampleItem> controller;
  bool _loading = false;
  final AutoScrollController _scrollController = AutoScrollController();

  @override
  void initState() {
    controller = DynamicListController<ExampleItem>(
        provider: ExampleDataProvider(), scrollJudge: DefaultScrollJudge());
    controller.addLoadingListener((type, loading) {
      setState(() {
        _loading = loading;
      });
    });
    super.initState();
  }

  _scrollToBottom() {
    controller.scrollToBottom(
      _scrollController,
      duration: const Duration(milliseconds: 500),
    );
  }

  _scrollToTop() {
    controller.scrollToTop(
      _scrollController,
      duration: const Duration(milliseconds: 500),
    );
  }

  _randScroll() {
    int index = Random().nextInt(controller.items.length);
    Item item = controller.items[index];
    print("index: $index, item: ${item.id}");
    controller.scrollToItem(
      _scrollController,
      item,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("TEST"),
          actions: [
            TextButton(onPressed: _randScroll, child: const Text("TO RAND")),
            TextButton(onPressed: _scrollToTop, child: const Text("TO TOP")),
            TextButton(
                onPressed: _scrollToBottom, child: const Text("TO BOTTOM")),
          ],
          elevation: 8,
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: SizedBox(
                  height: 2,
                  child: _loading ? const LinearProgressIndicator() : null)),
        ),
        body: DynamicListView(
            scrollController: _scrollController,
            itemsBuilder: (List<Item> data) {
              List<Widget> children = [];
              for (var i = 0; i < data.length; i++) {
                children.add(ItemWrap(
                    scrollController: _scrollController,
                    index: i,
                    child: Container(
                        color: Colors.green,
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(20),
                        child: Text(data[i].id))));
              }
              return children;
            },
            controller: controller));
  }
}

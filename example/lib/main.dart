import 'package:enough_giphy_flutter/enough_giphy_flutter.dart';
import 'package:enough_giphy_flutter/widgets.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformApp(
      title: 'enough_giphy_flutter',
      material: (context, target) => MaterialAppData(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const MyHomePage(title: 'enough_giphy_flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _images = <GiphyGif>[];
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: _images.isEmpty
          ? const Center(child: Text('Please add a GIF'))
          : ListView.builder(
              itemBuilder: (context, index) => GiphyImageView(
                gif: _images[index],
                fit: BoxFit.contain,
              ),
              itemCount: _images.length,
              controller: _scrollController,
            ),
    );
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(widget.title),
      ),
      material: (context, platform) => MaterialScaffoldData(
        body: content,
        floatingActionButton: FloatingActionButton(
          onPressed: _selectGif,
          tooltip: 'Select Gif',
          child: const Icon(Icons.gif),
        ),
      ),
      cupertino: (context, platform) => CupertinoPageScaffoldData(
          body: Stack(
        children: [
          content,
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CupertinoButton.filled(
                child: const Icon(Icons.gif),
                onPressed: _selectGif,
              ),
            ),
          ),
        ],
      )),
    );
  }

  /// Selects and display a gif, sticker or emoji from GIPHY
  void _selectGif() async {
    const giphyApiKey = 'giphy-api-key';
    if (giphyApiKey == 'giphy-api-key') {
      showPlatformDialog(
        context: context,
        builder: (context) => PlatformAlertDialog(
          title: const Text('Check your GIPHY API Key'),
          content: const Text('You need to register an API key first.'),
        ),
      );
      return;
    }
    // let the user select the gif:
    final gif = await Giphy.getGif(
      context: context,
      apiKey: giphyApiKey, //  your API key
      type: GiphyType.gifs, // choose between gifs, stickers and emoji
      rating: GiphyRating.g, // general audience / all ages
      lang: GiphyLanguage.english, // 'en'
      keepState: true, // remember type and seach query
      showPreview: true, // shows a preview before returning the GIF
    );
    // process the gif:
    if (gif != null) {
      _images.insert(0, gif);
      setState(() {});
      WidgetsBinding.instance?.addPostFrameCallback((duration) {
        _scrollController.animateTo(
          0,
          duration: const Duration(microseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }
}

import 'package:enough_giphy_flutter/enough_giphy_flutter.dart';
import 'package:enough_giphy_flutter/src/grid.dart';
import 'package:enough_giphy_flutter/src/image.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:enough_platform_widgets/platform.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// What predefined grid should be used
enum GridType {
  /// Square grid with the specififed gridMinColumns
  squareFixedColumns,

  /// Square grid with as many columns as fit
  squareFixedWidth,

  /// A stacked columns grid with at least gridMinColumns
  stackedColumns
}

/// Contains the GIPHY UI components
class GiphySheet extends StatefulWidget {
  final GiphyClient client;
  final GiphyRequest request;
  final InputDecoration? searchInputDecoration;
  final String? searchLabelText;
  final String? searchHintText;
  final String? searchEmptyResultText;
  final String? searchCancelText;
  final String? headerGifsText;
  final String? headerStickersText;
  final String? headerEmojiText;
  final void Function(GiphyGif gif)? onSelected;
  final Widget? attribution;
  final bool showAttribution;
  final bool showSearch;
  final bool showTypeSwitcher;
  final bool showPreview;
  final double gridSpacing;

  /// Optional scroll controller in case this sheet is embedded in a linked scrolling experience like a `DraggableScrollableSheet`
  final ScrollController? scrollController;

  /// Sliver builder responsible for creating the visual representation of the given source
  final Widget Function(
    BuildContext context,
    GiphySource source,
    void Function(GiphyGif) onSelected,
  )? gridBuilder;

  /// Sliver builder that is invoked when no GIFs could be loaded
  final Widget Function(
    BuildContext context,
    dynamic error,
    StackTrace? strackTrace,
  )? errorBuilder;

  /// When `true` the state is kept in a static variable to subsequent calls.
  ///
  /// This helps the user to not repeat a search entry, for example.
  final bool keepState;

  /// The minimum number of columns, defaults to 4
  final int gridMinColumns;

  /// The border radius for images shown in the grid
  final BorderRadius? gridBorderRadius;

  // / The border radius for an image shown in a preview alert
  // final BorderRadius? previewBorderRadius;

  /// The type of the predefined grids
  final GridType gridType;

  /// Creates a new GiphySheet
  const GiphySheet({
    Key? key,
    required this.client,
    required this.request,
    this.gridBuilder,
    this.errorBuilder,
    this.searchInputDecoration,
    this.searchLabelText,
    this.searchHintText,
    this.searchEmptyResultText,
    this.searchCancelText,
    this.onSelected,
    this.attribution,
    this.showAttribution = true,
    this.showSearch = true,
    this.showTypeSwitcher = true,
    this.showPreview = false,
    this.keepState = false,
    this.headerGifsText,
    this.headerStickersText,
    this.headerEmojiText,
    this.gridSpacing = 2.0,
    this.gridBorderRadius,
    // this.previewBorderRadius,
    this.scrollController,
    this.gridMinColumns = 2,
    this.gridType = GridType.stackedColumns,
  }) : super(key: key);

  @override
  _GiphySheetState createState() => _GiphySheetState();
}

class _GiphySheetState extends State<GiphySheet> {
  static GiphyRequest? _lastRequest;
  late Future<GiphySource> _loaderFuture;
  late InputDecoration _inputDecoration;
  late TextEditingController _searchController;
  late GiphyRequest _currentRequest;

  @override
  void initState() {
    _currentRequest =
        widget.keepState ? _lastRequest ?? widget.request : widget.request;
    _searchController =
        TextEditingController(text: _currentRequest.searchQuery);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _loaderFuture = widget.client.request(_currentRequest);
    _inputDecoration = widget.searchInputDecoration ??
        InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: widget.searchLabelText ?? 'GIPHY search',
          hintText: widget.searchHintText ?? 'Your search',
          suffix: PlatformIconButton(
              icon: Icon(CommonPlatformIcons.clear),
              onPressed: () {
                _searchController.text = '';
                _reload(_currentRequest.copyWithoutSearchQuery());
              }),
        );
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxAttributionSize = Size(size.width * 0.4, 40);
    final attribution = widget.attribution ??
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ConstrainedBox(
            constraints: BoxConstraints.loose(maxAttributionSize),
            child: Image.asset(
              'assets/attribution.gif',
              package: 'enough_giphy_flutter',
              height: 40.0,
              fit: BoxFit.contain,
            ),
          ),
        );
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        if (widget.showSearch) ...{
          SliverToBoxAdapter(
            child: widget.showAttribution
                ? Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildSearchField(context),
                        ),
                      ),
                      attribution,
                    ],
                  )
                : _buildSearchField(context),
          ),
        } else if (widget.showAttribution) ...{
          SliverToBoxAdapter(child: attribution),
        },
        if (widget.showTypeSwitcher) ...{
          SliverToBoxAdapter(child: _buildTypeSwitcher(context)),
        },
        FutureBuilder<GiphySource>(
          future: _loaderFuture,
          builder: (context, snapshot) {
            final source = snapshot.data;
            if (source != null) {
              final builder = widget.gridBuilder;
              if (builder != null) {
                return builder(context, source, _onSelected);
              }
              if (source.totalCount == 0) {
                return SliverPadding(
                  padding: EdgeInsets.all(widget.gridSpacing),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        widget.searchEmptyResultText ?? 'Nothing found',
                      ),
                    ),
                  ),
                );
              }
              GiphyGrid grid;
              switch (widget.gridType) {
                case GridType.squareFixedColumns:
                  grid = GiphyGrid.square(
                    giphySource: source,
                    onSelected: _onSelected,
                    spacing: widget.gridSpacing,
                    borderRadius: widget.gridBorderRadius,
                    minColums: widget.gridMinColumns,
                  );
                  break;
                case GridType.squareFixedWidth:
                  grid = GiphyGrid.fixedWidth(
                    giphySource: source,
                    onSelected: _onSelected,
                    spacing: widget.gridSpacing,
                    borderRadius: widget.gridBorderRadius,
                    minColums: widget.gridMinColumns,
                  );
                  break;
                case GridType.stackedColumns:
                  grid = GiphyGrid.fixedWidthVaryingHeight(
                    giphySource: source,
                    onSelected: _onSelected,
                    spacing: widget.gridSpacing,
                    borderRadius: widget.gridBorderRadius,
                    minColums: widget.gridMinColumns,
                  );
                  break;
              }
              return SliverPadding(
                padding: EdgeInsets.all(widget.gridSpacing),
                sliver: grid,
              );
            } else if (snapshot.hasError) {
              final error = snapshot.error;
              final stackTrace = snapshot.stackTrace;
              // ignore: avoid_print
              print('Unable to download source: $error $stackTrace');
              final builder = widget.errorBuilder;
              if (builder != null) {
                return builder(context, error, stackTrace);
              } else {
                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const Icon(Icons.error),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                            'Unable to connect to GIPHY, please check your internet connection.\n\nDetails: $error'),
                      ),
                    ],
                  ),
                );
              }
            }
            return SliverToBoxAdapter(
              child: Center(
                child: PlatformCircularProgressIndicator(),
              ),
            );
          },
        ),
      ],
    );
  }

  void _onSelected(GiphyGif gif) async {
    if (widget.showPreview) {
      final approved = await _showPreview(gif);
      if (approved != true) {
        return;
      }
    }
    final callback = widget.onSelected;
    if (callback != null) {
      callback(gif);
    } else {
      Navigator.of(context).pop(gif);
    }
  }

  Widget _buildSearchField(BuildContext context) {
    if (PlatformInfo.isCupertino) {
      return CupertinoSearchFlowTextField(
        enabled: (_currentRequest.type != GiphyType.emoji),
        controller: _searchController,
        cancelText: widget.searchCancelText ?? 'Cancel',
        onSubmitted: _onSearchSubmitted,
        title: _inputDecoration.labelText,
      );
    }
    return DecoratedPlatformTextField(
      enabled: (_currentRequest.type != GiphyType.emoji),
      decoration: _inputDecoration,
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _onSearchSubmitted,
    );
  }

  void _onSearchSubmitted(String text) {
    final request = text.isEmpty
        ? _currentRequest.copyWithoutSearchQuery()
        : _currentRequest.copyWith(searchQuery: text);
    _reload(request);
  }

  void _reload(GiphyRequest request) {
    _currentRequest = request;
    if (widget.keepState) {
      _lastRequest = request;
    }
    setState(() {
      _loaderFuture = widget.client.request(request);
    });
  }

  Widget _buildTypeSwitcher(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: PlatformToggleButtons(
          children: GiphyType.values
              .map((type) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(_getHeaderText(type)),
                  ))
              .toList(),
          isSelected: GiphyType.values
              .map((type) => (type == _currentRequest.type))
              .toList(),
          onPressed: (index) {
            final request =
                _currentRequest.copyWith(type: GiphyType.values[index]);
            _reload(request);
          },
        ),
      ),
    );
  }

  Future<bool?> _showPreview(GiphyGif gif) {
    final titleWidget = Text(gif.title);
    final username = gif.username;
    final giphy = GiphyImageView(gif: gif, fit: BoxFit.contain);
    // final radius = widget.previewBorderRadius;
    // if (radius != null) {
    //   giphy = ClipRRect(
    //     borderRadius: radius,
    //     child: giphy,
    //   );
    // }
    final content = (username == null || username.isEmpty)
        ? giphy
        : SingleChildScrollView(
            child: Column(
              children: [
                giphy,
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Theme.of(context).canvasColor.withAlpha(128),
                    child: PlatformTextButton(
                      child: PlatformText('@${gif.username}'),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        final query = '@${gif.username}';
                        _searchController.text = query;
                        final scrollController = widget.scrollController;
                        if (scrollController != null) {
                          scrollController.animateTo(
                            0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                        _reload(_currentRequest.copyWith(searchQuery: query));
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
    if (PlatformInfo.isCupertino) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: titleWidget,
          content: content,
          actions: [
            CupertinoButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Icon(CupertinoIcons.clear_circled),
            ),
            CupertinoButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Icon(CupertinoIcons.check_mark_circled),
            ),
          ],
        ),
      );
    }
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: titleWidget,
        content: content,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.clear),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check),
          ),
        ],
      ),
    );
  }

  String _getHeaderText(GiphyType type) {
    switch (type) {
      case GiphyType.gifs:
        return widget.headerGifsText ?? 'GIFs';
      case GiphyType.stickers:
        return widget.headerStickersText ?? 'Stickers';
      case GiphyType.emoji:
        return widget.headerEmojiText ?? 'Emoji';
    }
  }
}

# enough_giphy_flutter

Add a powerful and customizable [GIPHY](https://developers.giphy.com/) picker into your Flutter app.

## Benefits
Using `enough_giphy_flutter` has the following benefits:
* The mandatory GIPHY attribution is not an afterthought - use it "as is" to get your app approved or customize the attribution according to your needs.
* Platform-specific UI: use cupertino look and feel on iOS and MacOS, material on Android and other platforms.
* Easily localize all texts.
* Customize the look and feel according to your preferences and style.
* As few dependencies as possible.


## Installation
Add this dependency your pubspec.yaml file:

```
dependencies:
  enough_giphy_flutter: ^0.1.0
```
The latest version or `enough_giphy_flutter` is [![enough_giphy_flutter version](https://img.shields.io/pub/v/enough_giphy_flutter.svg)](https://pub.dartlang.org/packages/enough_giphy_flutter).



## API Documentation
Check out the full API documentation at https://pub.dev/documentation/enough_giphy_flutter/latest/

## Usage
Use `enough_giphy_flutter` to select a GIF, sticker or emoji from [GIPHY](https://developers.giphy.com/). 

### Requirements
* Sign up for the mandatory API key for each supported platform at developers.giphy.com, compare https://developers.giphy.com/docs/api#quick-start-guide for details.
* Android: Ensure to add internet permission to your _AndroidManifest.xml_: `<uses-permission android:name="android.permission.INTERNET"/>` 


### Pick a GIF, Sticker or Emoji
Use `Giphy.getGif(...)` to pick a GIF, sticker or emoji. 

```dart
import 'package:enough_giphy_flutter/enough_giphy_flutter.dart';
[...]
  @override
  Widget build(BuildContext context) {
      return TextButton(
        child: Text('GIPHY'), 
        onPressend: () async {
            final gif = await Giphy.getGif(context: context, apiKey: '123abc123');
            if (gif != null) {
                // the user has selected a GIF, now handle it in your own way.
                // Example: display gif using the GiphyImageView:
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                        title: Text(gif.title),
                        content: GiphyImageView(
                            gif: gif,
                        ),
                    ),
                );
            }
        },
      );
  }
```
### Choose What to Pick
* Set the `type` parameter to switch between gifs, stickers and emoji, e.g. 
```dart
final gif = await Giphy.getGif(
    context: context, 
    apiKey: 'abc123abc',
    type: GiphyType.stickers, 
);
```

* Select localized content with the `lang` parameter (`String`), which is one of the [supported 2-letter-language codes](https://developers.giphy.com/docs/optional-settings#language-support):
```dart
final gif = await Giphy.getGif(
    context: context, 
    apiKey: 'abc123abc',
    type: GiphyType.stickers,
    lang: GiphyLanguage.german, 
);
```

* Use the `rating` parameter to show other than 'all ages' content:
```dart
final gif = await Giphy.getGif(
    context: context, 
    apiKey: 'abc123abc',
    type: GiphyType.gifs,
    lang: GiphyLanguage.spanish, 
    rating: GiphyRating.pg13,
);
```


### Localize
Localize texts with the following `String` parameters of the `getGif()` method:
* `searchLabelText` 
* `searchHintText`
* `searchEmptyResultText`
* `headerGifsText`
* `headerStickersText`
* `headerEmojiText`
You can also define an `errorBuilder` callback to display a localized error message:

```dart
// example for localizing text in German:
final gif = await Giphy.getGif(
    context: context, 
    apiKey: 'abc123abc',
    type: GiphyType.gifs,
    lang: GiphyLanguage.german, 
    rating: GiphyRating.g,
    searchLabelText: 'Suche',
    searchHintText: 'Deine Suchanfrage',
    searchEmptyResultText: 'Nichts gefunden...',
    headerGifsText: 'GIFs',
    headerStickersText: 'Sticker',
    headerEmojiText: 'Emoticons',
    errorBuilder: (context, error, stacktrace) => 
        const Center(child: Text('Leider gab es einen Fehler,\nbitte probiere es später noch einmal.')),
);
```

### Preview
You can show a confirmation dialog before a gif is selected by setting the `showPreview` parameter to `true`:

```dart
final gif = await Giphy.getGif(
    context: context, 
    apiKey: 'abc123abc',
    showPreview: true,
);
```

The preview is either a material `AlertDialog` or a `CupertinoAlertDialog` depending on the platform. This dialog will show the 
title and - if available - the creator of the gif. You can search for other gifs of the same creator by tapping on the creator's name. 

### Attribution
With `enough_giphy_flutter` your app automatically fulfills the [GIPHY Attribution Policy](https://developers.giphy.com/docs/sdk#design-guidelines):
* A GIPHY logo is shown next to the search field
* The preview dialog shows the creator of the selected gif.

If you want to show a different attribution, set the `Widget? attribution` parameter, e.g.:

```dart
final gif = await Giphy.getGif(
    context: context, 
    apiKey: 'abc123abc',
    attribution: Image.asset('assets/images/giphy.gif', height: 40),
);
```

To hide the attribution, set `showAttribution` to false:

```dart
final gif = await Giphy.getGif(
    context: context, 
    apiKey: 'abc123abc',
    showAttribution: false,
);
```

### Customize UI
Apart from the above can customize a lot of things, e.g. 
* Set `gridType` to `GridType.squareFixedColumns` or `GridType.squareFixedWidth` to use square tiles instead of the default stacked tiles.
  Or even specify your own `gridBuilder` to create your very own representation.
* Adapt the spacing between columns using [gridSpacing], defaults to `4.0`.
* Adapt the minimum number of columns shown with [gridMinColumns], which defaults to `2`.
* Create your own `gridBorderRadius` or set it to `null` to adapt the border of the shown GIFs in the grid to your liking.
* Disable search by setting [showSearch] to `false`.
* Disable the user switchting between gifs, stickers and emojy by setting [showTypeSwitcher] to `false`.
* Enable showing a high quality preview before returning a selection by setting [showPreview] to `true`.
* Set [showAttribution] to `false` to hide the attribution or specify your own attribution witdget with [attribution].
* Enable keeping the state of the currently selected type and search between invocations by setting [keepState] to `true`.
* Show you own UI on top of the GIPHY sheet after the user has selected a [GiphyGif] by setting your custom [onSelected] callback.


### Build your own Giphy Experience
Use the `widgets` package to build fully customized GIPHY solutions easily. Use the 
[API documentation](https://pub.dev/documentation/enough_giphy_flutter/latest/) and the [source](https://github.com/Enough-Software/enough_giphy_flutter) for guidance.

```dart
import 'package:enough_giphy_flutter/widgets.dart';
```

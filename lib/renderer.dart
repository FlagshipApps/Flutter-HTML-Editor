import 'dart:math';

import 'package:flutter/material.dart';
import 'package:light_html_editor/editor.dart';
import 'package:light_html_editor/placeholder.dart';
import 'package:light_html_editor/richtext/richtext_node.dart';
import 'package:light_html_editor/richtext/text_constants.dart';

///
/// Lightweight HTML renderer converting basic HTML text into Richtext
///
class RichtextRenderer extends StatelessWidget {
  ///
  /// Creates a new instance of an HTML renderer. Takes the root of a parse-tree
  /// as an argument which gets displayed.
  ///
  /// Displays an optional [label] at the bottom, styled by [labelStyle].
  ///
  /// The rendered text is padded by [padding].
  ///
  /// If a different font-size is wanted for text with unspecified font-size,
  /// [defaultFontSize] can be adapted.
  ///
  /// If a different default-text-color is wanted for text with unspecified
  /// text-color, [defaultColor] can be adapted.
  ///
  /// A border gets displayed around the rendered text per default, which can be
  /// turned off by setting [hasBorder]
  ///
  const RichtextRenderer({
    Key? key,
    @required this.root,
    this.hasBorder = true,
    this.padding = const EdgeInsets.all(4),
    this.defaultFontSize = TextConstants.defaultFontSize,
    this.defaultColor = TextConstants.defaultColor,
    this.label,
    this.maxLength,
    this.labelStyle = TextConstants.labelStyle,
    this.placeholderMarker = "\\\$",
    this.placeholders = const [],
  }) : super(key: key);

  final String? label;
  final TextStyle labelStyle;
  final DocumentNode? root;
  final bool hasBorder;
  final EdgeInsets padding;
  final Color defaultColor;
  final double defaultFontSize;
  final int? maxLength;
  final String placeholderMarker;
  final List<RichTextPlaceholder> placeholders;

  ///
  /// Creates a new instance of an HTML renderer. Takes a richtext created by
  /// [RichTextEditor] as an argument which is parsed into a ParseTree
  ///
  /// Displays an optional [label] at the bottom, styled by [labelStyle].
  ///
  /// The rendered text is padded by [padding].
  ///
  /// If a different font-size is wanted for text with unspecified font-size,
  /// [defaultFontSize] can be adapted.
  ///
  /// If a different default-text-color is wanted for text with unspecified
  /// text-color, [defaultColor] can be adapted.
  ///
  /// A border gets displayed around the rendered text per default, which can be
  /// turned off by setting [hasBorder]
  ///
  factory RichtextRenderer.fromRichtext(
    String richtext, {
    String? label,
    TextStyle labelStyle = TextConstants.labelStyle,
    bool hasBorder = true,
    EdgeInsets padding = const EdgeInsets.all(4),
    double defaultFontSize = TextConstants.defaultFontSize,
    Color defaultColor = TextConstants.defaultColor,
  }) {
    return RichtextRenderer(
      root: Parser().parse(richtext),
      label: label,
      labelStyle: labelStyle,
      hasBorder: hasBorder,
      padding: padding,
      defaultFontSize: defaultFontSize,
      defaultColor: defaultColor,
    );
  }

  ///
  /// converts a subtree into a list of [_TextNode], resulting into an in-order
  /// flattening of the subtree.
  ///
  void _processNodeNew(DocumentNode node, List<_TextNode> result) {
    for (int i = 0; i < node.text.length; i++) {
      if (node.text[i] != null && node.text[i].isNotEmpty)
        result.add(
          _TextNode(
            node.text[i],
            TextStyle(
              fontSize: node.fontSize != null ? node.fontSize : defaultFontSize,
              fontWeight: node.isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: node.isItalics ? FontStyle.italic : FontStyle.normal,
              color: node.textColor != null ? node.textColor : defaultColor,
              decoration: node.underline,
            ),
            node.invokesNewline,
          ),
        );
      if (i < node.children.length) _processNodeNew(node.children[i], result);
    }
  }

  ///
  /// Transforms the written text into an in-order representation which then gets
  /// further processed into a list of [RichText] to display.
  ///
  List<RichText> _renderText() {
    List<RichText> result = [];

    List<_TextNode> flattenedNodes = [];
    if (root != null) _processNodeNew(root!, flattenedNodes);

    List<TextSpan> tmp = [TextSpan(text: "")];

    int textLength = 0;
    bool full = false;

    for (_TextNode node in flattenedNodes) {
      String nodeText = node.text;
      if (maxLength != null && textLength + nodeText.length > maxLength!) {
        nodeText = nodeText.substring(
                0, min(maxLength! - textLength, nodeText.length)) +
            "...";
        full = true;
      }

      for (RichTextPlaceholder placeholder in placeholders) {
        String search =
            "$placeholderMarker${placeholder.symbol}$placeholderMarker";

        nodeText = nodeText.replaceAll(
          RegExp(search),
          "${placeholder.value}",
        );
      }

      tmp.add(
        TextSpan(
          text: nodeText,
          style: node.style,
        ),
      );

      if (node.invokesNewline && tmp.length > 0) {
        result.add(
          RichText(
            text: TextSpan(children: tmp),
          ),
        );
        tmp = [];
      }
    }

    if (tmp.length > 0)
      result.add(
        RichText(
          text: TextSpan(children: tmp),
        ),
      );

    if (result.length == 0)
      result.add(
        RichText(
          text: TextSpan(text: ""),
        ),
      );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: hasBorder
            ? Border.all(
                color: Colors.black,
              )
            : Border.all(
                color: Colors.transparent,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: padding,
            child: root != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: _renderText()
                        .map(
                          (RichText line) => Container(
                            child: line,
                            // decoration: BoxDecoration(
                            //   border: Border.all(
                            //     color: Colors.black,
                            //   ),
                            // ),
                          ),
                        )
                        .toList(),
                  )
                : SizedBox(
                    child: Text(" "),
                  ),
          ),
          if (label != null && label!.isNotEmpty)
            Padding(
              padding: padding,
              child: Text(
                label!,
                style: labelStyle,
              ),
            ),
        ],
      ),
    );
  }
}

///
/// representation of a single node with a corresponding [TextStyle] and if the
/// node invokes a linebreak after it
///
class _TextNode {
  final String text;
  final TextStyle style;
  final bool invokesNewline;

  _TextNode(this.text, this.style, this.invokesNewline);
}
import 'package:flutter/material.dart';
import 'package:light_html_editor/button_row.dart';
import 'package:light_html_editor/data/editor_properties.dart';
import 'package:light_html_editor/data/text_constants.dart';
import 'package:light_html_editor/placeholder.dart';
import 'package:light_html_editor/renderer.dart';
import 'package:light_html_editor/ui/selectable_textfield.dart';

import 'html_editor_controller.dart';

///
/// Lightweight HTML editor with optional preview function. Uses all width
/// available and the minimal height. Needs bounded width.
///
class RichTextEditor extends StatefulWidget {
  ///
  /// empty method
  ///
  static void _doNothingWithResult(String value) => {};

  ///
  /// Creates a new instance of a HTML text editor.
  /// [editorLabel] is displayed at the text input, styled by [labelStyle] when
  /// not focused, styled by [focusedLabelStyle] else
  ///
  /// [cursorColor] is the color of the cursor of the text input
  ///
  /// [inputStyle] text-style of the written code
  ///
  /// A rendered preview is displayed, when [showPreview] is set to [true], with
  /// an optional [previewLabel] is displayed below it
  ///
  /// [onChanged] is called each time, the HTML input changes providing the
  /// written code as parameter
  ///
  /// An optional [maxLength] can be provided, which is applied in the code input,
  /// not at the rendered text.
  ///
  /// If [initialValue] is set, the provided text is loaded into the editor.
  ///
  /// It is possible to use placeholders in the code. They have to be enclosed
  /// with [placeholderMarker]. If the marker is set to "$" for example, it could
  /// look like $VARIABLE$, which would get substituted in the richtext.
  ///
  const RichTextEditor({
    Key? key,
    this.textStyle,
    this.showPreview = true,
    this.showHeaderButton = true,
    this.initialValue,
    this.maxLength,
    this.placeholderMarker = "\\\$",
    this.placeholders = const [],
    this.onChanged = RichTextEditor._doNothingWithResult,
    this.editorDecoration = const EditorDecoration(),
    this.availableColors = TextConstants.defaultColors,
    this.alwaysShowButtons = false,
    this.controller,
    this.additionalActionButtons,
  }) : super(key: key);
  final TextStyle? textStyle;
  final bool showPreview;
  final bool showHeaderButton;
  final String? initialValue;
  final int? maxLength;
  final String placeholderMarker;
  final List<RichTextPlaceholder> placeholders;
  final List<String> availableColors;
  final bool alwaysShowButtons;
  final List<Widget>? additionalActionButtons;

  final EditorDecoration editorDecoration;
  final HtmlEditorController? controller;

  final Function(String) onChanged;

  @override
  _RichTextEditorState createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  /// used to control the HTML text and cursor position/selection
  late HtmlEditorController _controller;

  /// focusNode of the editor input field
  FocusNode _focusNode = FocusNode();

  /// handles visibility of editor-controls
  bool _areButtonsVisible = false;

  ScrollController _previewScrollController = ScrollController();

  @override
  void initState() {
    _controller = widget.controller ?? new HtmlEditorController();
    _areButtonsVisible = widget.alwaysShowButtons;

    // copy in initial value if provided
    if (_controller.text.isEmpty) _controller.text = widget.initialValue ?? "";

    // initialize event handler for hiding buttons
    if (!widget.alwaysShowButtons)
      _focusNode.addListener(() {
        setState(() {
          _areButtonsVisible = _focusNode.hasFocus;
        });
      });

    // initialize event handler for new input
    _controller.addListener(() {
      setState(() {});

      widget.onChanged(_controller.text);

      // get last character
      // int position = _textEditingController.selection.extentOffset;

      // if (position > 0) {
      //   String lastChar = _textEditingController
      //       .text[_textEditingController.selection.extentOffset - 1];

      //   if (lastChar == "\n" || true) {
      //     List<String> lines = _textEditingController.text.split("\n");
      //     int buffer = 0, lineIndex = -1;

      //     for (int i = 0; i < lines.length; i++) {
      //       String line = lines[i];

      //       buffer += line.length + 1;

      //       if (buffer > position) {
      //         lineIndex = i;
      //         break;
      //       }
      //     }

      // if (widget.showPreview) {
      //   if (lineIndex > 0) {
      //     double scrollAmount = lineIndex / (lines.length - 1);

      //     _previewScrollController.animateTo(
      //       _previewScrollController.position.maxScrollExtent *
      //           scrollAmount,
      //       duration: Duration(milliseconds: 200),
      //       curve: Curves.fastOutSlowIn,
      //     );
      //   }
      // }
      // }
      // }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.editorDecoration.backgroundColor,
      child: Column(
        children: [
          if (_areButtonsVisible) ...[
            ButtonRow(
              _controller,
              widget.availableColors,
              widget.additionalActionButtons ?? [],
            ),
            SizedBox(
              height: 8.0,
            ),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Container(
                      height: constraints.maxHeight,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 8.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      child: SelectableTextfield(
                        widget.editorDecoration,
                        _controller,
                        _focusNode,
                        maxLength: widget.maxLength,
                      ),
                    ),
                  ),
                ),
                if (widget.showPreview) ...[
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Preview",
                          style: widget.textStyle,
                        ),
                        SizedBox(
                          height: 8.0,
                        ),
                        SingleChildScrollView(
                          controller: _previewScrollController,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            child: RichtextRenderer.fromRichtext(
                              _controller.text,
                              placeholders: widget.placeholders,
                              placeholderMarker: widget.placeholderMarker,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

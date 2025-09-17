import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

final _markdownHtmlPod = Provider.family<String, String>((ref, source) {
  return md.markdownToHtml(source, extensionSet: md.ExtensionSet.gitHubWeb);
});

class MarkdownViewer extends ConsumerWidget {
  const MarkdownViewer({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final html = ref.read(_markdownHtmlPod(markdown));
    return Html(data: html, onLinkTap: null);
  }
}

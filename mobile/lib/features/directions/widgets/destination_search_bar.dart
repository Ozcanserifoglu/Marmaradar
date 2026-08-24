import 'package:flutter/material.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/directions/directions_models.dart';

class DestinationSearchBar extends StatefulWidget {
  const DestinationSearchBar({
    super.key,
    required this.query,
    required this.predictions,
    required this.isSearching,
    required this.isRouting,
    required this.onQueryChanged,
    required this.onPredictionSelected,
    required this.onClear,
    this.errorMessage,
  });

  final String query;
  final List<PlacePrediction> predictions;
  final bool isSearching;
  final bool isRouting;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PlacePrediction> onPredictionSelected;
  final VoidCallback onClear;
  final String? errorMessage;

  @override
  State<DestinationSearchBar> createState() => _DestinationSearchBarState();
}

class _DestinationSearchBarState extends State<DestinationSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant DestinationSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text &&
        widget.query != oldWidget.query) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surface,
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: widget.onQueryChanged,
            style: TextStyle(color: scheme.onSurface, fontSize: 16),
            cursorColor: AppColors.red,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Nereye?',
              hintStyle: TextStyle(color: scheme.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
              suffixIcon: _buildSuffix(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (widget.isRouting) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.route,
            backgroundColor: AppColors.outline,
          ),
        ],
        if (widget.errorMessage != null &&
            widget.errorMessage!.isNotEmpty &&
            widget.predictions.isEmpty) ...[
          const SizedBox(height: 8),
          Material(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                widget.errorMessage!,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
        if (widget.predictions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            color: scheme.surface,
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.predictions.length.clamp(0, 6),
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: scheme.outline,
              ),
              itemBuilder: (context, index) {
                final p = widget.predictions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.place_outlined,
                    color: AppColors.route,
                    size: 22,
                  ),
                  title: Text(
                    p.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    _focusNode.unfocus();
                    widget.onPredictionSelected(p);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffix() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (widget.isSearching) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: muted,
          ),
        ),
      );
    }
    if (widget.query.isEmpty) return null;
    return IconButton(
      tooltip: 'Temizle',
      icon: Icon(Icons.close, color: muted),
      onPressed: () {
        _controller.clear();
        widget.onClear();
      },
    );
  }
}

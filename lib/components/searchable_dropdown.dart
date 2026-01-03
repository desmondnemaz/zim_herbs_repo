import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

/// A generic Searchable Dropdown widget.
///
/// Displays a text field-like button that opens a dialog with a searchable list.
/// [T] is the type of item in the list.
class SearchableDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String label;
  final String Function(T) itemLabelBuilder;
  final void Function(T?) onChanged;
  final ResponsiveSize rs;
  final String? Function(T?)? validator;

  const SearchableDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.itemLabelBuilder,
    required this.onChanged,
    required this.rs,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final T? result = await showDialog<T>(
          context: context,
          builder:
              (context) => _SearchDialog<T>(
                items: items,
                itemLabelBuilder: itemLabelBuilder,
                label: label,
              ),
        );
        // We only trigger onChanged if a selection was made.
        // If the user dismissed the dialog, we do nothing (keep current value).
        if (result != null) {
          onChanged(result);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: rs.labelFont,
          ),
          floatingLabelStyle: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: rs.labelFont,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.2,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.1,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.onPrimary,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        isEmpty: value == null,
        child: Text(
          value != null ? itemLabelBuilder(value as T) : '',
          style: TextStyle(fontSize: rs.bodyFont),
        ),
      ),
    );
  }
}

/// Internal dialog used by [SearchableDropdown].
class _SearchDialog<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final String label;

  const _SearchDialog({
    required this.items,
    required this.itemLabelBuilder,
    required this.label,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  List<T> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredItems = widget.items);
      return;
    }
    setState(() {
      _filteredItems =
          widget.items
              .where(
                (item) => widget
                    .itemLabelBuilder(item)
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select ${widget.label}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: _filter,
            ),
          ),

          // List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child:
                _filteredItems.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items found',
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                widget.itemLabelBuilder(item),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.5),
                              ),
                              onTap: () => Navigator.pop(context, item),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                            ),
                            if (index != _filteredItems.length - 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Theme.of(context).dividerColor
                                    .withValues(alpha: 0.2),
                              ),
                          ],
                        );
                      },
                    ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

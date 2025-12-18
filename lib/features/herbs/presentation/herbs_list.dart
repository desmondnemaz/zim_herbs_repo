import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/components/add_edit_herb_dialog.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/components/desktop_herb_list.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/components/mobile_herb_list.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class HerbsList extends StatefulWidget {
  const HerbsList({super.key});

  @override
  State<HerbsList> createState() => _HerbsListState();
}

class _HerbsListState extends State<HerbsList> {
  String searchQuery = "";
  final HerbRepository _repository = HerbRepository();
  late Future<List<HerbModel>> _herbsFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _herbsFuture = _repository.getAllHerbs();
    });
  }

  Future<void> _handleDelete(HerbModel herb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Herb'),
            content: Text('Are you sure you want to delete "${herb.nameEn}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteHerb(herb.id);
        _refreshList();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Herb deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting herb: $e')));
        }
      }
    }
  }

  Future<void> _showAddEditDialog({HerbModel? herb}) async {
    await showDialog(
      context: context,
      builder:
          (context) => AddEditHerbDialog(
            herb: herb,
            onSave: (newHerb) async {
              try {
                if (herb == null) {
                  await _repository.createHerb(newHerb);
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Herb added')));
                  }
                } else {
                  await _repository.updateHerb(newHerb);
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Herb updated')));
                  }
                }
                _refreshList();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving herb: $e')),
                  );
                }
                rethrow;
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return Scaffold(
      appBar:
          Responsive.isDesktop(context)
              ? null
              : AppBar(
                toolbarHeight: 10,
                elevation: 0,
                backgroundColor: pharmacyTheme.colorScheme.primary,
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: pharmacyTheme.colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: pharmacyTheme.scaffoldBackgroundColor,
          ),
          child: Column(
            children: [
              // AppBar
              Container(
                padding: EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  color: pharmacyTheme.colorScheme.primary,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back,
                            color: pharmacyTheme.colorScheme.secondary,
                            size: rs.appBarIcon,
                          ),
                        ),
                        SizedBox(width: defaultPadding),
                        Text(
                          "All Herbs",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pharmacyTheme.colorScheme.secondary,
                            fontSize: rs.appBarTitleFont,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search herbs...",
                    filled: true,
                    fillColor: pharmacyTheme.colorScheme.onPrimary,
                    prefixIcon: Icon(
                      Icons.search,
                      color: pharmacyTheme.colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // HERBS LIST
              Expanded(
                child: FutureBuilder<List<HerbModel>>(
                  future: _herbsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyView();
                    }

                    final herbs = snapshot.data!;
                    final filteredHerbs =
                        herbs
                            .where(
                              (h) =>
                                  h.nameEn.toLowerCase().contains(
                                    searchQuery.toLowerCase(),
                                  ) ||
                                  (h.nameSn?.toLowerCase().contains(
                                        searchQuery.toLowerCase(),
                                      ) ??
                                      false),
                            )
                            .toList();

                    if (filteredHerbs.isEmpty) {
                      return _buildEmptyView();
                    }

                    return Responsive.isMobile(context)
                        ? MobileHerbList(
                          filteredHerbs: filteredHerbs,
                          rs: rs,
                          onEdit: (herb) => _showAddEditDialog(herb: herb),
                          onDelete: _handleDelete,
                        )
                        : DesktopHerbList(
                          filteredHerbs: filteredHerbs,
                          rs: rs,
                          onEdit: (herb) => _showAddEditDialog(herb: herb),
                          onDelete: _handleDelete,
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No herbs available' : 'No herbs found',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/bloc/herb_bloc.dart';
import 'package:zim_herbs_repo/features/herbs/bloc/herb_event.dart';
import 'package:zim_herbs_repo/features/herbs/bloc/herb_state.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/components/desktop_herb_list.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/components/mobile_herb_list.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/add_edit_herb_page.dart';

class HerbsList extends StatefulWidget {
  const HerbsList({super.key});

  @override
  State<HerbsList> createState() => _HerbsListState();
}

class _HerbsListState extends State<HerbsList> {
  // We no longer need _herbsFuture or searchQuery here!
  // The BLoC will manage those for us.
  final HerbRepository _repository = HerbRepository();

  @override
  void initState() {
    super.initState();
    // No initState logic needed here if we use BlocProvider(create: ...)
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

        // This is a "Human" touch: After deleting, we tell the chef (Bloc)
        // to refresh the meal (List).
        if (mounted) {
          context.read<HerbBloc>().add(RefreshHerbs());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Herb deleted')));
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditHerbPage(herb: herb)),
    );

    if (result == true) {
      // If the page returned "true", it means something changed.
      // Tell the Bloc to reload.
      if (mounted) {
        context.read<HerbBloc>().add(RefreshHerbs());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    // STEP 1: Wrap everything in a BlocProvider so the children can find the "Chef"
    return BlocProvider(
      create: (context) => HerbBloc(_repository)..add(LoadHerbs()),
      child: Scaffold(
        appBar:
            Responsive.isDesktop(context)
                ? null
                : AppBar(
                  toolbarHeight: 10,
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
        floatingActionButton: Builder(
          builder:
              (context) => FloatingActionButton(
                tooltip: 'Add Herb',
                onPressed: () => _showAddEditDialog(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 4,
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(context, rs),

                // Search Bar
                _buildSearchBar(context),

                // HERBS LIST (The cool part!)
                Expanded(
                  // STEP 2: Use BlocBuilder to listen to our Chef
                  child: BlocBuilder<HerbBloc, HerbState>(
                    builder: (context, state) {
                      // Case A: Chef is busy
                      if (state is HerbLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Case B: Something went wrong
                      if (state is HerbError) {
                        return Center(child: Text(state.message));
                      }

                      // Case C: Success! We have herbs
                      if (state is HerbLoaded) {
                        if (state.herbs.isEmpty) {
                          return _buildEmptyView(state.searchQuery);
                        }

                        // Just pass the list from the state to our widgets
                        return Responsive.isMobile(context)
                            ? MobileHerbList(
                              filteredHerbs: state.herbs,
                              rs: rs,
                              onEdit: (herb) => _showAddEditDialog(herb: herb),
                              onDelete: _handleDelete,
                            )
                            : DesktopHerbList(
                              filteredHerbs: state.herbs,
                              rs: rs,
                              onEdit: (herb) => _showAddEditDialog(herb: herb),
                              onDelete: _handleDelete,
                            );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveSize rs) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.secondary,
              size: rs.appBarIcon,
            ),
          ),
          SizedBox(width: defaultPadding),
          BlocBuilder<HerbBloc, HerbState>(
            builder: (context, state) {
              String title = "All Herbs";
              if (state is HerbLoaded) {
                title = "All Herbs (${state.herbs.length})";
              }
              return Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: rs.appBarTitleFont,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        onChanged: (value) {
          // STEP 3: Instead of setState, we just send a new Order (Event) to the Chef
          context.read<HerbBloc>().add(SearchHerbs(value));
        },
        decoration: InputDecoration(
          hintText: "Search herbs...",
          filled: true,
          fillColor: Theme.of(context).colorScheme.onPrimary,
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'No herbs available'
                : 'No herbs found for "$query"',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

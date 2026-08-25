import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/categories.dart';
import '../models/opportunity.dart';
import '../providers/opportunity_provider.dart';
import '../widgets/header_widget.dart';
import '../widgets/opportunity_card.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectAll(List<Opportunity> list) {
    setState(() {
      if (_selectedIds.length == list.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(list.map((o) => o.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();
    final filtered = provider.filteredOpportunities;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const MarakadheyHeader(),

          // Search & Filter Header Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => provider.setSearchQuery(v),
                  decoration: InputDecoration(
                    hintText: 'Search title, tag (#job), URL, note...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Category & Priority Dropdowns
                Row(
                  children: [
                    // Category Filter Dropdown
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedCategory,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                            items: [
                              const DropdownMenuItem(
                                value: 'ALL',
                                child: Text('All Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              ...AppConstants.categories.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                );
                              }),
                            ],
                            onChanged: (v) {
                              if (v != null) provider.setSelectedCategory(v);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Priority Filter Dropdown
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedPriority,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                            items: const [
                              DropdownMenuItem(
                                value: 'ALL',
                                child: Text('All Priorities', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              DropdownMenuItem(
                                value: 'HIGH',
                                child: Text('🔴 High Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                              ),
                              DropdownMenuItem(
                                value: 'MEDIUM',
                                child: Text('🟡 Medium Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                              ),
                              DropdownMenuItem(
                                value: 'LOW',
                                child: Text('🟢 Low Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) provider.setSelectedPriority(v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Tabs (Horizontal Scrollable Pills)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _buildTabPill('all', 'All', provider.opportunities.length, provider),
                  _buildTabPill('pending', 'Pending', provider.pendingCount, provider),
                  _buildTabPill('urgent', '⚡ Urgent (48h)', provider.urgentCount, provider),
                  _buildTabPill('today', 'Today', provider.todayCount, provider),
                  _buildTabPill('upcoming', 'Upcoming', provider.upcomingCount, provider),
                  _buildTabPill('recurring', '🔄 Recurring', provider.recurringCount, provider),
                  _buildTabPill('completed', 'Done', provider.completedCount, provider),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Batch Selection Header (when active)
          if (_isSelectionMode)
            Container(
              color: const Color(0xFFFFF7ED),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedIds.length == filtered.length && filtered.isNotEmpty,
                    activeColor: AppColors.primary,
                    onChanged: (_) => _toggleSelectAll(filtered),
                  ),
                  Text(
                    '${_selectedIds.length} Selected',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondary, fontSize: 13),
                  ),
                  const Spacer(),
                  // Batch Complete
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Color(0xFF15803D)),
                    tooltip: 'Mark Completed',
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            provider.batchComplete(_selectedIds.toList());
                            setState(() {
                              _selectedIds.clear();
                              _isSelectionMode = false;
                            });
                          },
                  ),
                  // Batch Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                    tooltip: 'Delete Selected',
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            provider.batchDelete(_selectedIds.toList());
                            setState(() {
                              _selectedIds.clear();
                              _isSelectionMode = false;
                            });
                          },
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedIds.clear();
                        _isSelectionMode = false;
                      });
                    },
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Main Opportunities List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(provider)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = _selectedIds.contains(item.id);

                      if (_isSelectionMode) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(item.id);
                              } else {
                                _selectedIds.add(item.id);
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedIds.add(item.id);
                                      } else {
                                        _selectedIds.remove(item.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: OpportunityCard(opportunity: item),
                              ),
                            ],
                          ),
                        );
                      }

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: const Color(0xFFEF4444),
                          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
                        ),
                        onDismissed: (_) {
                          provider.deleteOpportunity(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted "${item.title}"'),
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: AppColors.primary,
                                onPressed: () {},
                              ),
                            ),
                          );
                        },
                        child: GestureDetector(
                          onLongPress: () {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedIds.add(item.id);
                            });
                          },
                          child: OpportunityCard(opportunity: item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String filterKey, String label, int count, OpportunityProvider provider) {
    final isSelected = provider.selectedFilter == filterKey;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => provider.setSelectedFilter(filterKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(OpportunityProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFED7AA), width: 2),
              ),
              child: const Icon(Icons.inbox_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Opportunities Here',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'No results matching "${provider.searchQuery}". Try a different keyword or filter.'
                  : 'You have no opportunities under this filter.\nShare a link from Chrome or create one below!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

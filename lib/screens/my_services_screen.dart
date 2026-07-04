import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/screens/widgets/add_service_sheet.dart';
import 'package:tour_guid/screens/widgets/service_card.dart';
import 'package:tour_guid/utils/app_localization.dart';
import '../providers/service_peovider.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus; // null = all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedStatus = null;
            break;
          case 1:
            _selectedStatus = 'pending';
            break;
          case 2:
            _selectedStatus = 'approved';
            break;
          case 3:
            _selectedStatus = 'rejected';
            break;
        }
      });
    });
    Future.microtask(() {
      if (mounted) {
        Provider.of<ServiceProvider>(context, listen: false).fetchMyServices();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _filteredServices(List<dynamic> all) {
    if (_selectedStatus == null) return all;
    return all.where((s) => s.status == _selectedStatus).toList();
  }

  Future<bool?> _confirmDelete(String serviceTitle) {
    final t = AppLocalizations.of(context).t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t('delete_service'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          t('are_you_sure_delete_service'),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel'),
                style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(int serviceId) async {
    final t = AppLocalizations.of(context).t;
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final result = await serviceProvider.deleteService(serviceId: serviceId);
    if (!mounted) return;
    final success = result['success'] == true;
    HapticFeedback.lightImpact();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: Colors.white,
            size: 20),
        const SizedBox(width: 10),
        Text(success
            ? t('service_deleted_successfully')
            : t('failed_to_delete_service')),
      ]),
      backgroundColor: success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final t = AppLocalizations.of(context).t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final myServices = serviceProvider.myServices;
    final isLoading = serviceProvider.isLoadingMyServices;

    final pendingCount = myServices.where((s) => s.status == 'pending').length;
    final approvedCount = myServices.where((s) => s.status == 'approved').length;
    final rejectedCount = myServices.where((s) => s.status == 'rejected').length;
    final filtered = _filteredServices(myServices);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── Gradient Header ────────────────────────────────────────────
          _buildHeader(context, t, primary, myServices.length,
              pendingCount, approvedCount, rejectedCount),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => serviceProvider.fetchMyServices(),
              color: primary,
              child: isLoading && myServices.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _buildEmpty(context, t, isDark, primary)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final service = filtered[index];
                            return _ServiceItem(
                              service: service,
                              index: index,
                              onDelete: _confirmDelete,
                              onDeleteConfirmed: _deleteService,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () async {
          await openAddServiceSheet(context);
          if (mounted) {
            Provider.of<ServiceProvider>(context, listen: false)
                .fetchMyServices();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(t('add_service')),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String Function(String) t,
    Color primary,
    int total,
    int pending,
    int approved,
    int rejected,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      t('my_services'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Provider.of<ServiceProvider>(context, listen: false)
                            .fetchMyServices(),
                    icon: const Icon(Icons.refresh, color: Colors.white70, size: 22),
                    tooltip: t('refresh'),
                  ),
                ],
              ),
            ),

            // Stats chips
            if (total > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _StatChip(
                        count: total,
                        label: t('all'),
                        color: Colors.white,
                        bg: Colors.white24),
                    if (pending > 0)
                      _StatChip(
                          count: pending,
                          label: t('status_pending'),
                          color: const Color(0xFFF59E0B),
                          bg: const Color(0xFFF59E0B).withOpacity(0.22)),
                    if (approved > 0)
                      _StatChip(
                          count: approved,
                          label: t('status_approved'),
                          color: const Color(0xFF22C55E),
                          bg: const Color(0xFF22C55E).withOpacity(0.22)),
                    if (rejected > 0)
                      _StatChip(
                          count: rejected,
                          label: t('status_rejected'),
                          color: const Color(0xFFEF4444),
                          bg: const Color(0xFFEF4444).withOpacity(0.22)),
                  ],
                ),
              ),

            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal, fontSize: 13),
              tabs: [
                Tab(text: '${t('all')} ($total)'),
                Tab(text: '${t('status_pending')} ($pending)'),
                Tab(text: '${t('status_approved')} ($approved)'),
                Tab(text: '${t('status_rejected')} ($rejected)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(
      BuildContext context, String Function(String) t, bool isDark, Color primary) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.storefront_outlined,
                    size: 56, color: primary.withOpacity(0.45)),
              ),
              const SizedBox(height: 20),
              Text(
                _selectedStatus == null
                    ? t('my_services_empty')
                    : t('no_services_in_status'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color bg;

  const _StatChip({
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Service Item ──────────────────────────────────────────────────────────────

class _ServiceItem extends StatelessWidget {
  final dynamic service;
  final int index;
  final Future<bool?> Function(String) onDelete;
  final Future<void> Function(int) onDeleteConfirmed;

  const _ServiceItem({
    required this.service,
    required this.index,
    required this.onDelete,
    required this.onDeleteConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (service.status) {
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.hourglass_top_rounded;
        statusLabel = t('status_pending');
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_outlined;
        statusLabel = t('status_rejected');
        break;
      default: // approved
        statusColor = const Color(0xFF22C55E);
        statusIcon = Icons.check_circle_outline;
        statusLabel = t('status_approved');
    }

    return Dismissible(
      key: Key('myservice_${service.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(t('delete'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) => onDelete(service.title),
      onDismissed: (_) => onDeleteConfirmed(service.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            margin: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                top: BorderSide(color: statusColor.withOpacity(0.4), width: 1),
                left: BorderSide(color: statusColor.withOpacity(0.4), width: 1),
                right:
                    BorderSide(color: statusColor.withOpacity(0.4), width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                if (service.status == 'rejected' &&
                    service.rejectionReason != null &&
                    service.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '· ${service.rejectionReason}',
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Service card
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: SizedBox(
              height: 220,
              child: ServiceCard(
                service: service,
                index: index,
                fromWhere: 'myServices',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

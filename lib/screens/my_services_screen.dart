import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/screens/widgets/add_service_sheet.dart';
import 'package:tour_guid/screens/widgets/service_card.dart';
import 'package:tour_guid/utils/app_icons.dart';
import 'package:tour_guid/utils/app_localization.dart';
import '../providers/service_peovider.dart';

class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final t = AppLocalizations.of(context).t;

    // ✅ Filter services belonging to logged-in user (using Supabase UUID)
    final myServices = serviceProvider.services
        .where((s) => s.supabaseUserId != null &&
                      s.supabaseUserId == authProvider.supabaseUserId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppBackButton.light(),
        ),
        title: Text(t('my_services')),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await serviceProvider.fetchAllServices();
        },
        child: myServices.isEmpty
            ? Center(
          child: Text(
            t('no_services_yet'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: myServices.length,
            itemBuilder: (context, index) {
              final service = myServices[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 230,
                  child: ServiceCard(
                    service: service,
                    index: index, fromWhere: 'myServices',
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () => openAddServiceSheet(context),
        icon: const Icon(Icons.add),
        label: Text(t('add_service')),
      ),
    );
  }
}
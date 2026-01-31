import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/utils/app_localization.dart';

import '../../utils/map_launcher.dart';
import 'login_prompt_dialog.dart';

class MapButton extends StatelessWidget {
  final double width;
  final double height;
  final double lat;
  final double lng;
  final String placeName;
  const MapButton({required this.placeName,required this.lat,required this.lng,super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final loc=AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton.icon(
        onPressed: () async{
          // Check if user is authenticated
          if (authProvider.user == null) {
            showLoginPromptDialog(context, feature: 'view_location');
            return;
          }

          await  MapLauncher.openMaps(
            context: context,
            latitude:lat,
            longitude: lng,
            placeName: placeName,
          );
        },
        icon: const Icon(Icons.location_on_outlined, color: Colors.white),
        label:  Text(loc.t('show_on_map'),
            style: TextStyle(color: Colors.white)),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A2C),
          side: const BorderSide(color: Color(0xFF1E3A2C), width: 1.5),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
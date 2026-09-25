import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/kunde.dart';
import 'kunde_edit_screen.dart';

class KundeDetailScreen extends StatefulWidget {
  final Kunde kunde;

  const KundeDetailScreen({super.key, required this.kunde});

  @override
  State<KundeDetailScreen> createState() => _KundeDetailScreenState();
}

class _KundeDetailScreenState extends State<KundeDetailScreen> {
  late Kunde _currentKunde;

  @override
  void initState() {
    super.initState();
    _currentKunde = widget.kunde;
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KundeEditScreen(kunde: _currentKunde),
      ),
    );

    if (result == 'DELETE') {
      if (mounted) Navigator.pop(context, 'DELETE');
    } else if (result is Kunde) {
      setState(() {
        _currentKunde = result;
      });
      // Zwracamy zaktualizowany obiekt przy powrocie
      if (mounted) Navigator.pop(context, result);
    }
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 100,
    );

    if (pickedFile != null && mounted) {
      final croppedPath = await _cropCircleImage(context, pickedFile.path);
      if (croppedPath != null) {
        setState(() {
        _currentKunde.profileImageUrl = croppedPath;
        widget.kunde.profileImageUrl = croppedPath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zaktualizowano zdjęcie profilowe'),
            duration: Duration(seconds: 3)
            ),
        );
      }
      }
    }
  }

  void _handleAvatarTap() {
    final path = _currentKunde.profileImageUrl;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    if (hasImage) {
      _viewImageFullscreen(path);
    } else {
      _changeAvatar();
    }
  }

  void _viewImageFullscreen(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.crop),
                  tooltip: 'Dopasuj kadr',
                  onPressed: () async {
                    final cropped = await _cropCircleImage(ctx, imagePath);
                    if (cropped != null) {
                      setState(() {
                        _currentKunde.profileImageUrl = cropped;
                        widget.kunde.profileImageUrl = cropped;
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (val) async {
                    if (val == 'CHANGE') {
                      Navigator.pop(ctx);
                      _changeAvatar();
                    } else if (val == 'DELETE') {
                      setState(() {
                        _currentKunde.profileImageUrl = null;
                        widget.kunde.profileImageUrl = null;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usunięto zdjęcie profilowe')),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'CHANGE',
                      child: Row(
                        children: [
                          Icon(Icons.photo_library_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Zmień zdjęcie'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'DELETE',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Usuń zdjęcie', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.file(File(imagePath)),
              ),
            ),
          ),
        ),
    );
  }
  
  Future<String?> _cropCircleImage(BuildContext context, String sourcePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Dopasuj zdjęcie',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
          showCropGrid: false,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Dostosuj zdjęcie',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          cropStyle: CropStyle.circle,
        ),
      ],
    );
    return croppedFile?.path;
  }

  Future<void> _openGoogleMapsNavigation(String address) async {
    if (address.trim().isEmpty) return;
    final encodedAddress = Uri.encodeComponent(address.trim());
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedAddress');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie można otworzyć mapy')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = _currentKunde;
    final isAvailable = k.isAvailable ?? true;
    final isMale = k.geschlecht.toLowerCase().startsWith('m');
    final statusText = isAvailable
          ? (isMale ? '● Dostępny' : '● Dostępna')
          : (isMale ? '○ Niedostępny' : '○ Niedostępna');

    final purpleTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
        ),
      scaffoldBackgroundColor: const Color(0xFFF7F5FA),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _currentKunde);
      },
      child: Theme(
        data: purpleTheme,
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
          leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _currentKunde),
        ),
        title: Text('Podopieczny'),
        backgroundColor: purpleTheme.colorScheme.primaryContainer,
        foregroundColor: purpleTheme.colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edytuj profil',
            onPressed: _openEdit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Karta nagłówkowa z awatarem i statusem
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _handleAvatarTap,
                    child: Stack(
                      children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.deepPurple.shade50,
                    backgroundImage: (k.profileImageUrl != null &&
                            k.profileImageUrl!.isNotEmpty &&
                            File(k.profileImageUrl!).existsSync())
                        ? FileImage(File(k.profileImageUrl!))
                        : null,
                    child: (k.profileImageUrl == null || k.profileImageUrl!.isEmpty)
                        ? Text(
                            '${k.vorname.isNotEmpty ? k.vorname[0] : ""}${k.name.isNotEmpty ? k.name[0] : ""}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${k.vorname} ${k.name}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: k.anschrift.isNotEmpty ? () => _openGoogleMapsNavigation(k.anschrift) : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: k.anschrift.isNotEmpty ? Colors.deepPurple : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    k.anschrift.isNotEmpty ? k.anschrift : 'Brak adresu',
                                    style: TextStyle(
                                      color: k.anschrift.isNotEmpty ? Colors.deepPurple.shade700 : Colors.grey.shade600,
                                      fontSize: 13,
                                      decoration: k.anschrift.isNotEmpty ? TextDecoration.underline : TextDecoration.none,
                                      decorationColor: Colors.deepPurple.shade200,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (k.isAvailable ?? true) ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: (k.isAvailable ?? true) ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dane podstawowe
          _buildInfoCard(
            title: 'Dane osobowe',
            icon: Icons.badge_outlined,
            children: [
              _buildDetailRow(Icons.wc_outlined, 'Płeć', k.geschlecht),
              _buildDetailRow(Icons.cake_outlined, 'Data urodzenia', k.geburtsdatum?.isNotEmpty == true ? k.geburtsdatum! : 'Nie podano'),
              _buildDetailRow(Icons.phone_outlined, 'Telefon', k.telNr.isNotEmpty ? k.telNr : 'Nie podano'),
              _buildDetailRow(Icons.favorite_outline, 'Stan cywilny', k.familienstand),
              _buildDetailRow(Icons.money_outlined, 'Stawka dniowa', k.tagessatz != null ? '${k.tagessatz} € / dzień' : 'Nie podano'),
            ],
          ),
          const SizedBox(height: 16),

          if (k.vornameAnsprechperson != null && k.vornameAnsprechperson!.trim().isNotEmpty) ...[
          _buildInfoCard(
            title: 'Osoba do kontaktu',
            icon: Icons.badge_outlined,
            children: [
              _buildDetailRow(Icons.person, 'Imię', k.vornameAnsprechperson),
              _buildDetailRow(Icons.person_outlined, 'Nazwisko', k.nachnameAnsprechperson),
              _buildDetailRow(Icons.phone_outlined, 'Telefon', k.telNrAnsprechperson),
              _buildDetailRow(Icons.home_outlined, 'Adres', k.anschriftAnsprechperson),
              _buildDetailRow(Icons.alternate_email, 'Mail', k.emailAnsprechperson),
              _buildDetailRow(Icons.favorite, 'Relacja', k.bezugAnsprechperson),
            ],
          ),
          ],
          // Kwalifikacje
          _buildInfoCard(
            title: 'Zdrowie i choroby',
            icon: Icons.verified_outlined,
            children: [
              _buildDetailRow(Icons.verified_outlined, 'Stopień opieki', k.pflegegrad != null ? 'Pflegegrad ${k.pflegegrad}' : 'Brak'),
              _buildDetailRow(Icons.monitor_weight_outlined, 'Waga', k.gewicht != null ? '${k.gewicht} kg' : 'Nie podano'),
              _buildDetailRow(Icons.height_outlined, 'Wzrost', k.groesse != null ? '${k.groesse} cm' : 'Nie podano'),
              _buildDetailRow(Icons.medication_outlined, 'Dzielenie leków', k.medikamenteVerteilung.isEmpty ? 'Nie określono' : k.medikamenteVerteilung.map((id) => KundeOptions.findLabel(KundeOptions.medikamenteVerteilung, id)).join(' oraz '),),
              
              const Divider(height: 12),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.wc_outlined, size: 18, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    'Toaleta i fizjologia',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              () {
                final items = k.toilettenGang.map((id) => KundeOptions.findLabel(KundeOptions.toilettenGang, id)).toList();
                if (k.krankheiten.contains('inkontinenz') && !k.toilettenGang.contains('inkontinenz')) {
                  items.add('Inkontynencja moczowa');
                }
                if (k.hilfsmittel.contains('toilettenstuhl') && !k.toilettenGang.contains('toilettenstuhl')) {
        items.add('Krzesło toaletowe');
                }

                if (items.isEmpty) {
                  return const Text('Samodzielnie / Brak problemów', style: TextStyle(color: Colors.grey, fontSize: 13));
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.map((label) {
                  final isCritical = label.toLowerCase().contains('cewnik') ||
                                      label.toLowerCase().contains('stomia');
                  return Chip(
                    avatar: Icon(
                      isCritical ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      size: 15,
                      color: isCritical ? Colors.amber.shade900 : Colors.deepPurple,
                    ),
                    label: Text(label),
                    backgroundColor: isCritical ? Colors.amber.shade50 : Colors.deepPurple.shade50,
                    side: BorderSide(color: isCritical ? Colors.amber.shade200 : Colors.deepPurple.shade100),
                  );
                  }).toList(),
                );
              }(),
              const SizedBox(height: 10),
              const Divider(height: 12),
              const SizedBox(height: 12),
              const Text('Choroby', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),),
              const SizedBox(height: 8),
              if (k.krankheiten.isEmpty)
                const Text('Brak zdiagnozowanych chorób', style: TextStyle(color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: k.krankheiten.map((id) {
                    final label = KundeOptions.findLabel(KundeOptions.krankheiten, id);
                    return Chip(
                      avatar: const Icon(Icons.healing, size: 16, color: Colors.deepPurple),
                      label: Text(label),
                      backgroundColor: Colors.deepPurple.shade50,
                      side: BorderSide(color: Colors.deepPurple.shade100),
                    );
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Preferencje zlecenia
          _buildInfoCard(
            title: 'Wymagane czynności i pomoce',
            icon: Icons.assignment_outlined,
            children: [
              if (k.hilfsarbeiten.isEmpty && k.hausarbeiten.isEmpty && k.hilfsmittel.isEmpty)
                const Text('Brak zdefiniowanych zadań', style: TextStyle(color: Colors.grey))
              else ...[
                if (k.hilfsarbeiten.isNotEmpty) ...[
                  const Text(
                    'Pomoc przy osobie:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: k.hilfsarbeiten.map((id) {
                      return Chip(
                        label: Text(KundeOptions.findLabel(KundeOptions.hilfsarbeiten, id)),
                        backgroundColor: Colors.purple.shade50,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (k.hausarbeiten.isNotEmpty) ...[
                  const Text(
                    'Prowadzenie domu:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: k.hausarbeiten.map((id) {
                      return Chip(
                        label: Text(KundeOptions.findLabel(KundeOptions.hausarbeiten, id)),
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),
                ],
                if (k.hilfsmittel.isNotEmpty) ...[
                  const Text(
                    'Dostępne pomoce:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (k.hilfsmittel.contains('pflegedienst'))
                        Chip(
                          avatar: const Icon(Icons.local_hospital_outlined, size: 16, color: Colors.deepPurple),
                          label: Text(
                            k.pflegedienstHaeufigkeit != null && k.pflegedienstHaeufigkeit!.isNotEmpty ? 'Pflegedienst: ${k.pflegedienstHaeufigkeit}' : 'Pflegedienst',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.deepPurple),
                          ),
                          backgroundColor: Colors.deepPurple.shade50,
                          side: BorderSide(color: Colors.deepPurple.shade200),
                        ),
                      
                      ...k.hilfsmittel.where((id) => id != 'pflegedienst').map((id) {
                      return Chip(
                        label: Text(KundeOptions.findLabel(KundeOptions.hilfsmittel, id)),
                        backgroundColor: Colors.grey.shade100,
                      );
                    }),
                    ],
                  ),
                ],
              ],
            ],
          ),

          const SizedBox(height: 4),
          _buildInfoCard(
            title: 'Wymogi dotyczące opiekuna',
            icon: Icons.badge_outlined,
            children: [
              _buildCheckRow(Icons.smoke_free_outlined, 'Niepaląca osoba', k.hasHilfsarbeiten('rauchen')),
              _buildCheckRow(Icons.nightlight_round_outlined, 'Opieka w nocy', k.hasHilfsarbeiten('nachtarbeiten')),
              _buildCheckRow(Icons.yard_outlined, 'Prace w ogrodzie', k.hasHilfsarbeiten('gartenarbeiten')),
              _buildDetailRow(Icons.translate_outlined, 'Znajomość niemieckiego', k.deutschForderungen),
              _buildDetailRow(Icons.wc_outlined, 'Preferowana płeć opiekuna', k.betreuerGeschlecht),
              _buildDetailRow(Icons.directions_car_outlined, 'Prawo jazdy', k.fuehrerschein),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            title: 'Warunki mieszkaniowe',
            icon: Icons.badge_outlined,
            children: [
              _buildDetailRow(Icons.location_city_outlined, 'Miejsce pobytu', k.betreuungsOrt),
              _buildDetailRow(Icons.night_shelter_outlined, 'Sytuacja mieszkalna', k.wohnortSituation),
            const SizedBox(height: 10),
            const Text(
              'Wyposażenie pokoju:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)
            ),
            const SizedBox(height: 6),
            if (k.zimmerausstattung.isEmpty)
              const Text('Brak zdefiniowanego wyposażenia', style: TextStyle(color: Colors.black54))
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: k.zimmerausstattung.map((id) {
                  final label = KundeOptions.findLabel(KundeOptions.zimmerausstattung, id);
                  return Chip(
                    avatar: const Icon(Icons.check, size: 16, color: Colors.deepPurple),
                    label: Text(label),
                    backgroundColor: Colors.deepPurple.shade50,
                    side: BorderSide(color: Colors.deepPurple.shade100),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
      ),
    ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCheckRow(IconData icon, String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          const Spacer(),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: value ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            value ? 'Tak' : 'Nie',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: value ? Colors.green.shade800 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
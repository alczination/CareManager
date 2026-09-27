import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/turnus.dart';
import '../../models/kunde.dart';
import '../../models/betreuer.dart';
import '../../services/pdf_service.dart';
import '../../services/turnus_service.dart';
import '../kalendarz/add_turnus_dialog.dart';
import 'betreuer_edit_screen.dart';

class BetreuerDetailScreen extends StatefulWidget {
  final Betreuer betreuer;
  final VoidCallback? onDataChanged;

  const BetreuerDetailScreen({
    super.key,
    required this.betreuer,
    this.onDataChanged,
  });

  @override
  State<BetreuerDetailScreen> createState() => _BetreuerDetailScreenState();
}

class _BetreuerDetailScreenState extends State<BetreuerDetailScreen> with SingleTickerProviderStateMixin {
  static const String _turnusStorageKey = 'turnus_database_v1';
  List<Turnus> _myTurnusy = [];
  bool _isLoadingTurnusy = true;
  late Betreuer _currentBetreuer;

  late AnimationController _fabAnimationController;
  late Animation<double> _expandAnimation;
  bool _isFabOpen = false;

  @override
  void initState() {
    super.initState();
    _currentBetreuer = widget.betreuer;
    _loadTurnusyForBetreuer();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleFabMenu() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _closeFabMenu() {
    if (_isFabOpen) {
      setState(() {
        _isFabOpen = false;
        _fabAnimationController.reverse();
      });
    }
  }

  Future<void> _loadTurnusyForBetreuer() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_turnusStorageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final allTurnusy = decoded.map((e) => Turnus.fromJson(e)).toList();
        final myFiltered = allTurnusy.where((t) {
          return t.betreuerId == widget.betreuer.id ||
              t.betreuerName.trim() ==
                  '${widget.betreuer.vorname} ${widget.betreuer.name}'.trim();
        }).toList();
        myFiltered.sort((a, b) => b.startDate.compareTo(a.startDate));
        if (mounted) {
          setState(() {
            _myTurnusy = myFiltered;
            _isLoadingTurnusy = false;
          });
        }
        return;
      } catch (e) {
        debugPrint('Błąd odczytu turnusów opiekuna: $e');
      }
    }

    if (mounted) {
      setState(() {
        _myTurnusy = [];
        _isLoadingTurnusy = false;
      });
    }
  }

  Future<void> _addNewTurnusForThisBetreuer() async {
    _closeFabMenu();
    final createdTurnus = await TurnusService.planAndSaveTurnus(
      context: context,
      lockedBetreuer: _currentBetreuer,
    );

    if (createdTurnus != null && mounted) {
      await _loadTurnusyForBetreuer();
      widget.onDataChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Planowanie wyjazdu dla ${_currentBetreuer.vorname}'),
      ),
    );
  }
}

  Future<void> _confirmDeleteProfile() async {
    _closeFabMenu();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń profil'),
        content: Text(
          'Czy na pewno chcesz usunąć profil ${_currentBetreuer.vorname} ${_currentBetreuer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.pop(context, 'DELETE');
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BetreuerEditScreen(betreuer: _currentBetreuer),
      ),
    );

    if (result == 'DELETE') {
      if (mounted) Navigator.pop(context, 'DELETE');
    } else if (result is Betreuer) {
      setState(() {
        _currentBetreuer = result;
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
          _currentBetreuer.profileImageUrl = croppedPath;
          widget.betreuer.profileImageUrl = croppedPath;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zaktualizowano zdjęcie profilowe'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _handleAvatarTap() {
    final path = _currentBetreuer.profileImageUrl;
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
                      _currentBetreuer.profileImageUrl = cropped;
                      widget.betreuer.profileImageUrl = cropped;
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
                      _currentBetreuer.profileImageUrl = null;
                      widget.betreuer.profileImageUrl = null;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Usunięto zdjęcie profilowe'),
                      ),
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
                        Text(
                          'Usuń zdjęcie',
                          style: TextStyle(color: Colors.red),
                        ),
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

  Future<String?> _cropCircleImage(
    BuildContext context,
    String sourcePath,
  ) async {
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final currentTurnus = _myTurnusy.cast<Turnus?>().firstWhere(
      (t) => !today.isBefore(t!.startDate) && !today.isAfter(t.endDate),
      orElse: () => null,
    );
    final upcomingTurnusy =
        _myTurnusy.where((t) => today.isBefore(t.startDate)).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final pastTurnusy = _myTurnusy
        .where((t) => today.isAfter(t.endDate))
        .toList();
    final totalDays = _myTurnusy.fold<int>(
      0,
      (sum, item) => sum + item.durationInDays,
    );
    final b = _currentBetreuer;
    final isAvailable = b.isAvailable ?? true;
    final isMale = b.geschlecht.toLowerCase().startsWith('m');
    final statusText = isAvailable
        ? (isMale ? '● Dostępny do zlecenia' : '● Dostępna do zlecenia')
        : (isMale ? '○ Niedostępny' : '○ Niedostępna');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _currentBetreuer);
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _currentBetreuer),
          ),
          title: Text('${b.vorname} ${b.name}'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.picture_as_pdf_outlined),
          //     tooltip: 'Generuj profil PDF',
          //     onPressed: () => PdfService.showPdfOptionsAndGenerate(context, b),
          //   ),
          //   IconButton(
          //     icon: const Icon(Icons.edit_outlined),
          //     tooltip: 'Edytuj profil',
          //     onPressed: _openEdit,
          //   ),
          // ],
        ),
        floatingActionButton: _buildSpeedDialFab(),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage:
                                (b.profileImageUrl != null &&
                                    b.profileImageUrl!.isNotEmpty &&
                                    File(b.profileImageUrl!).existsSync())
                                ? FileImage(File(b.profileImageUrl!))
                                : null,
                            child:
                                (b.profileImageUrl == null ||
                                    b.profileImageUrl!.isEmpty)
                                ? Text(
                                    '${b.vorname.isNotEmpty ? b.vorname[0] : ""}${b.name.isNotEmpty ? b.name[0] : ""}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                            '${b.vorname} ${b.name}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b.anschrift.isNotEmpty
                                ? b.anschrift
                                : 'Brak adresu',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (b.isAvailable ?? true)
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: (b.isAvailable ?? true)
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
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
                _buildDetailRow(Icons.wc_outlined, 'Płeć', b.geschlecht),
                _buildDetailRow(
                  Icons.cake_outlined,
                  'Data urodzenia',
                  b.geburtsdatum?.isNotEmpty == true
                      ? b.geburtsdatum!
                      : 'Nie podano',
                ),
                _buildDetailRow(
                  Icons.place_outlined,
                  'Miejsce urodzenia',
                  b.geburtsort?.isNotEmpty == true
                      ? b.geburtsort!
                      : 'Nie podano',
                ),
                _buildDetailRow(
                  Icons.phone_outlined,
                  'Telefon',
                  b.telNr.isNotEmpty ? b.telNr : 'Nie podano',
                ),
                _buildDetailRow(
                  Icons.alternate_email,
                  'Mail',
                  b.email ?? 'Nie podano',
                ),
                _buildDetailRow(
                  Icons.favorite_outline,
                  'Stan cywilny',
                  b.familienstand,
                ),
                _buildDetailRow(
                  Icons.flag_circle_outlined,
                  'Narodowość',
                  b.nationalitat.isNotEmpty
                      ? b.nationalitat.join(', ')
                      : 'Nie podano',
                ),
                _buildDetailRow(
                  Icons.church_outlined,
                  'Religia',
                  b.religion.isEmpty ? 'Nie podano' : b.religion.join(', '),
                ),
                _buildDetailRow(
                  Icons.child_care_outlined,
                  'Dzieci',
                  b.hasKinder != true || b.kinder.isEmpty
                      ? (b.hasKinder == true ? 'Tak' : 'Brak')
                      : b.kinder.join(', '),
                ),
                _buildDetailRow(
                  Icons.palette_outlined,
                  'Hobby',
                  b.hobbys.isEmpty ? 'Brak' : b.hobbys.join(', '),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (b.vornameAnsprechperson != null &&
                b.nachnameAnsprechperson != null) ...[
              _buildInfoCard(
                title: 'Osoba do kontaktu',
                icon: Icons.badge_outlined,
                children: [
                  _buildDetailRow(
                    Icons.person,
                    'Imię',
                    b.vornameAnsprechperson ?? 'Nie podano',
                  ),
                  _buildDetailRow(
                    Icons.person_outlined,
                    'Nazwisko',
                    b.nachnameAnsprechperson ?? 'Nie podano',
                  ),
                  _buildDetailRow(
                    Icons.phone_outlined,
                    'Telefon',
                    b.telNrAnsprechperson ?? 'Nie podano',
                  ),
                  _buildDetailRow(
                    Icons.home_outlined,
                    'Adres',
                    b.anschriftAnsprechperson ?? 'Nie podano',
                  ),
                  _buildDetailRow(
                    Icons.favorite,
                    'Relacja',
                    b.bezugAnsprechperson ?? 'Nie podano',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Kwalifikacje
            _buildInfoCard(
              title: 'Kwalifikacje i umiejętności',
              icon: Icons.verified_outlined,
              children: [
                _buildDetailRow(
                  Icons.translate_outlined,
                  'Znajomość języka niem.',
                  b.deutschKenntnisse,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Inne języki:',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (b.andereSprachen.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            'Brak',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: b.andereSprachen.map((jezyk) {
                              return Chip(
                                label: Text(
                                  jezyk,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.blue.shade50,
                                side: BorderSide(color: Colors.blue.shade100),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildCheckRow(
                  Icons.directions_car_outlined,
                  'Prawo jazdy',
                  b.fuehrerschein,
                ),
                _buildCheckRow(
                  Icons.directions_car_filled,
                  'Gotowość do jazdy',
                  b.bereitFuehrerschein,
                ),
                _buildCheckRow(
                  Icons.medical_services_outlined,
                  'Doświadczenie medyczne',
                  b.medizinischeErfahrung,
                ),
                _buildCheckRow(
                  Icons.smoking_rooms_outlined,
                  'Osoba paląca',
                  b.raucher,
                ),
                _buildCheckRow(
                  Icons.yard_outlined,
                  'Prace w ogrodzie',
                  b.gartenArbeiten,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Wykształcenie:',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          b.ausbildung.isEmpty
                              ? 'Brak'
                              : b.ausbildung.map((e) => '$e').join('\n'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (b.beruflicheErfahrung != null &&
                    b.beruflicheErfahrung!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 12),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Doświadczenie zawodowe:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      b.beruflicheErfahrung!.trim(),
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Zdrowie
            _buildInfoCard(
              title: 'Zdrowie',
              icon: Icons.verified_outlined,
              children: [
                _buildDetailRow(
                  Icons.monitor_weight_outlined,
                  'Waga',
                  b.gewicht != null ? '${b.gewicht} kg' : 'Nie podano',
                ),
                _buildDetailRow(
                  Icons.height_outlined,
                  'Wzrost',
                  b.groesse != null ? '${b.groesse} cm' : 'Nie podano',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.coronavirus_outlined,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Alergie:',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (b.allergien.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            'Brak',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: b.allergien.map((allergie) {
                              return Chip(
                                label: Text(
                                  allergie,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.blue.shade50,
                                side: BorderSide(color: Colors.blue.shade100),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.coronavirus_outlined,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Choroby:',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (b.krankheiten.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            'Brak',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: b.krankheiten.map((krankheit) {
                              return Chip(
                                label: Text(
                                  krankheit,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.blue.shade50,
                                side: BorderSide(color: Colors.blue.shade100),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.coronavirus_outlined,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Leki:',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (b.medikamenten.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            'Brak',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: b.medikamenten.map((medikament) {
                              return Chip(
                                label: Text(
                                  medikament,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.blue.shade50,
                                side: BorderSide(color: Colors.blue.shade100),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preferencje zlecenia
            _buildInfoCard(
              title: 'Preferencje zlecenia',
              icon: Icons.assignment_ind_outlined,
              children: [
                _buildDetailRow(
                  Icons.calendar_today_outlined,
                  'Dostępny od',
                  b.datumVerfuegbarkeit?.isNotEmpty == true
                      ? b.datumVerfuegbarkeit!
                      : 'Nie podano',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.date_range_outlined,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Preferowane turnusy:',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (b.betreuungsZyklen.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(left: 28),
                          child: Text(
                            'Brak preferencji (dowolne)',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: b.betreuungsZyklen.map((cykl) {
                              return Chip(
                                avatar: const Icon(
                                  Icons.timelapse_outlined,
                                  size: 14,
                                  color: Colors.blueAccent,
                                ),
                                label: Text(
                                  cykl,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.blue.shade50,
                                side: BorderSide(color: Colors.blue.shade100),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildDetailRow(
                  Icons.person_search_outlined,
                  'Preferowana płeć',
                  b.betreuungGeschlecht,
                ),
                _buildCheckRow(
                  Icons.groups_outlined,
                  'Opieka nad 2 osobami',
                  b.betreuungZweiPersonen,
                ),
                _buildCheckRow(
                  Icons.pets_outlined,
                  'Zgoda na zwierzęta',
                  b.betreuungHaustiere,
                ),
                _buildCheckRow(
                  Icons.yard_outlined,
                  'Pomoc w ogrodzie',
                  b.gartenArbeiten,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Ubezpieczenie:',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          b.versicherung.isEmpty
                              ? 'Brak'
                              : b.versicherung.map((e) => '$e').join('\n'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Notatki
            if (b.notizen != null && b.notizen!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Notatki',
                icon: Icons.note_alt_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      b.notizen!.trim(),
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBadge(
                      'Wszystkich wyjazdów',
                      '${_myTurnusy.length}',
                      Icons.flight_takeoff,
                      Colors.blueAccent,
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    _buildStatBadge(
                      'Łączny staż',
                      '$totalDays dni',
                      Icons.calendar_month_outlined,
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Pobyty i zlecenia (${_myTurnusy.length})',
              icon: Icons.history_edu_outlined,
              children: [
                if (_isLoadingTurnusy)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_myTurnusy.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Brak zarejestrowanych wyjazdów dla tego opiekuna',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (currentTurnus != null) ...[
                    const Text(
                      'AKTUALNE MIEJSCE POBYTU',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTurnusCard(currentTurnus, isOngoing: true),
                    const SizedBox(height: 12),
                  ],
                  if (upcomingTurnusy.isNotEmpty) ...[
                    const Text(
                      'ZAPLANOWANE / PRZYSZŁE POBYTY',
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...upcomingTurnusy.map((t) => _buildTurnusCard(t)),
                    const SizedBox(height: 12),
                  ],
                  if (pastTurnusy.isNotEmpty) ...[
                    const Text(
                      'PRZESZŁE POBYTY (HISTORIA)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...pastTurnusy.map(
                      (t) => _buildTurnusCard(t, isPast: true),
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
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
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
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
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
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

  Widget _buildSpeedDialItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: _expandAnimation,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: color,
            elevation: 5,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(35),
            child: InkWell(
              borderRadius: BorderRadius.circular(35),
              onTap: () {
                _closeFabMenu();
                onTap();
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 48), // Większa wysokość kapsułki
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Większy padding
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: Colors.white), // Większa ikona (22 zamiast 18)
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15, // Większy font (15 zamiast 13)
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDialFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabOpen) ...[
          _buildSpeedDialItem(
            icon: Icons.add_alarm,
            label: 'Zaplanuj wyjazd',
            color: Colors.teal.shade700,
            onTap: _addNewTurnusForThisBetreuer,
          ),
          _buildSpeedDialItem(
            icon: Icons.edit_outlined, 
            label: 'Edytuj profil', 
            color: Colors.blueAccent.shade700, 
            onTap: _openEdit,
          ),
          _buildSpeedDialItem(
            icon: Icons.picture_as_pdf_outlined, 
            label: 'Eksportuj do PDF', 
            color: Colors.deepPurple.shade600, 
            onTap: () => PdfService.showPdfOptionsAndGenerate(context, _currentBetreuer),
          ),
          _buildSpeedDialItem(
          icon: Icons.receipt_long_outlined,
          label: 'Wystaw rachunek', 
          color: Colors.lightBlue.shade700, 
          onTap: _openEdit,
          ),
          _buildSpeedDialItem(
            icon: Icons.delete_outline, 
            label: 'Usuń profil', 
            color: Colors.redAccent.shade700, 
            onTap: _confirmDeleteProfile,
          ),
        ],
        
        SizedBox(
          height: 56,
          child: FloatingActionButton.extended(
            heroTag: 'fab_speed_dial_main',
            backgroundColor: _isFabOpen ? Colors.grey.shade900 : Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            onPressed: _toggleFabMenu,
            icon: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _expandAnimation.value * 3.14159,
                  child: Icon(
                    _isFabOpen ? Icons.close : Icons.star_rounded,
                    size: 26,
                  ),
                );
              },
            ),
            label: Text(
              'Opcje',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTurnusCard(
    Turnus turnus, {
    bool isOngoing = false,
    bool isPast = false,
  }) {
    Color badgeColor = Colors.teal;
    String badgeText = 'NADCHODZĄCY';

    if (isOngoing) {
      badgeColor = Colors.green;
      badgeText = 'W TRAKCIE';
    } else if (isPast) {
      badgeColor = Colors.grey;
      badgeText = 'ZAKOŃCZONY';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isOngoing ? Colors.green.shade300 : Colors.grey.shade300,
          width: isOngoing ? 1.5 : 1,
        ),
      ),
      color: isOngoing
          ? Colors.green.shade50.withOpacity(0.3)
          : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home_work_outlined, size: 18, color: badgeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    turnus.kundeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.date_range, size: 15, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  '${_formatDate(turnus.startDate)} – ${_formatDate(turnus.endDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${turnus.durationInDays} dni',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (turnus.notiz != null && turnus.notiz!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Notatka: ${turnus.notiz}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

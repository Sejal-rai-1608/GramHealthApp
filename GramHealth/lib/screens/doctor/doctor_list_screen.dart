import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../services/doctor_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_state.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final _filterKeys = const [
    'spec_all',
    'spec_gp',
    'spec_pedia',
    'spec_cardio',
    'spec_derma'
  ];
  String _activeFilterKey = 'spec_all';
  final _searchCtrl = TextEditingController();

  List<DoctorModel> _doctors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final docs = await DoctorService.getDoctors();
      if (mounted)
        setState(() {
          _doctors = docs;
          _isLoading = false;
        });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Failed to load doctors. Check your connection.';
          _isLoading = false;
        });
    }
  }

  List<DoctorModel> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    var list = _doctors;
    if (q.isNotEmpty) {
      list = list
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              d.specialization.toLowerCase().contains(q))
          .toList();
    }
    if (_activeFilterKey != 'spec_all') {
      const map = {
        'spec_gp': 'general',
        'spec_pedia': 'pedia',
        'spec_cardio': 'cardio',
        'spec_derma': 'derma'
      };
      final kw = map[_activeFilterKey] ?? '';
      if (kw.isNotEmpty)
        list = list
            .where((d) => d.specialization.toLowerCase().contains(kw))
            .toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Find a doctor',
            style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink),
              decoration: InputDecoration(
                hintText: context.tr('search_doctor'),
                hintStyle: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkFaint),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.inkMuted),
                filled: true,
                fillColor: AppColors.groundAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.borderLight)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.borderLight)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(
                        color: AppColors.tealDeep, width: 1.5)),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _filterKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final key = _filterKeys[i];
                final active = _activeFilterKey == key;
                return CareChip(
                    label: context.tr(key),
                    selected: active,
                    onTap: () => setState(() => _activeFilterKey = key));
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const LoadingState(message: 'Finding doctors…')
                : _error != null
                    ? EmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Unable to load doctors',
                        subtitle: _error!,
                        actionLabel: 'Retry',
                        onAction: _loadDoctors,
                      )
                    : _filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No doctors found',
                            subtitle: 'Try a different search or filter.',
                            actionLabel: 'Clear filters',
                            onAction: () => setState(() {
                              _searchCtrl.clear();
                              _activeFilterKey = 'spec_all';
                            }),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DoctorCard(doc: _filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doc;
  const _DoctorCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return CareCard(
      onTap: () => context.push('/doctor-details/${doc.id}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: doc.image,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: AppColors.mint,
                    alignment: Alignment.center,
                    child: Text(
                        doc.name.isNotEmpty ? doc.name[0].toUpperCase() : '?',
                        style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Dr. ${doc.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  height: 1.2)),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          button: true,
                          label: 'Start video consultation',
                          child: GestureDetector(
                            onTap: () => context.push('/teleconsultation-request',
                                extra: {
                                  'doctorId': doc.id,
                                  'doctorName': doc.name,
                                  'doctorPhone': doc.phone
                                }),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                    color: AppColors.mint,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: AppColors.tealPale)),
                                child: const Icon(Icons.videocam_outlined,
                                    size: 16, color: AppColors.teal),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(doc.specialization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _meta(Icons.work_outline_rounded, doc.exp),
                        if (doc.rating != null)
                          _meta(Icons.star_rounded, '${doc.rating}',
                              color: AppColors.amberDeep),
                        if (doc.isAvailable == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.onlineWash,
                                borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                        color: AppColors.onlineGreen,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text('Available',
                                    style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onlineGreen)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton(
              onPressed: () => context.push('/teleconsultation-request',
                  extra: {
                    'doctorId': doc.id,
                    'doctorName': doc.name,
                    'doctorPhone': doc.phone
                  }),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md)),
                elevation: 0,
              ),
              child: Text(context.tr('book_consultation'),
                  style: GoogleFonts.manrope(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text, {Color color = AppColors.inkMuted}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted)),
      ],
    );
  }
}

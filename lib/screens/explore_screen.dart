import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'destination_screen.dart';

/// Shown first when nobody has searched yet (same list as the website).
const popularInAfrica = ['NG', 'GH', 'KE', 'ZA', 'EG', 'MA', 'TZ', 'SN', 'RW'];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late Future<List<Destination>> _destinations;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _destinations = context.read<ApiClient>().destinations();
  }

  Future<void> _reload() async {
    setState(() => _destinations = context.read<ApiClient>().destinations());
    await _destinations;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: RefreshIndicator(
      color: Colors.black,
      onRefresh: _reload,
      child: FutureBuilder(
        future: _destinations,
        builder: (context, snap) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            if (snap.hasError)
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: ErrorPanel(message: '${snap.error}', onRetry: _reload),
                ),
              )
            else if (!snap.hasData)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.black)),
              )
            else
              ..._lists(snap.data!),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    ),
  );

  Widget _header() => Container(
    color: Colors.black,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Logo(color: Colors.white),
        const SizedBox(height: 36),
        Text('Travel Far.\nStay Connected', style: display(36, color: Colors.white)),
        const SizedBox(height: 10),
        const Text(
          'No physical SIM cards. No roaming surprises. Just reliable data wherever your journey takes you.',
          style: TextStyle(color: AppColors.vibrant, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        Text(
          'Where are you headed?',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          textInputAction: TextInputAction.search,
          style: GoogleFonts.poppins(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Choose your destination...',
            hintStyle: GoogleFonts.poppins(color: const Color(0xFF6C6D75)),
            prefixIcon: const Icon(Icons.search, color: AppColors.muted),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              borderSide: BorderSide(color: AppColors.tangerine, width: 2),
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _lists(List<Destination> all) {
    if (_query.isNotEmpty) {
      final results = all
          .where((d) => d.name.toLowerCase().contains(_query) || d.code.toLowerCase() == _query)
          .toList();
      return [
        _title('Results for “$_query”'),
        if (results.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Text(
                "We don't cover that destination yet. Try a nearby country or a regional plan.",
                style: TextStyle(color: AppColors.body),
              ),
            ),
          ),
        _grid(results),
      ];
    }
    final byCode = {for (final d in all) d.code: d};
    return [
      _title('Popular in Africa'),
      _grid([for (final c in popularInAfrica) ?byCode[c]]),
      _title('All destinations'),
      _grid(all),
    ];
  }

  Widget _title(String text) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
    sliver: SliverToBoxAdapter(child: Text(text, style: display(22))),
  );

  Widget _grid(List<Destination> list) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    sliver: SliverList.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => DestinationTile(list[i]),
    ),
  );
}

class DestinationTile extends StatelessWidget {
  const DestinationTile(this.destination, {super.key});
  final Destination destination;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.tile,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DestinationScreen(destination: destination))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Flag(destination.code),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'From ${money(destination.fromPrice)}',
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.subtle),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.subtle),
          ],
        ),
      ),
    ),
  );
}
